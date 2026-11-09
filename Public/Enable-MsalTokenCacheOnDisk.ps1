<#
.SYNOPSIS
    Makes a client application keep its tokens on disk, encrypted, across sessions.
.DESCRIPTION
    Registers the application's token caches with the Posh-MSAL cache on disk, shared by every
    application and every PowerShell session of the user, through
    Microsoft.Identity.Client.Extensions.Msal. The cache is encrypted with DPAPI on Windows and kept
    in the keyring (libsecret) on Linux, in the Posh-MSAL folder of LocalApplicationData. Signed-in
    accounts go to the user token cache; the tokens of confidential clients go to a separate app
    token cache.

    The first time on Windows, an MSAL.PS cache found in the MSAL.PS folder of LocalApplicationData
    is copied into the user token cache; the old file is not changed.

    When the cache cannot be encrypted, as on Linux without a keyring (SSH or headless sessions), the
    cmdlet fails with MsalTokenCacheNotProtected unless AllowUnencryptedStorage is given; it then
    keeps a plain file readable by the user's account, and says so with a warning.

    On a platform with no cache on disk, it warns and the tokens stay in memory.
.EXAMPLE
    Select-MsalClientApplication -ClientId '00000000-0000-0000-0000-000000000000' -TenantId 'contoso.onmicrosoft.com' | Enable-MsalTokenCacheOnDisk
    Keeps the tokens of the application Get-MsalToken uses for this client id and tenant.
.EXAMPLE
    $ClientApplication | Enable-MsalTokenCacheOnDisk -AllowUnencryptedStorage -PassThru
    On a host with no keyring, keeps the cache in a plain file and returns the application.
.INPUTS
    Microsoft.Identity.Client.IPublicClientApplication, Microsoft.Identity.Client.IConfidentialClientApplication
.OUTPUTS
    With -PassThru, the application; otherwise nothing.
.LINK
    Clear-MsalTokenCache
.LINK
    Select-MsalClientApplication
#>
function Enable-MsalTokenCacheOnDisk {
    [CmdletBinding(DefaultParameterSetName = 'PublicClient')]
    [OutputType([Microsoft.Identity.Client.PublicClientApplication], [Microsoft.Identity.Client.ConfidentialClientApplication])]
    param
    (
        # Public client application to use, from New-MsalClientApplication or Select-MsalClientApplication.
        [Parameter(Mandatory = $true, ParameterSetName = 'PublicClient', Position = 0, ValueFromPipeline = $true)]
        [Microsoft.Identity.Client.IPublicClientApplication] $PublicClientApplication,
        # Confidential client application to use, from New-MsalClientApplication or Select-MsalClientApplication.
        [Parameter(Mandatory = $true, ParameterSetName = 'ConfidentialClient', Position = 0, ValueFromPipeline = $true)]
        [Microsoft.Identity.Client.IConfidentialClientApplication] $ConfidentialClientApplication,
        # Store the cache in a plain file when it cannot be encrypted on this system.
        [Parameter(Mandatory = $false)]
        [switch] $AllowUnencryptedStorage,
        # Returns the client application.
        [Parameter(Mandatory = $false)]
        [switch] $PassThru
    )

    process {
        switch ($PSCmdlet.ParameterSetName) {
            "PublicClient" {
                $ClientApplication = $PublicClientApplication
                break
            }
            "ConfidentialClient" {
                $ClientApplication = $ConfidentialClientApplication
                break
            }
        }

        if ($script:ModuleFeatureSupport.TokenCacheSupport) {
            (Get-MsalCacheHelper User -AllowUnencryptedStorage:$AllowUnencryptedStorage).RegisterCache($ClientApplication.UserTokenCache)
            if ($ClientApplication -is [Microsoft.Identity.Client.IConfidentialClientApplication]) {
                (Get-MsalCacheHelper App -AllowUnencryptedStorage:$AllowUnencryptedStorage).RegisterCache($ClientApplication.AppTokenCache)
            }
        }
        else {
            Write-Warning 'The token cache on disk is only available on Windows and Linux. The token cache will be stored in memory and not persisted on disk.'
        }

        if ($PassThru) {
            Write-Output $ClientApplication
        }
    }
}
