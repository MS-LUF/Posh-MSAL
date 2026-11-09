<#
.SYNOPSIS
    Builds the request that gets a token from the token cache of a public client.
.DESCRIPTION
    The account is the one with LoginHint as user name or, without it, the first account of the
    cache. ForceRefresh is true or false when the caller chose, or null to leave MSAL's default.
.EXAMPLE
    Get-MsalSilentRequest $Application -Scopes 'https://graph.microsoft.com/User.Read' -LoginHint 'user@contoso.com'
    Builds the request for this account.
.OUTPUTS
    Microsoft.Identity.Client.AcquireTokenSilentParameterBuilder
#>
function Get-MsalSilentRequest {
    [CmdletBinding()]
    [OutputType([Microsoft.Identity.Client.AcquireTokenSilentParameterBuilder])]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [Microsoft.Identity.Client.IPublicClientApplication] $Application,
        [Parameter(Mandatory = $true)]
        [string[]] $Scopes,
        # Account by user name; without it, the first account of the cache.
        [Parameter(Mandatory = $false)]
        [string] $LoginHint,
        # $true or $false when the caller chose; $null leaves MSAL's default.
        [Parameter(Mandatory = $false)]
        [AllowNull()]
        [object] $ForceRefresh
    )

    if ($LoginHint) {
        $Request = $Application.AcquireTokenSilent($Scopes, $LoginHint)
    }
    else {
        [Microsoft.Identity.Client.IAccount] $Account = $Application.GetAccountsAsync().GetAwaiter().GetResult() | Select-Object -First 1
        $Request = $Application.AcquireTokenSilent($Scopes, $Account)
    }
    if ($null -ne $ForceRefresh) { [void] $Request.WithForceRefresh([bool] $ForceRefresh) }
    return $Request
}
