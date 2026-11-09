<#
.SYNOPSIS
    Tells which flow a Get-MsalToken call asks for.
.DESCRIPTION
    Checks the parameter set and the switches in the order MSAL.PS did. A confidential client uses
    AuthorizationCode, OnBehalfOf or ClientCredential. A public client uses UsernamePassword,
    DeviceCode, Interactive, IntegratedWindowsAuth, Silent or, with none of these, Default.

    Interactive becomes DeviceCode on PowerShell 7 when the application's redirect URI is not an
    http://localhost one, as the system browser needs it and there is no embedded browser.
.EXAMPLE
    Resolve-MsalTokenFlow $PSCmdlet.ParameterSetName $PSBoundParameters $ClientApplication
    Returns the name of the flow, such as ClientCredential.
.OUTPUTS
    System.String
#>
function Resolve-MsalTokenFlow {
    [CmdletBinding()]
    [OutputType([string])]
    param (
        # Parameter set of Get-MsalToken.
        [Parameter(Mandatory = $true, Position = 0)]
        [string] $ParameterSetName,
        # Bound parameters of Get-MsalToken.
        [Parameter(Mandatory = $true, Position = 1)]
        [hashtable] $BoundParameters,
        [Parameter(Mandatory = $true, Position = 2)]
        [Microsoft.Identity.Client.IClientApplicationBase] $Application
    )

    ## Which acquisition flow a Get-MsalToken call asks for, in the order upstream MSAL.PS checked them.
    $Bound = { param ($Name) $BoundParameters.ContainsKey($Name) -and $BoundParameters[$Name] }
    if ($ParameterSetName -like 'ConfidentialClient*') {
        if ($BoundParameters.ContainsKey('AuthorizationCode')) { return 'AuthorizationCode' }
        if ($BoundParameters.ContainsKey('UserAssertion')) { return 'OnBehalfOf' }
        return 'ClientCredential'
    }
    if (& $Bound 'UserCredential') { return 'UsernamePassword' }
    if (& $Bound 'DeviceCode') { return 'DeviceCode' }
    if (& $Bound 'Interactive') {
        # PowerShell 7 has no embedded browser: the system browser needs an http://localhost
        # redirect URI (any port or path); with any other one, device code is the only way left.
        $RedirectUri = $null
        $Loopback = [uri]::TryCreate([string] $Application.AppConfig.RedirectUri, [System.UriKind]::Absolute, [ref] $RedirectUri) -and $RedirectUri.Scheme -eq 'http' -and $RedirectUri.Host -eq 'localhost'
        if (-not $script:ModuleFeatureSupport.EmbeddedWebViewSupport -and -not $Loopback) { return 'DeviceCode' }
        return 'Interactive'
    }
    if (& $Bound 'IntegratedWindowsAuth') { return 'IntegratedWindowsAuth' }
    if (& $Bound 'Silent') { return 'Silent' }
    return 'Default'
}
