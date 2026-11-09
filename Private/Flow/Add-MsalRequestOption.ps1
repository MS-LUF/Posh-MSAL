<#
.SYNOPSIS
    Adds the options every flow takes to an MSAL request builder.
.DESCRIPTION
    Sets the tenant of the request (on the application's cloud), the correlation id and the extra
    query parameters, each only when given, and returns the builder.
.EXAMPLE
    Add-MsalRequestOption $Request -TenantId 'fabrikam.onmicrosoft.com' -CorrelationId (New-Guid)
    Sends the request to another tenant, with a correlation id.
.OUTPUTS
    The request builder given.
#>
function Add-MsalRequestOption {
    [CmdletBinding()]
    [OutputType([object])]
    param (
        # An MSAL request builder.
        [Parameter(Mandatory = $true, Position = 0)]
        [object] $Request,
        # Tenant of this request, on the application's cloud.
        [Parameter(Mandatory = $false)]
        [string] $TenantId,
        [Parameter(Mandatory = $false)]
        [guid] $CorrelationId = [guid]::Empty,
        [Parameter(Mandatory = $false)]
        [hashtable] $ExtraQueryParameters
    )

    ## Options every flow takes.
    if ($TenantId) { [void] $Request.WithTenantId($TenantId) }
    if ($CorrelationId -ne [guid]::Empty) { [void] $Request.WithCorrelationId($CorrelationId) }
    if ($ExtraQueryParameters) { [void] $Request.WithExtraQueryParameters((ConvertTo-MsalExtraQueryParameter $ExtraQueryParameters)) }
    return $Request
}
