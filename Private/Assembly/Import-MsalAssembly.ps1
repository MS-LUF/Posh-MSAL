<#
.SYNOPSIS
    Loads the bundled MSAL.NET libraries for this PowerShell edition.
.DESCRIPTION
    Refuses PowerShell 7 below 7.4, then loads every DLL of lib/net472 on Windows PowerShell or
    lib/net8.0 on PowerShell 7. On Windows PowerShell it first registers the assembly resolver, as
    that edition has no binding redirects. A DLL whose name is already loaded from elsewhere goes
    through Resolve-MsalAssemblyLoadError. Called once by the module loader.
.EXAMPLE
    Import-MsalAssembly
    Loads MSAL.NET and its dependencies into the session.
.OUTPUTS
    None.
#>
function Import-MsalAssembly {
    [CmdletBinding()]
    param ()

    ## Pick the MSAL.NET build for this edition: net472 on Windows PowerShell, net8.0 on PowerShell 7.4 and later.
    if ($PSVersionTable.PSEdition -eq 'Core') {
        if ($PSVersionTable.PSVersion -lt [version]'7.4') {
            throw ('Posh-MSAL needs PowerShell 7.4 or later (or Windows PowerShell 5.1); this is PowerShell {0}.' -f $PSVersionTable.PSVersion)
        }
        $TargetFramework = 'net8.0'
    }
    else {
        $TargetFramework = 'net472'
    }
    $LibPath = Join-Path (Join-Path $script:ModuleRoot 'lib') $TargetFramework
    if ($TargetFramework -eq 'net472') { Register-MsalAssemblyResolver -Path $LibPath }

    ## Load every managed DLL of the closure; the native broker runtimes under runtimes/ are found by
    ## Microsoft.Identity.Client.NativeInterop itself, relative to its own location.
    foreach ($Dll in Get-ChildItem -Path $LibPath -Filter '*.dll' | Sort-Object Name) {
        try {
            # Windows PowerShell would load another version of MSAL.NET side by side with no error,
            # and keep using it: report it as the conflict PowerShell 7 raises. Only the MSAL
            # assemblies are checked; side-by-side System.* polyfills are harmless.
            if ($Dll.BaseName -like 'Microsoft.Identity*') {
                $Loaded = Find-MsalLoadedAssembly -Name $Dll.BaseName -Version ([System.Reflection.AssemblyName]::GetAssemblyName($Dll.FullName).Version)
                if ($Loaded) { throw (New-Object System.IO.FileLoadException ('Another version of {0} ({1}) is already loaded from "{2}".' -f $Dll.BaseName, $Loaded.GetName().Version, $Loaded.Location)) }
            }
            Add-Type -LiteralPath $Dll.FullName | Out-Null
        }
        catch {
            [void] (Resolve-MsalAssemblyLoadError $Dll.FullName)
        }
    }
}
