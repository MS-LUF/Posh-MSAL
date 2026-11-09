<#
.SYNOPSIS
    Validates one environment and returns it in the module's normalised form.
.DESCRIPTION
    Takes a hashtable or an object with Name, AzureADEndpoint, GraphEndpoint and, optionally,
    DisableInstanceDiscovery and AzureCloudInstance. The name must be letters, digits, hyphens or
    underscores; each endpoint must be an https URL with a host only, and is kept as
    https://host in lower case. Throws on any invalid value.
.EXAMPLE
    ConvertTo-MsalEnvironment @{ Name = 'Contoso'; AzureADEndpoint = 'https://login.contoso.com'; GraphEndpoint = 'https://graph.contoso.com' } -Type UserDefined
    Returns the Contoso environment, ready to add to the module state.
.OUTPUTS
    System.Management.Automation.PSCustomObject
#>
function ConvertTo-MsalEnvironment {
    [CmdletBinding()]
    [OutputType([psobject])]
    param (
        # Hashtable or object with Name, AzureADEndpoint, GraphEndpoint and optionally DisableInstanceDiscovery, AzureCloudInstance.
        [Parameter(Mandatory = $true, Position = 0)]
        [object] $InputObject,
        [Parameter(Mandatory = $true)]
        [ValidateSet('BuiltIn', 'UserDefined')]
        [string] $Type
    )

    ## Validates and normalises one environment. Throws on an invalid name or endpoint.
    $Source = @{}
    if ($InputObject -is [System.Collections.IDictionary]) { foreach ($Key in $InputObject.Keys) { $Source[[string] $Key] = $InputObject[$Key] } }
    else { foreach ($Property in $InputObject.psobject.Properties) { $Source[$Property.Name] = $Property.Value } }
    $Value = { param ($Key) $Source[$Key] }
    $Name = [string] (& $Value 'Name')
    if ($Name -notmatch '^[A-Za-z0-9][A-Za-z0-9_-]{0,63}$') {
        throw ('Invalid environment name "{0}": use letters, digits, "-" and "_" only.' -f $Name)
    }
    $Endpoints = @{}
    foreach ($Property in 'AzureADEndpoint', 'GraphEndpoint') {
        $Uri = $null
        if (-not [uri]::TryCreate([string] (& $Value $Property), [System.UriKind]::Absolute, [ref] $Uri) -or $Uri.Scheme -ne 'https' -or $Uri.AbsolutePath -ne '/' -or $Uri.Query -or $Uri.Fragment) {
            throw ('Invalid {0} "{1}" for environment "{2}": give an https URL with a host only, e.g. https://login.example.com.' -f $Property, (& $Value $Property), $Name)
        }
        $Endpoints[$Property] = 'https://{0}' -f $Uri.Authority.ToLowerInvariant()
    }
    # An older MSAL.NET loaded first by another module (kept with dll.lenientLoading) lacks the newer
    # values, such as GovFr before 4.6x: the environment then has none instead of failing the import.
    $AzureCloudInstance = $null
    $InstanceName = [string] (& $Value 'AzureCloudInstance')
    if ($InstanceName) {
        $Known = @([System.Enum]::GetNames([Microsoft.Identity.Client.AzureCloudInstance]) | Where-Object { $_ -eq $InstanceName })
        if ($Known.Count -gt 0) { $AzureCloudInstance = [Microsoft.Identity.Client.AzureCloudInstance] $Known[0] }
        else { Write-Verbose ('Environment "{0}": the loaded MSAL.NET has no AzureCloudInstance "{1}".' -f $Name, $InstanceName) }
    }

    $Environment = [PSCustomObject] @{
        PSTypeName               = 'PoshMsal.Environment'
        Name                     = $Name
        Type                     = $Type
        AzureADEndpoint          = $Endpoints.AzureADEndpoint
        GraphEndpoint            = $Endpoints.GraphEndpoint
        DisableInstanceDiscovery = [bool] (& $Value 'DisableInstanceDiscovery')
        AzureCloudInstance       = $AzureCloudInstance
    }
    return $Environment
}
