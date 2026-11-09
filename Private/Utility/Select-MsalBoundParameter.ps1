<#
.SYNOPSIS
    Filters a hashtable or PSBoundParameters containing PowerShell command parameters to only those valid for specified command.
.EXAMPLE
    PS C:\>Select-MsalBoundParameter @{Name='Valid'; Verbose=$true; NotAParameter='Remove'} -CommandName Get-Process -ExcludeParameters 'Verbose'
    Filters the parameter hashtable to only include valid parameters for the Get-Process command and exclude the Verbose parameter.
.EXAMPLE
    PS C:\>Select-MsalBoundParameter @{Name='Valid'; Verbose=$true; NotAParameter='Remove'} -CommandName Get-Process -CommandParameterSet NameWithUserName
    Filters the parameter hashtable to only include valid parameters for the Get-Process command in the "NameWithUserName" ParameterSet.
.INPUTS
    System.String
#>
function Select-MsalBoundParameter {
    [CmdletBinding()]
    [OutputType([hashtable])]
    param (
        # Specifies the parameter key pairs to be filtered.
        [Parameter(Mandatory = $true, Position = 1, ValueFromPipeline = $true)]
        [hashtable] $NamedParameters,

        # Specifies the parameter names to remove from the output.
        [Parameter(Mandatory = $false)]
        [ArgumentCompleter( {
                $wordToComplete = $args[2]; $fakeBoundParameters = $args[4]
                if ($fakeBoundParameters.ContainsKey('NamedParameters')) {
                    [string[]]$fakeBoundParameters.NamedParameters.Keys | Where-Object { $_ -Like "$wordToComplete*" }
                }
            })]
        [string[]] $ExcludeParameters,

        # Specifies the name of a PowerShell command to further filter valid parameters.
        [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNullOrEmpty()]
        [ArgumentCompleter( {
                $wordToComplete = $args[2]
                [array] $CommandInfo = Get-Command "$wordToComplete*"
                if ($CommandInfo) {
                    $CommandInfo.Name
                }
            })]
        [Alias('Name')]
        [string] $CommandName,

        # Specifies a parameter set of the PowerShell command to further filter valid parameters.
        [Parameter(Mandatory = $false)]
        [ArgumentCompleter( {
                $wordToComplete = $args[2]; $fakeBoundParameters = $args[4]
                if ($fakeBoundParameters.ContainsKey('CommandName')) {
                    [array] $CommandInfo = Get-Command $fakeBoundParameters.CommandName
                    if ($CommandInfo) {
                        $CommandInfo[0].ParameterSets.Name | Where-Object { $_ -Like "$wordToComplete*" }
                    }
                }
            })]
        [string[]] $CommandParameterSets
    )

    process {
        [hashtable] $SelectedParameters = $NamedParameters.Clone()

        [string[]] $CommandParameters = $null
        if ($CommandName) {
            $CommandInfo = Get-Command $CommandName
            if ($CommandParameterSets) {
                [System.Collections.Generic.List[string]] $listCommandParameters = New-Object System.Collections.Generic.List[string]
                foreach ($CommandParameterSet in $CommandParameterSets) {
                    $listCommandParameters.AddRange([string[]]($CommandInfo.ParameterSets | Where-Object Name -eq $CommandParameterSet | Select-Object -ExpandProperty Parameters | Select-Object -ExpandProperty Name))
                }
                $CommandParameters = $listCommandParameters | Select-Object -Unique
            }
            else {
                $CommandParameters = $CommandInfo.Parameters.Keys
            }
        }

        [string[]] $ParameterKeys = $SelectedParameters.Keys
        foreach ($ParameterKey in $ParameterKeys) {
            if ($ExcludeParameters -contains $ParameterKey -or ($CommandParameters -and $CommandParameters -notcontains $ParameterKey)) {
                $SelectedParameters.Remove($ParameterKey)
            }
        }

        return $SelectedParameters
    }
}

