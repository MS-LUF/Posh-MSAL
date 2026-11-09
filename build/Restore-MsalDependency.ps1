<#
.SYNOPSIS
    Rebuilds lib/ from the pinned MSAL.NET packages of Data/MsalDependency.psd1.
.DESCRIPTION
    Downloads every pinned package from nuget.org, checks its SHA-512 against the pin, extracts
    the pinned files into a staging folder and checks each one's SHA-256. On Windows it also
    checks that every DLL carries a valid Authenticode signature from Microsoft Corporation.
    Only when every check passes is lib/ replaced by the staging folder, so lib/ holds exactly the
    pinned files. Needs PowerShell only (5.1 or 7), no .NET SDK.
.EXAMPLE
    PS C:\>./build/Restore-MsalDependency.ps1
#>
[CmdletBinding()]
param (
    [string] $FeedUrl = 'https://api.nuget.org/v3-flatcontainer'
)
Set-StrictMode -Version 3.0
$ErrorActionPreference = 'Stop'

$RepositoryRoot = Split-Path -Parent $PSScriptRoot
$LibPath = Join-Path $RepositoryRoot 'lib'
$Pins = Import-PowerShellDataFile -Path (Join-Path (Join-Path $RepositoryRoot 'Data') 'MsalDependency.psd1')
$IsWindowsHost = -not (Get-Variable IsWindows -ErrorAction SilentlyContinue) -or $IsWindows
Add-Type -AssemblyName System.IO.Compression, System.IO.Compression.FileSystem
if ($PSVersionTable.PSEdition -eq 'Desktop') { [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12 }

$WorkFolder = Join-Path ([System.IO.Path]::GetTempPath()) ('posh-msal-restore-' + [guid]::NewGuid().Guid.Substring(0, 8))
$StagingFolder = Join-Path $WorkFolder 'lib'
[void] (New-Item -ItemType Directory -Path $StagingFolder)
try {
    foreach ($Package in $Pins.Packages) {
        $Id = $Package.Id.ToLowerInvariant()
        $Version = $Package.Version.ToLowerInvariant()
        $PackageFile = Join-Path $WorkFolder "$Id.$Version.nupkg"
        Invoke-WebRequest -Uri "$FeedUrl/$Id/$Version/$Id.$Version.nupkg" -OutFile $PackageFile -UseBasicParsing

        $Sha512 = [System.Security.Cryptography.SHA512]::Create()
        $Stream = [System.IO.File]::OpenRead($PackageFile)
        try { $Actual = [System.Convert]::ToBase64String($Sha512.ComputeHash($Stream)) }
        finally { $Stream.Dispose(); $Sha512.Dispose() }
        if ($Actual -ne $Package.Sha512) { throw "SHA-512 mismatch for $($Package.Id) $($Package.Version): expected $($Package.Sha512), got $Actual." }

        $Archive = [System.IO.Compression.ZipFile]::OpenRead($PackageFile)
        try {
            foreach ($File in $Package.Files) {
                $Entry = $Archive.GetEntry($File.Source)
                if (-not $Entry) { throw "$($File.Source) not found in $($Package.Id) $($Package.Version)." }
                $Destination = Join-Path $StagingFolder $File.Target
                [void] (New-Item -ItemType Directory -Path (Split-Path -Parent $Destination) -Force)
                [System.IO.Compression.ZipFileExtensions]::ExtractToFile($Entry, $Destination, $true)
                $Hash = (Get-FileHash -LiteralPath $Destination -Algorithm SHA256).Hash
                if ($Hash -ne $File.Sha256) { throw "SHA-256 mismatch for $($File.Target): expected $($File.Sha256), got $Hash." }
                if ($IsWindowsHost -and $Destination -like '*.dll') {
                    $Signature = Get-AuthenticodeSignature -LiteralPath $Destination
                    if ($Signature.Status -ne 'Valid' -or $Signature.SignerCertificate.Subject -notmatch 'O=Microsoft Corporation') {
                        throw "$($File.Target) is not validly signed by Microsoft Corporation ($($Signature.Status))."
                    }
                }
            }
        }
        finally { $Archive.Dispose() }
        Write-Verbose ('{0} {1}: {2} file(s) checked.' -f $Package.Id, $Package.Version, @($Package.Files).Count)
    }

    if (Test-Path -LiteralPath $LibPath) { Remove-Item -LiteralPath $LibPath -Recurse -Force }
    Move-Item -LiteralPath $StagingFolder -Destination $LibPath
    Write-Verbose "lib/ restored from $(@($Pins.Packages).Count) pinned packages." -Verbose
}
finally {
    Remove-Item -LiteralPath $WorkFolder -Recurse -Force -ErrorAction SilentlyContinue
}
