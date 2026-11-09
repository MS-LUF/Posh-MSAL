<#
.SYNOPSIS
    Builds the username and password request of a public client, with a deprecation warning.
.DESCRIPTION
    MSAL.NET deprecates this flow, which cannot work with multifactor authentication.
.EXAMPLE
    Get-MsalUsernamePasswordRequest $Application -Scopes 'https://graph.microsoft.com/User.Read' -Credential (Get-Credential)
    Builds the request and warns that the flow is deprecated.
.OUTPUTS
    Microsoft.Identity.Client.AcquireTokenByUsernamePasswordParameterBuilder
#>
function Get-MsalUsernamePasswordRequest {
    [CmdletBinding()]
    [OutputType([Microsoft.Identity.Client.AcquireTokenByUsernamePasswordParameterBuilder])]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [Microsoft.Identity.Client.IPublicClientApplication] $Application,
        [Parameter(Mandatory = $true)]
        [string[]] $Scopes,
        [Parameter(Mandatory = $true)]
        [pscredential] $Credential
    )

    Write-Warning 'The username/password flow (ROPC) is deprecated by MSAL.NET and blocked by multi-factor authentication; prefer the interactive, device code or broker flows.'
    return $Application.AcquireTokenByUsernamePassword($Scopes, $Credential.UserName, $Credential.Password)
}
