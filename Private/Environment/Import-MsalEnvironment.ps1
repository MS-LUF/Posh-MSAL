<#
.SYNOPSIS
    Loads the built-in environments, then the user-defined ones.
.DESCRIPTION
    The built-in environments come from Data/MsalEnvironment.psd1, in their file order, which
    decides the environment a bare authority host maps to. The user-defined ones come from the
    environments.json file of the user config folder; a damaged file or entry is skipped with a
    warning. The loader keeps the result in a list in the module state.
.EXAMPLE
    [System.Collections.Generic.List[psobject]] @(Import-MsalEnvironment)
    Loads every environment into a list.
.OUTPUTS
    System.Management.Automation.PSCustomObject
#>
function Import-MsalEnvironment {
    [CmdletBinding()]
    [OutputType([psobject])]
    param ()

    ## Built-in environments first (their order decides which one a bare authority host maps to),
    ## then the user-defined ones from <ConfigDirectory>/environments.json.
    $Environments = New-Object System.Collections.Generic.List[psobject]
    $BuiltIn = Import-PowerShellDataFile -Path (Join-Path (Join-Path $script:ModuleRoot 'Data') 'MsalEnvironment.psd1')
    foreach ($Entry in $BuiltIn.Environments) { $Environments.Add((ConvertTo-MsalEnvironment $Entry -Type BuiltIn)) }

    $Path = $script:ModuleState.EnvironmentFile
    if (Test-Path -LiteralPath $Path -PathType Leaf) {
        try {
            # Assigned before @(): under 5.1 ConvertFrom-Json emits a JSON array as one object.
            $Saved = Get-Content -LiteralPath $Path -Raw | ConvertFrom-Json -ErrorAction Stop
            $Saved = @($Saved)
        }
        catch {
            Write-Warning ('Custom environments not loaded: "{0}" is not valid JSON ({1}).' -f $Path, $_.Exception.Message)
            $Saved = @()
        }
        foreach ($Entry in $Saved) {
            try {
                $Environment = ConvertTo-MsalEnvironment $Entry -Type UserDefined
                if ($Environments | Where-Object Name -eq $Environment.Name) { throw ('the name "{0}" is already used' -f $Environment.Name) }
                $Environments.Add($Environment)
            }
            catch {
                Write-Warning ('Custom environment skipped from "{0}": {1}' -f $Path, $_.Exception.Message)
            }
        }
    }
    # Callers keep them in a List[psobject] (see the loader).
    $Environments
}
