<#
.SYNOPSIS
    Gets the accounts in the token cache of a client application.
.DESCRIPTION
    Returns the accounts that signed in through the application and are still in its user token
    cache, in memory, or on disk when Enable-MsalTokenCacheOnDisk was used. Username keeps only the
    account with that user principal name.

    To get a token for one of them from the cache, give its Username to Get-MsalToken -Silent
    -LoginHint.
.EXAMPLE
    Get-MsalClientApplication -ClientId '00000000-0000-0000-0000-000000000000' | Get-MsalAccount
    Lists the accounts cached by the session's applications with this client id.
.EXAMPLE
    Get-MsalAccount $ClientApplication -Username 'user@contoso.com'
    Gets one account from the application's cache.
.INPUTS
    Microsoft.Identity.Client.IClientApplicationBase, Microsoft.Identity.Client.IAccount
.OUTPUTS
    Microsoft.Identity.Client.IAccount
.LINK
    Get-MsalToken
#>
function Get-MsalAccount {
    [CmdletBinding()]
    [OutputType([Microsoft.Identity.Client.IAccount])]
    param
    (
        # Client application whose user token cache is read.
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ParameterSetName = 'ClientApplication', Position = 0)]
        [Microsoft.Identity.Client.IClientApplicationBase] $ClientApplication,
        # Accounts to filter, such as the output of an earlier Get-MsalAccount.
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ParameterSetName = 'Accounts', Position = 0)]
        [Microsoft.Identity.Client.IAccount[]] $Accounts,
        # The username in UserPrincipalName (UPN) format.
        [Parameter(Mandatory = $false)]
        [string] $Username
    )

    process {
        if ($PSCmdlet.ParameterSetName -eq 'ClientApplication') {
            [Microsoft.Identity.Client.IAccount[]] $Accounts = $ClientApplication.GetAccountsAsync().GetAwaiter().GetResult()
        }

        if ($Username) {
            return $Accounts | Where-Object Username -eq $Username
        }
        else {
            return $Accounts
        }
    }
}

