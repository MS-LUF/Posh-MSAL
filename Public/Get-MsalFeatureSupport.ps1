<#
.SYNOPSIS
    Shows what works on this machine and which MSAL.NET version is loaded.
.DESCRIPTION
    Returns what the module found when it was imported: whether the embedded browser window, device
    code, the token cache on disk and the authentication broker are available on this platform and
    PowerShell edition, the version of MSAL.NET loaded, and the assembly conflicts met while loading
    it, such as another module having loaded its own MSAL.NET first.
.EXAMPLE
    Get-MsalFeatureSupport
    Shows the features available in this session.
.INPUTS
    None.
.OUTPUTS
    System.Management.Automation.PSCustomObject
#>
function Get-MsalFeatureSupport {
    [CmdletBinding()]
    [OutputType([psobject])]
    param ()

    return [PSCustomObject]$script:ModuleFeatureSupport
}

