<#
.SYNOPSIS
    Finds an assembly of this name already loaded from outside the module with another version.
.DESCRIPTION
    Windows PowerShell (the .NET Framework) loads a second version of a strong-named assembly side
    by side without any error, and PowerShell then resolves type names to the copy loaded first.
    Another module's older MSAL.NET would silently stand in for the module's own. Checking before
    loading turns that case into the conflict PowerShell 7 reports with an error. An assembly loaded
    from the module's own folder, or with the same version, is not a conflict.
.EXAMPLE
    Find-MsalLoadedAssembly -Name 'Microsoft.Identity.Client' -Version '4.92.0.0'
    Returns another module's MSAL.NET if one with a different version is loaded.
.OUTPUTS
    System.Reflection.Assembly
#>
function Find-MsalLoadedAssembly {
    [CmdletBinding()]
    [OutputType([System.Reflection.Assembly])]
    param (
        # Simple name of the assembly.
        [Parameter(Mandatory = $true)]
        [string] $Name,
        # Version of the module's own copy.
        [Parameter(Mandatory = $true)]
        [version] $Version
    )

    foreach ($Assembly in [System.AppDomain]::CurrentDomain.GetAssemblies()) {
        if ($Assembly.IsDynamic -or $Assembly.GetName().Name -ne $Name) { continue }
        if ($Assembly.GetName().Version -eq $Version) { continue }
        if ($Assembly.Location -and $Assembly.Location.StartsWith($script:ModuleRoot, [System.StringComparison]::OrdinalIgnoreCase)) { continue }
        return $Assembly
    }
}
