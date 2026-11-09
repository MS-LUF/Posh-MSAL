<#
.SYNOPSIS
    Tells whether a client application matches the filters of Get-MsalClientApplication.
.DESCRIPTION
    Every filter given must match: client id, redirect URI (compared as parsed URIs, since MSAL
    normalises them), tenant, authority, authority host. The tenant is read from the canonical
    authority, because the application's AppConfig.TenantId is empty when it was built from a URL.
.EXAMPLE
    Test-MsalApplicationMatch $Application -ClientId $ClientId -AuthorityHost 'login.microsoftonline.us'
    True when the application has this client id and signs in to the US Government authority host.
.OUTPUTS
    System.Boolean
#>
function Test-MsalApplicationMatch {
    [CmdletBinding()]
    [OutputType([bool])]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [Microsoft.Identity.Client.IClientApplicationBase] $Application,
        [Parameter(Mandatory = $false)]
        [string] $ClientId,
        [Parameter(Mandatory = $false)]
        [uri] $RedirectUri,
        [Parameter(Mandatory = $false)]
        [string] $TenantId,
        [Parameter(Mandatory = $false)]
        [uri] $Authority,
        # Authority host of an environment, e.g. login.microsoftonline.us.
        [Parameter(Mandatory = $false)]
        [string] $AuthorityHost
    )

    ## Filters of Get-MsalClientApplication. The tenant is read from the application's authority:
    ## AppConfig.TenantId is empty when the authority is given as a URL.
    $Config = $Application.AppConfig
    $Canonical = $Config.Authority.AuthorityInfo.CanonicalAuthority
    $Tenant = @($Canonical.AbsolutePath.Split('/') | Where-Object { $_ }) | Select-Object -First 1
    if ($ClientId -and $Config.ClientId -ne $ClientId) { return $false }
    if ($RedirectUri -and $Config.RedirectUri -ne $RedirectUri.AbsoluteUri -and $Config.RedirectUri -ne $RedirectUri.OriginalString) { return $false }
    if ($TenantId -and $Tenant -ne $TenantId) { return $false }
    if ($Authority -and $Canonical.AbsoluteUri.TrimEnd('/') -ne $Authority.AbsoluteUri.TrimEnd('/')) { return $false }
    if ($AuthorityHost -and $Canonical.Authority -ne $AuthorityHost) { return $false }
    return $true
}
