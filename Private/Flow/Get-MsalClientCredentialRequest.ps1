<#
.SYNOPSIS
    Builds the client credentials request of a confidential client.
.DESCRIPTION
    ForceRefresh is true or false when the caller chose, or null to leave MSAL's default.
.EXAMPLE
    Get-MsalClientCredentialRequest $Application -Scopes 'https://graph.microsoft.com/.default' -SendX5C
    Builds the request, sending the certificate's public key to the STS.
.OUTPUTS
    Microsoft.Identity.Client.AcquireTokenForClientParameterBuilder
#>
function Get-MsalClientCredentialRequest {
    [CmdletBinding()]
    [OutputType([Microsoft.Identity.Client.AcquireTokenForClientParameterBuilder])]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [Microsoft.Identity.Client.IConfidentialClientApplication] $Application,
        [Parameter(Mandatory = $true)]
        [string[]] $Scopes,
        # $true or $false when the caller chose; $null leaves MSAL's default.
        [Parameter(Mandatory = $false)]
        [AllowNull()]
        [object] $ForceRefresh,
        [Parameter(Mandatory = $false)]
        [switch] $SendX5C
    )

    $Request = $Application.AcquireTokenForClient($Scopes)
    if ($null -ne $ForceRefresh) { [void] $Request.WithForceRefresh([bool] $ForceRefresh) }
    if ($SendX5C) { [void] $Request.WithSendX5C($true) }
    return $Request
}
