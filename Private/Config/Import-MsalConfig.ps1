<#
.SYNOPSIS
    Import Configuration
.EXAMPLE
    PS C:\>Import-MsalConfig
    Import Configuration
.INPUTS
    System.String
#>
function Import-MsalConfig {
    [CmdletBinding()]
    [OutputType([psobject])]
    param (
        # Configuration File Path
        [Parameter(Mandatory = $false)]
        [string] $Path = 'config.json'
    )

    ## Initialize
    if (![IO.Path]::IsPathRooted($Path)) {
        $AppDataDirectory = $script:ModuleState.ConfigDirectory
        $Path = Join-Path $AppDataDirectory $Path
    }

    if (Test-Path $Path) {
        ## Load from File
        $ModuleConfigPersistent = Get-Content $Path -Raw | ConvertFrom-Json

        ## Return Config
        return $ModuleConfigPersistent
    }
}

