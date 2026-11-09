<#
.SYNOPSIS
    Builds the storage properties of the user or app token cache on disk.
.DESCRIPTION
    Gives the file name in the module's token cache folder and, on Linux, the keyring schema and
    attributes that find the secret again. On Windows the default protection is DPAPI. With
    Unprotected, a separate plain file is used, for hosts with neither DPAPI nor a keyring.
.EXAMPLE
    (Get-MsalCacheStorageProperty App -Unprotected).CacheFilePath
    Gets the path of the plain-file app token cache.
.OUTPUTS
    Microsoft.Identity.Client.Extensions.Msal.StorageCreationProperties
#>
function Get-MsalCacheStorageProperty {
    [CmdletBinding()]
    [OutputType([Microsoft.Identity.Client.Extensions.Msal.StorageCreationProperties])]
    param (
        # User: tokens of signed-in accounts (UserTokenCache). App: tokens of confidential clients (AppTokenCache).
        # Each has its own store, so one does not overwrite the other.
        [Parameter(Mandatory = $true, Position = 0)]
        [ValidateSet('User', 'App')]
        [string] $Store,
        # Plain file readable by the user account, for hosts with no DPAPI or keyring.
        [Parameter(Mandatory = $false)]
        [switch] $Unprotected
    )

    $FileName = 'Posh-MSAL.{0}cache{1}.bin' -f $Store.ToLowerInvariant(), $(if ($Unprotected) { '.unprotected' } else { '' })
    $Builder = New-Object Microsoft.Identity.Client.Extensions.Msal.StorageCreationPropertiesBuilder ($FileName, $script:ModuleState.TokenCacheDirectory)
    if ($Unprotected) {
        [void] $Builder.WithUnprotectedFile()
    }
    elseif ($script:ModuleState.OSPlatform -eq 'Linux') {
        # libsecret: the secret is found again by its schema and these two attributes.
        $Attribute1 = New-Object 'System.Collections.Generic.KeyValuePair[string,string]' ('ProductGroup', 'Posh-MSAL')
        $Attribute2 = New-Object 'System.Collections.Generic.KeyValuePair[string,string]' ('Store', $Store)
        [void] $Builder.WithLinuxKeyring('com.lucas-cueff.posh-msal', [Microsoft.Identity.Client.Extensions.Msal.MsalCacheHelper]::LinuxKeyRingDefaultCollection, ('Posh-MSAL {0} token cache' -f $Store.ToLowerInvariant()), $Attribute1, $Attribute2)
    }
    # Windows without -Unprotected: DPAPI, the Extensions.Msal default.
    return $Builder.Build()
}
