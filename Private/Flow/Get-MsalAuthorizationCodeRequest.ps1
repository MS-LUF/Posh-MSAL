<#
.SYNOPSIS
    Builds the request that redeems an authorization code for a confidential client.
.EXAMPLE
    Get-MsalAuthorizationCodeRequest $Application -Scopes 'https://graph.microsoft.com/User.Read' -AuthorizationCode $Code
    Builds the request; Invoke-MsalRequest runs it.
.OUTPUTS
    Microsoft.Identity.Client.AcquireTokenByAuthorizationCodeParameterBuilder
#>
function Get-MsalAuthorizationCodeRequest {
    [CmdletBinding()]
    [OutputType([Microsoft.Identity.Client.AcquireTokenByAuthorizationCodeParameterBuilder])]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [Microsoft.Identity.Client.IConfidentialClientApplication] $Application,
        [Parameter(Mandatory = $true)]
        [string[]] $Scopes,
        [Parameter(Mandatory = $true)]
        [string] $AuthorizationCode,
        [Parameter(Mandatory = $false)]
        [switch] $SendX5C
    )

    $Request = $Application.AcquireTokenByAuthorizationCode($Scopes, $AuthorizationCode)
    if ($SendX5C) { [void] $Request.WithSendX5C($true) }
    return $Request
}
