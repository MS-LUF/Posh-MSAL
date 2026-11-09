<#
.SYNOPSIS
    Forgets the client applications kept for the session, or deletes the token cache on disk.
.DESCRIPTION
    Without FromDisk, empties the session's list of client applications: their tokens held in memory
    are lost, and the next Get-MsalToken builds new applications.

    With FromDisk, deletes the token caches on disk instead and leaves the session's list alone: the
    user and app caches, encrypted and unencrypted, their keyring entries on Linux, and the old
    MSAL.PS cache file, so that it is not copied again. Applications enabled with
    Enable-MsalTokenCacheOnDisk then read an empty cache.
.EXAMPLE
    Clear-MsalTokenCache
    Forgets every client application of the session.
.EXAMPLE
    Clear-MsalTokenCache -FromDisk
    Deletes the token cache on disk.
.INPUTS
    None.
.OUTPUTS
    None.
.LINK
    Enable-MsalTokenCacheOnDisk
#>
function Clear-MsalTokenCache {
    [CmdletBinding()]
    param(
        # Clear the token cache from disk.
        [Parameter(Mandatory = $false)]
        [switch] $FromDisk
    )

    if ($FromDisk) {
        if ($script:ModuleFeatureSupport.TokenCacheSupport) {
            foreach ($Store in 'User', 'App') {
                foreach ($Unprotected in $false, $true) {
                    $Properties = Get-MsalCacheStorageProperty $Store -Unprotected:$Unprotected
                    try {
                        # Removes the file and, on Linux, the keyring secret.
                        [Microsoft.Identity.Client.Extensions.Msal.Storage]::Create($Properties, $null).Clear($false)
                    }
                    catch {
                        # No keyring on this host: nothing was stored there.
                        Write-Debug ('Clearing {0}: {1}' -f $Properties.CacheFilePath, $_.Exception.Message)
                    }
                    if (Test-Path -LiteralPath $Properties.CacheFilePath) { Remove-Item -LiteralPath $Properties.CacheFilePath -Force }
                }
            }
        }
        $LegacyPath = $script:ModuleState.LegacyTokenCachePath
        if (Test-Path -LiteralPath $LegacyPath) { Remove-Item -LiteralPath $LegacyPath -Force }
    }
    else {
        $script:PublicClientApplications = New-Object 'System.Collections.Generic.List[Microsoft.Identity.Client.IPublicClientApplication]'
        $script:ConfidentialClientApplications = New-Object 'System.Collections.Generic.List[Microsoft.Identity.Client.IConfidentialClientApplication]'
    }
}
