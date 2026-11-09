<#
.SYNOPSIS
    Saves the user-defined environments to the environments.json file of the user config folder.
.DESCRIPTION
    Writes every environment of type UserDefined held in the module state. When none is left, the
    file is removed rather than left empty.
.EXAMPLE
    Export-MsalEnvironment
    Saves the user-defined environments after a change.
.OUTPUTS
    None.
#>
function Export-MsalEnvironment {
    [CmdletBinding()]
    param ()

    ## Writes the user-defined environments to <ConfigDirectory>/environments.json (an empty file
    ## is removed rather than left behind).
    $Path = $script:ModuleState.EnvironmentFile
    $UserDefined = @($script:ModuleState.Environments | Where-Object Type -eq 'UserDefined' | ForEach-Object {
            [ordered] @{ Name = $_.Name; AzureADEndpoint = $_.AzureADEndpoint; GraphEndpoint = $_.GraphEndpoint; DisableInstanceDiscovery = $_.DisableInstanceDiscovery }
        })
    if ($UserDefined.Count -eq 0) {
        if (Test-Path -LiteralPath $Path) { Remove-Item -LiteralPath $Path -Force }
        return
    }
    [void] (Assert-MsalDirectory (Split-Path -Parent $Path))
    # -InputObject keeps a one-item list a JSON array under 5.1 as well.
    ConvertTo-Json -InputObject $UserDefined -Depth 3 | Set-Content -LiteralPath $Path -Encoding UTF8
}
