<#
.SYNOPSIS
    Builds the integrated Windows authentication request of a public client, with a deprecation warning.
.DESCRIPTION
    MSAL.NET deprecates this flow. The default flow of Get-MsalToken tries it on its own, with the
    warning silenced.
.EXAMPLE
    Get-MsalIntegratedWindowsAuthRequest $Application -Scopes 'https://graph.microsoft.com/User.Read' -LoginHint 'user@contoso.com'
    Builds the request for this user and warns that the flow is deprecated.
.OUTPUTS
    Microsoft.Identity.Client.AcquireTokenByIntegratedWindowsAuthParameterBuilder
#>
function Get-MsalIntegratedWindowsAuthRequest {
    [CmdletBinding()]
    [OutputType([Microsoft.Identity.Client.AcquireTokenByIntegratedWindowsAuthParameterBuilder])]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [Microsoft.Identity.Client.IPublicClientApplication] $Application,
        [Parameter(Mandatory = $true)]
        [string[]] $Scopes,
        [Parameter(Mandatory = $false)]
        [string] $LoginHint
    )

    # The default flow of Get-MsalToken tries this one on its own, with the warning silenced.
    Write-Warning 'Integrated Windows Authentication is deprecated by MSAL.NET; prefer the authentication broker (-AuthenticationBroker) for single sign-on with the Windows account.'
    $Request = $Application.AcquireTokenByIntegratedWindowsAuth($Scopes)
    if ($LoginHint) { [void] $Request.WithUsername($LoginHint) }
    return $Request
}
