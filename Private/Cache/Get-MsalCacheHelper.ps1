<#
.SYNOPSIS
    Returns the session's cache helper for the user or app token cache on disk.
.DESCRIPTION
    One helper per store is created for the session and reused. The encrypted store (DPAPI on
    Windows, the keyring on Linux) is always tried first; when it cannot be used, the function
    throws MsalTokenCacheNotProtected, unless AllowUnencryptedStorage is given, in which case it
    falls back to a plain file and warns. The user store also receives the old MSAL.PS cache once.
.EXAMPLE
    (Get-MsalCacheHelper User).RegisterCache($Application.UserTokenCache)
    Makes the application's user token cache persist in the encrypted user store.
.OUTPUTS
    Microsoft.Identity.Client.Extensions.Msal.MsalCacheHelper
#>
function Get-MsalCacheHelper {
    [CmdletBinding()]
    [OutputType([Microsoft.Identity.Client.Extensions.Msal.MsalCacheHelper])]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [ValidateSet('User', 'App')]
        [string] $Store,
        # Fall back to a plain file when the encrypted store cannot be used.
        [Parameter(Mandatory = $false)]
        [switch] $AllowUnencryptedStorage
    )

    ## One helper per store for the session; the encrypted store is always tried first.
    $Helpers = $script:ModuleState.TokenCacheHelpers
    if ($Helpers.ContainsKey($Store)) { return $Helpers[$Store] }
    try {
        $Helper = New-MsalCacheHelper $Store
        $Helpers[$Store] = $Helper
    }
    catch {
        $Reason = $_.Exception
        while ($Reason.InnerException) { $Reason = $Reason.InnerException }
        if (-not $AllowUnencryptedStorage) {
            $Hint = if ($script:ModuleState.OSPlatform -eq 'Linux') { ' On Linux this needs libsecret and an unlocked keyring (e.g. GNOME Keyring) in the session; SSH and headless sessions usually have none.' } else { '' }
            $Message = 'The token cache cannot be stored encrypted on this system: {0}.{1} Use -AllowUnencryptedStorage to keep it in a plain file readable by your account instead.' -f $Reason.Message.TrimEnd('.'), $Hint
            $PSCmdlet.ThrowTerminatingError((New-Object System.Management.Automation.ErrorRecord ((New-Object System.InvalidOperationException ($Message, $Reason)), 'MsalTokenCacheNotProtected', [System.Management.Automation.ErrorCategory]::NotEnabled, $Store)))
        }
        $Key = $Store + '.Unprotected'
        if ($Helpers.ContainsKey($Key)) { $Helper = $Helpers[$Key] }
        else {
            $Helper = New-MsalCacheHelper $Store -Unprotected
            $Helpers[$Key] = $Helper
        }
        Write-Warning ('The {0} token cache is NOT encrypted ({1}); it is stored in "{2}", readable by anyone with access to your account.' -f $Store.ToLowerInvariant(), $Reason.Message.TrimEnd('.'), (Get-MsalCacheStorageProperty $Store -Unprotected).CacheFilePath)
    }
    if ($Store -eq 'User') { Import-MsalLegacyTokenCache $Helper }
    return $Helper
}
