<#
.SYNOPSIS
    Gets the clouds (environments) Posh-MSAL can sign in to.
.DESCRIPTION
    Returns the built-in environments (Global, USGov, USGovDoD, China, BleuCloud, DelosCloud,
    GovSGCloud) and the user-defined ones added with Add-MsalEnvironment. An environment gives the
    authority host, the default scope (the Graph endpoint followed by /.default) and, on Windows
    PowerShell, the default redirect URI, for the Environment parameter of
    New-MsalClientApplication, Select-MsalClientApplication and Get-MsalToken.

    A name without wildcards that matches no environment is an error (MsalEnvironmentNotFound).
.EXAMPLE
    Get-MsalEnvironment
    Lists every environment.
.EXAMPLE
    Get-MsalEnvironment -Name 'BleuCloud'
    Gets the Bleu environment.
.EXAMPLE
    Get-MsalEnvironment -Name 'US*'
    Gets the two US Government environments.
.INPUTS
    System.String
.OUTPUTS
    System.Management.Automation.PSCustomObject
.LINK
    Add-MsalEnvironment
#>
function Get-MsalEnvironment {
    [CmdletBinding()]
    [OutputType([psobject])]
    param (
        # Name of the environment; wildcards are allowed.
        [Parameter(Mandatory = $false, Position = 0, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [SupportsWildcards()]
        [string[]] $Name = '*'
    )

    process {
        foreach ($Pattern in $Name) {
            $Found = @($script:ModuleState.Environments | Where-Object Name -like $Pattern)
            if (-not $Found -and -not [System.Management.Automation.WildcardPattern]::ContainsWildcardCharacters($Pattern)) {
                Write-Error -Message ('Unknown environment "{0}".' -f $Pattern) -Category ObjectNotFound -ErrorId 'MsalEnvironmentNotFound' -TargetObject $Pattern
            }
            Write-Output $Found
        }
    }
}
