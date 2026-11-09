<#
.SYNOPSIS
    Wraps a signed client assertion in the delegate MSAL.NET asks for.
.DESCRIPTION
    MSAL.NET deprecates WithClientAssertion(string) for a delegate that returns the assertion. MSAL
    calls the delegate on its own threads, where no runspace exists, so it is an expression tree
    returning the given string, not a scriptblock.
.EXAMPLE
    $Builder.WithClientAssertion((Get-MsalClientAssertionCallback $Jwt))
    Makes a confidential client application sign in with this JWT.
.OUTPUTS
    System.Func`2[Microsoft.Identity.Client.AssertionRequestOptions,System.Threading.Tasks.Task`1[System.String]]
#>
function Get-MsalClientAssertionCallback {
    [CmdletBinding()]
    [OutputType([System.Func[Microsoft.Identity.Client.AssertionRequestOptions, System.Threading.Tasks.Task[string]]])]
    param (
        # The signed client assertion (a JWT).
        [Parameter(Mandatory = $true, Position = 0)]
        [string] $Assertion
    )

    ## MSAL 4.92 deprecates WithClientAssertion(string) for a delegate returning the assertion. MSAL
    ## calls it on its own threads, where no runspace exists, so it is an expression tree returning
    ## the given assertion, not a scriptblock.
    $Expression = [System.Linq.Expressions.Expression]
    $Options = $Expression::Parameter([Microsoft.Identity.Client.AssertionRequestOptions], 'options')
    $FromResult = [System.Threading.Tasks.Task].GetMethod('FromResult').MakeGenericMethod([string])
    $Body = $Expression::Call($FromResult, [System.Linq.Expressions.Expression[]] @($Expression::Constant($Assertion)))
    $Lambda = $Expression::Lambda([System.Func[Microsoft.Identity.Client.AssertionRequestOptions, System.Threading.Tasks.Task[string]]], $Body, [System.Linq.Expressions.ParameterExpression[]] @($Options))
    return $Lambda.Compile()
}
