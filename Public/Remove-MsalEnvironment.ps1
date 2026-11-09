<#
.SYNOPSIS
    Removes a user-defined cloud (environment).
.DESCRIPTION
    Removes an environment added with Add-MsalEnvironment from the session and from the
    environments.json file of the Posh-MSAL folder of ApplicationData. Built-in environments cannot be
    removed. Client applications already created for that cloud keep working.
.EXAMPLE
    Remove-MsalEnvironment -Name 'Contoso'
    Removes the Contoso environment.
.INPUTS
    System.String
.OUTPUTS
    None.
.LINK
    Add-MsalEnvironment
#>
function Remove-MsalEnvironment {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    param (
        # Name of the user-defined environment to remove.
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [string[]] $Name
    )

    process {
        foreach ($EnvironmentName in $Name) {
            $Current = $script:ModuleState.Environments | Where-Object Name -eq $EnvironmentName | Select-Object -First 1
            if (-not $Current) {
                Write-Error -Message ('Unknown environment "{0}".' -f $EnvironmentName) -Category ObjectNotFound -ErrorId 'MsalEnvironmentNotFound' -TargetObject $EnvironmentName
                continue
            }
            if ($Current.Type -eq 'BuiltIn') {
                Write-Error -Message ('"{0}" is a built-in environment and cannot be removed.' -f $EnvironmentName) -Category PermissionDenied -ErrorId 'MsalEnvironmentBuiltIn' -TargetObject $EnvironmentName
                continue
            }
            if ($PSCmdlet.ShouldProcess($EnvironmentName, 'Remove environment')) {
                [void] $script:ModuleState.Environments.Remove($Current)
                Export-MsalEnvironment
            }
        }
    }
}
