<#
.SYNOPSIS
    Copies the MSAL.PS token cache into the new user token cache, once.
.DESCRIPTION
    MSAL.PS kept its cache in one DPAPI-protected file, on Windows only. When that file exists and
    the new user store is still empty, its content is decrypted and written to the new store if it
    is an MSAL v3 cache (a JSON object). The old file is never changed. Does nothing on Linux.
.EXAMPLE
    Import-MsalLegacyTokenCache (New-MsalCacheHelper User)
    Fills an empty user store from the MSAL.PS cache, if there is one.
.OUTPUTS
    None.
#>
function Import-MsalLegacyTokenCache {
    [CmdletBinding()]
    param (
        # Helper of the new user token cache.
        [Parameter(Mandatory = $true, Position = 0)]
        [Microsoft.Identity.Client.Extensions.Msal.MsalCacheHelper] $CacheHelper
    )

    ## Upstream MSAL.PS kept its cache in one DPAPI file (Windows only). Copy it once into the new
    ## user store, only while that store is still empty; the old file is left untouched.
    $LegacyPath = $script:ModuleState.LegacyTokenCachePath
    if ($script:ModuleState.OSPlatform -ne 'Windows' -or -not (Test-Path -LiteralPath $LegacyPath -PathType Leaf)) { return }
    $Current = $CacheHelper.LoadUnencryptedTokenCache()
    if ($null -ne $Current -and $Current.Length -gt 0) { return }

    try {
        if ($PSVersionTable.PSEdition -eq 'Desktop') { Add-Type -AssemblyName System.Security }
        $Bytes = [System.Security.Cryptography.ProtectedData]::Unprotect([System.IO.File]::ReadAllBytes($LegacyPath), $null, [System.Security.Cryptography.DataProtectionScope]::CurrentUser)
        # MSAL v3 cache format: a JSON object. Anything else would make every later cache read fail.
        $Json = [System.Text.Encoding]::UTF8.GetString($Bytes) | ConvertFrom-Json -ErrorAction Stop
        if ($Json -isnot [psobject] -or $Json -is [array]) { throw 'not an MSAL token cache' }
        $CacheHelper.SaveUnencryptedTokenCache($Bytes)
        Write-Verbose ('Migrated the MSAL.PS token cache "{0}" into the Posh-MSAL user token cache.' -f $LegacyPath)
    }
    catch {
        $Reason = $_.Exception
        while ($Reason.InnerException) { $Reason = $Reason.InnerException }
        Write-Warning ('The MSAL.PS token cache "{0}" was not migrated ({1}); sign in again.' -f $LegacyPath, $Reason.Message)
    }
}
