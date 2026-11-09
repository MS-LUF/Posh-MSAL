<#
.SYNOPSIS
    Builds the on-behalf-of request of a confidential client, exchanging the token an API received.
.EXAMPLE
    Get-MsalOnBehalfOfRequest $Application -Scopes 'https://graph.microsoft.com/User.Read' -UserAssertion $IncomingToken
    Builds the request that exchanges the incoming token for a Graph token.
.OUTPUTS
    Microsoft.Identity.Client.AcquireTokenOnBehalfOfParameterBuilder
#>
function Get-MsalOnBehalfOfRequest {
    [CmdletBinding()]
    [OutputType([Microsoft.Identity.Client.AcquireTokenOnBehalfOfParameterBuilder])]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [Microsoft.Identity.Client.IConfidentialClientApplication] $Application,
        [Parameter(Mandatory = $true)]
        [string[]] $Scopes,
        # The token the API received, to exchange.
        [Parameter(Mandatory = $true)]
        [string] $UserAssertion,
        [Parameter(Mandatory = $false)]
        [string] $UserAssertionType,
        [Parameter(Mandatory = $false)]
        [switch] $SendX5C
    )

    if ($UserAssertionType) { $Assertion = New-Object Microsoft.Identity.Client.UserAssertion -ArgumentList $UserAssertion, $UserAssertionType }
    else { $Assertion = New-Object Microsoft.Identity.Client.UserAssertion -ArgumentList $UserAssertion }
    $Request = $Application.AcquireTokenOnBehalfOf($Scopes, $Assertion)
    if ($SendX5C) { [void] $Request.WithSendX5C($true) }
    return $Request
}
