<#
.SYNOPSIS
    Resolves the cloud, the authority and the default scope from the cloud parameters of a cmdlet.
.DESCRIPTION
    The only place with the precedence and conflict rules: Authority, then Environment, then
    AzureCloudInstance, then the Global environment. Parameters that name different authority
    hosts, or different tenants, are an error, as is AzureGermany.

    Without ApplicationAuthority, it returns the authority to build an application with. With it,
    it checks the request against that existing application, which MSAL only lets change its
    tenant, and returns the tenant to request.

    The result has Environment (null for an authority host no environment knows), Authority,
    TenantId, DefaultScope (the Graph endpoint followed by /.default) and DisableInstanceDiscovery.
.EXAMPLE
    Resolve-MsalEnvironment -Environment 'BleuCloud' -TenantId 'contoso.onmicrosoft.com'
    Returns the Bleu environment, its authority for that tenant and its default scope.
.OUTPUTS
    System.Management.Automation.PSCustomObject
#>
function Resolve-MsalEnvironment {
    [CmdletBinding()]
    [OutputType([psobject])]
    param (
        # Name of a built-in or user-defined environment.
        [Parameter(Mandatory = $false)]
        [string] $Environment,
        [Parameter(Mandatory = $false)]
        [Microsoft.Identity.Client.AzureCloudInstance] $AzureCloudInstance,
        [Parameter(Mandatory = $false)]
        [uri] $Authority,
        [Parameter(Mandatory = $false)]
        [string] $TenantId,
        # Authority of an existing application: resolve a request against it instead of building one.
        [Parameter(Mandatory = $false)]
        [uri] $ApplicationAuthority
    )

    ## Precedence: -Authority > -Environment > -AzureCloudInstance > Global; two that name different
    ## authority hosts are an error. Returns the environment (null for an authority host no
    ## environment knows), the authority to build with (build mode) or the tenant to request
    ## (application mode), and the environment's defaults.
    $FromName = $null
    if ($Environment) { $FromName = Get-MsalEnvironmentByName $Environment }
    $FromInstance = $null
    if ($PSBoundParameters.ContainsKey('AzureCloudInstance') -and $AzureCloudInstance -ne [Microsoft.Identity.Client.AzureCloudInstance]::None) {
        if ($AzureCloudInstance -eq [Microsoft.Identity.Client.AzureCloudInstance]::AzureGermany) {
            throw (New-Object System.ArgumentException 'Azure Germany (-AzureCloudInstance AzureGermany) was closed in 2021 and cannot be used. Use -Environment to choose another cloud.')
        }
        $FromInstance = $script:ModuleState.Environments | Where-Object { $_.AzureCloudInstance -eq $AzureCloudInstance } | Select-Object -First 1
        if (-not $FromInstance) { throw (New-Object System.ArgumentException ('-AzureCloudInstance {0} has no environment.' -f $AzureCloudInstance)) }
    }
    $HostOf = { param ($Endpoint) ([uri] $Endpoint).Authority.ToLowerInvariant() }
    if ($FromName -and $FromInstance -and (& $HostOf $FromName.AzureADEndpoint) -ne (& $HostOf $FromInstance.AzureADEndpoint)) {
        throw (New-Object System.ArgumentException ('-Environment {0} and -AzureCloudInstance {1} name different clouds; give only one.' -f $FromName.Name, $AzureCloudInstance))
    }
    $Resolved = if ($FromName) { $FromName } else { $FromInstance }
    $FirstWithHost = { param ($AuthorityHost) $script:ModuleState.Environments | Where-Object { (& $HostOf $_.AzureADEndpoint) -eq $AuthorityHost } | Select-Object -First 1 }

    $AuthorityHost = $null
    $AuthorityTenant = $null
    if ($Authority) {
        if (-not $Authority.IsAbsoluteUri) { throw (New-Object System.ArgumentException ('-Authority "{0}" is not an absolute URL.' -f $Authority.OriginalString)) }
        $AuthorityHost = $Authority.Authority.ToLowerInvariant()
        if ($Resolved -and (& $HostOf $Resolved.AzureADEndpoint) -ne $AuthorityHost) {
            throw (New-Object System.ArgumentException ('-Authority {0} is not in the {1} environment ({2}); give only one of them.' -f $Authority.AbsoluteUri, $Resolved.Name, $Resolved.AzureADEndpoint))
        }
        if (-not $Resolved) { $Resolved = & $FirstWithHost $AuthorityHost }
        $Segments = @($Authority.AbsolutePath.Split('/') | Where-Object { $_ })
        if ($Segments.Count -gt 0) { $AuthorityTenant = $Segments[0] }
    }
    if ($Resolved -and $AuthorityTenant -and $TenantId -and $AuthorityTenant -ne $TenantId) {
        throw (New-Object System.ArgumentException ('-TenantId {0} and the tenant of -Authority ({1}) differ; give only one.' -f $TenantId, $AuthorityTenant))
    }

    if ($ApplicationAuthority) {
        ## A request on an existing application: only the tenant can change (MSAL rejects another cloud).
        $ApplicationHost = $ApplicationAuthority.Authority.ToLowerInvariant()
        $RequestedHost = if ($AuthorityHost) { $AuthorityHost } elseif ($Resolved) { & $HostOf $Resolved.AzureADEndpoint } else { $null }
        if ($RequestedHost -and $RequestedHost -ne $ApplicationHost) {
            throw (New-Object System.ArgumentException ('The client application was built for {0}, not {1}; create one for that cloud with New-MsalClientApplication -Environment or -Authority.' -f $ApplicationHost, $RequestedHost))
        }
        if (-not $Resolved) { $Resolved = & $FirstWithHost $ApplicationHost }
        $RequestTenant = if ($TenantId) { $TenantId } elseif ($Resolved) { $AuthorityTenant } else { $null }
        $AuthorityToBuild = $null
    }
    else {
        if (-not $Resolved -and -not $Authority) { $Resolved = Get-MsalEnvironmentByName 'Global' }
        if (-not $Resolved -and $TenantId) {
            throw (New-Object System.ArgumentException ('-Authority {0} is not in a known environment, so -TenantId cannot be applied to it: put the tenant in -Authority.' -f $Authority.AbsoluteUri))
        }
        $RequestTenant = if ($TenantId) { $TenantId } elseif ($AuthorityTenant) { $AuthorityTenant } else { 'common' }
        if ($Authority -and ($AuthorityTenant -or -not $Resolved)) { $AuthorityToBuild = $Authority.AbsoluteUri }
        elseif ($Authority) { $AuthorityToBuild = 'https://{0}/{1}' -f $AuthorityHost, $RequestTenant }
        else { $AuthorityToBuild = '{0}/{1}' -f $Resolved.AzureADEndpoint, $RequestTenant }
    }

    return [PSCustomObject] @{
        Environment              = $Resolved
        Authority                = $AuthorityToBuild
        TenantId                 = $RequestTenant
        DefaultScope             = $(if ($Resolved) { '{0}/.default' -f $Resolved.GraphEndpoint } else { $null })
        DisableInstanceDiscovery = [bool] ($Resolved -and $Resolved.DisableInstanceDiscovery)
    }
}
