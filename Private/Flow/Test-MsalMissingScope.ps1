<#
.SYNOPSIS
    Tells whether a token was granted without one of the requested scopes.
.DESCRIPTION
    Used by the default flow of Get-MsalToken: a missing scope means a consent is missing, so an
    interactive sign-in follows.
.EXAMPLE
    Test-MsalMissingScope $AuthenticationResult 'https://graph.microsoft.com/User.Read'
    True when the token does not carry User.Read.
.OUTPUTS
    System.Boolean
#>
function Test-MsalMissingScope {
    [CmdletBinding()]
    [OutputType([bool])]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [Microsoft.Identity.Client.AuthenticationResult] $AuthenticationResult,
        [Parameter(Mandatory = $true, Position = 1)]
        [string[]] $Scopes
    )

    ## True when the token was granted without one of the requested scopes (a consent is missing).
    foreach ($Scope in $Scopes) {
        if ($AuthenticationResult.Scopes -notcontains $Scope) { return $true }
    }
    return $false
}
