<#
.SYNOPSIS
    Creates a cache helper for the user or app token cache on disk, and checks that it works.
.DESCRIPTION
    Wraps MsalCacheHelper.CreateAsync and VerifyPersistence, so it throws
    MsalCachePersistenceException when the store cannot be written and read back, as on Linux with
    no keyring in the session. Tests mock this function to stand in for the store.
.EXAMPLE
    New-MsalCacheHelper User -Unprotected
    Creates a helper for the plain-file user token cache.
.OUTPUTS
    Microsoft.Identity.Client.Extensions.Msal.MsalCacheHelper
#>
function New-MsalCacheHelper {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '', Justification = 'Creates an in-memory helper; the probe it writes is removed by VerifyPersistence itself.')]
    [CmdletBinding()]
    [OutputType([Microsoft.Identity.Client.Extensions.Msal.MsalCacheHelper])]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [ValidateSet('User', 'App')]
        [string] $Store,
        [Parameter(Mandatory = $false)]
        [switch] $Unprotected
    )

    ## Throws (MsalCachePersistenceException) when the store cannot be written and read back,
    ## e.g. on Linux with no keyring in the session.
    $Properties = Get-MsalCacheStorageProperty $Store -Unprotected:$Unprotected
    $Helper = [Microsoft.Identity.Client.Extensions.Msal.MsalCacheHelper]::CreateAsync($Properties, $null).GetAwaiter().GetResult()
    $Helper.VerifyPersistence()
    return $Helper
}
