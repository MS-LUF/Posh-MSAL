<#
.SYNOPSIS
    Pins the MSAL.NET dependency closure in Data/MsalDependency.psd1, then restores lib/.
.DESCRIPTION
    Runs "dotnet restore" on build/MsalDependency.csproj into a temporary folder (no compilation),
    reads the resolved closure from project.assets.json, and writes, for every package of the
    net472 and net8.0 closures, its version, the SHA-512 of its .nupkg as nuget.org publishes it,
    and the SHA-256 of every file Posh-MSAL takes from it. Then runs Restore-MsalDependency.ps1,
    which downloads the packages again and checks them against these pins.
    Needs the .NET SDK 8 or later. Run it only to change the bundled MSAL.NET version.
.EXAMPLE
    PS C:\>./build/Update-MsalDependency.ps1
#>
[CmdletBinding()]
param (
    # Native broker runtimes to bundle: the broker is used on Windows only for now (linux-x64 alone
    # weighs 40 MB, and macOS is not supported).
    [string[]] $RuntimeIdentifier = @('win-x64', 'win-x86', 'win-arm64')
)
Set-StrictMode -Version 3.0
$ErrorActionPreference = 'Stop'

$RepositoryRoot = Split-Path -Parent $PSScriptRoot
$ProjectPath = Join-Path $PSScriptRoot 'MsalDependency.csproj'
$DataPath = Join-Path (Join-Path $RepositoryRoot 'Data') 'MsalDependency.psd1'
# Target framework folder => the names project.assets.json may key it by (format 4 uses the short one).
$TargetFrameworks = [ordered]@{ 'net472' = @('net472', '.NETFramework,Version=v4.7.2'); 'net8.0' = @('net8.0', '.NETCoreApp,Version=v8.0') }

$WorkFolder = Join-Path ([System.IO.Path]::GetTempPath()) ('posh-msal-update-' + [guid]::NewGuid().Guid.Substring(0, 8))
$PackagesFolder = Join-Path $WorkFolder 'packages'
$ObjFolder = Join-Path $WorkFolder 'obj'
[void] (New-Item -ItemType Directory -Path $PackagesFolder, $ObjFolder)
try {
    & dotnet restore $ProjectPath --packages $PackagesFolder "-p:BaseIntermediateOutputPath=$ObjFolder$([System.IO.Path]::DirectorySeparatorChar)" --nologo
    if ($LASTEXITCODE -ne 0) { throw "dotnet restore failed with exit code $LASTEXITCODE." }
    $Assets = Get-Content -LiteralPath (Join-Path $ObjFolder 'project.assets.json') -Raw | ConvertFrom-Json

    # .NET 8 ships some of these assemblies itself, in a newer version: the SDK drops the package's
    # copy, and so does this script (loading ours next to the framework's would be a conflict).
    $FrameworkAssemblies = @{}
    $FrameworkList = Get-ChildItem -Path (Join-Path $PackagesFolder 'microsoft.netcore.app.ref') -Filter 'FrameworkList.xml' -Recurse | Select-Object -First 1
    if (-not $FrameworkList) { throw 'Microsoft.NETCore.App.Ref was not restored: cannot tell which assemblies .NET 8 provides.' }
    foreach ($Match in (Select-String -LiteralPath $FrameworkList.FullName -Pattern 'Type="Managed"[^>]*AssemblyName="([^"]+)"[^>]*AssemblyVersion="([^"]+)"')) {
        $FrameworkAssemblies[$Match.Matches[0].Groups[1].Value] = [version] $Match.Matches[0].Groups[2].Value
    }

    $Packages = [ordered]@{}
    foreach ($Tfm in $TargetFrameworks.Keys) {
        $Target = $Assets.targets.psobject.Properties | Where-Object { $TargetFrameworks[$Tfm] -contains $_.Name } | Select-Object -First 1
        if (-not $Target) { throw "No $Tfm target in project.assets.json." }
        # Windows PowerShell only runs on Windows: its build takes the Windows broker runtimes only.
        $Rids = if ($Tfm -eq 'net472') { @($RuntimeIdentifier -like 'win-*') } else { $RuntimeIdentifier }
        foreach ($Library in $Target.Value.psobject.Properties) {
            if ($Library.Value.type -ne 'package') { continue }
            $Id, $Version = $Library.Name -split '/', 2
            $PackageFolder = Join-Path (Join-Path $PackagesFolder $Id.ToLowerInvariant()) $Version.ToLowerInvariant()
            if (-not $Packages.Contains($Library.Name)) {
                $Packages[$Library.Name] = [ordered]@{
                    Id      = $Id
                    Version = $Version
                    # The hash of the .nupkg bytes as served. project.assets.json holds NuGet's content
                    # hash instead, which leaves out the repository signature and matches no download.
                    Sha512  = (Get-Content -LiteralPath (Join-Path $PackageFolder ('{0}.{1}.nupkg.sha512' -f $Id.ToLowerInvariant(), $Version.ToLowerInvariant())) -Raw).Trim()
                    Files   = New-Object System.Collections.Generic.List[object]
                }
            }
            $Picked = @()
            if ($Library.Value.psobject.Properties['runtime']) {
                foreach ($Source in $Library.Value.runtime.psobject.Properties.Name) {
                    if ($Source -like '*/_._') { continue }
                    if ($Tfm -eq 'net8.0') {
                        $AssemblyName = [System.Reflection.AssemblyName]::GetAssemblyName((Join-Path $PackageFolder $Source))
                        if ($FrameworkAssemblies.ContainsKey($AssemblyName.Name) -and $FrameworkAssemblies[$AssemblyName.Name] -ge $AssemblyName.Version) {
                            Write-Verbose ('{0}: skipped, .NET 8 provides {1}.' -f $Source, $FrameworkAssemblies[$AssemblyName.Name])
                            continue
                        }
                    }
                    $Picked += , @($Source, ('{0}/{1}' -f $Tfm, ($Source -split '/')[-1]))
                }
            }
            if ($Library.Value.psobject.Properties['runtimeTargets']) {
                foreach ($RuntimeTarget in $Library.Value.runtimeTargets.psobject.Properties) {
                    # Only native broker runtimes: RID-specific managed assets are not used by the loader.
                    if ($RuntimeTarget.Value.assetType -eq 'native' -and $Rids -contains $RuntimeTarget.Value.rid) {
                        $Picked += , @($RuntimeTarget.Name, ('{0}/runtimes/{1}/native/{2}' -f $Tfm, $RuntimeTarget.Value.rid, ($RuntimeTarget.Name -split '/')[-1]))
                    }
                }
            }
            foreach ($Asset in $Picked) {
                $SourceFile = Join-Path $PackageFolder $Asset[0]
                $Packages[$Library.Name].Files.Add([ordered]@{
                        Source = $Asset[0]
                        Target = $Asset[1]
                        Sha256 = (Get-FileHash -LiteralPath $SourceFile -Algorithm SHA256).Hash
                    })
            }
        }
    }

    $Lines = New-Object System.Collections.Generic.List[string]
    $Lines.Add('# Generated by build/Update-MsalDependency.ps1 from build/MsalDependency.csproj. Do not edit by hand.')
    $Lines.Add('# Restore-MsalDependency.ps1 rebuilds lib/ from these pins; Tests/Dependency.Tests.ps1 checks lib/ against them.')
    $Lines.Add('@{')
    $Lines.Add('    Packages = @(')
    foreach ($Package in $Packages.Values | Sort-Object { $_.Id }) {
        if ($Package.Files.Count -eq 0) { continue }
        $Lines.Add('        @{')
        $Lines.Add(("            Id      = '{0}'" -f $Package.Id))
        $Lines.Add(("            Version = '{0}'" -f $Package.Version))
        $Lines.Add(("            Sha512  = '{0}'" -f $Package.Sha512))
        $Lines.Add('            Files   = @(')
        foreach ($File in $Package.Files | Sort-Object { $_.Target }) {
            $Lines.Add(("                @{{ Source = '{0}'; Target = '{1}'; Sha256 = '{2}' }}" -f $File.Source, $File.Target, $File.Sha256))
        }
        $Lines.Add('            )')
        $Lines.Add('        }')
    }
    $Lines.Add('    )')
    $Lines.Add('}')
    [void] (New-Item -ItemType Directory -Path (Split-Path -Parent $DataPath) -Force)
    [System.IO.File]::WriteAllLines($DataPath, $Lines)
    Write-Verbose "Pins written to $DataPath." -Verbose
}
finally {
    Remove-Item -LiteralPath $WorkFolder -Recurse -Force -ErrorAction SilentlyContinue
}

& (Join-Path $PSScriptRoot 'Restore-MsalDependency.ps1')
