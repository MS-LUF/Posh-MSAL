<#
.SYNOPSIS
    Returns the environment with this exact name, or throws.
.DESCRIPTION
    The error message lists the known environments and points to Add-MsalEnvironment.
.EXAMPLE
    (Get-MsalEnvironmentByName 'BleuCloud').GraphEndpoint
    Gets the Graph endpoint of Bleu.
.OUTPUTS
    System.Management.Automation.PSCustomObject
#>
function Get-MsalEnvironmentByName {
    [CmdletBinding()]
    [OutputType([psobject])]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [string] $Name
    )

    $Environment = $script:ModuleState.Environments | Where-Object Name -eq $Name | Select-Object -First 1
    if (-not $Environment) {
        throw ('Unknown environment "{0}". Known environments: {1}. Add one with Add-MsalEnvironment.' -f $Name, (($script:ModuleState.Environments | ForEach-Object Name) -join ', '))
    }
    return $Environment
}
