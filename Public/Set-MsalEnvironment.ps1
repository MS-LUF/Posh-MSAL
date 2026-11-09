<#
.SYNOPSIS
    Changes a user-defined cloud (environment).
.DESCRIPTION
    Changes the endpoints or the instance discovery setting of an environment added with
    Add-MsalEnvironment, and saves it. Parameters not given keep their value. Built-in environments
    cannot be changed. Client applications already created keep the authority they were built with.
.EXAMPLE
    Set-MsalEnvironment -Name 'Contoso' -GraphEndpoint 'https://graph2.contoso.com'
    Changes the Graph endpoint, and so the default scope, of the Contoso environment.
.EXAMPLE
    Set-MsalEnvironment -Name 'Contoso' -DisableInstanceDiscovery:$false
    Turns instance discovery back on for the Contoso environment.
.INPUTS
    System.Management.Automation.PSObject
.OUTPUTS
    System.Management.Automation.PSCustomObject
.LINK
    Add-MsalEnvironment
#>
function Set-MsalEnvironment {
    [CmdletBinding(SupportsShouldProcess = $true)]
    [OutputType([psobject])]
    param (
        # Name of the user-defined environment to change.
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipelineByPropertyName = $true)]
        [string] $Name,
        # New authority host, e.g. https://login.contoso.com.
        [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)]
        [uri] $AzureADEndpoint,
        # New Microsoft Graph endpoint, which gives the default scope.
        [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)]
        [uri] $GraphEndpoint,
        # Turn off MSAL instance discovery (and authority validation) for this environment; -DisableInstanceDiscovery:$false turns it back on.
        [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)]
        [switch] $DisableInstanceDiscovery
    )

    process {
        $Current = $script:ModuleState.Environments | Where-Object Name -eq $Name | Select-Object -First 1
        if (-not $Current) {
            Write-Error -Message ('Unknown environment "{0}".' -f $Name) -Category ObjectNotFound -ErrorId 'MsalEnvironmentNotFound' -TargetObject $Name
            return
        }
        if ($Current.Type -eq 'BuiltIn') {
            Write-Error -Message ('"{0}" is a built-in environment and cannot be changed; add a user-defined one with Add-MsalEnvironment.' -f $Name) -Category PermissionDenied -ErrorId 'MsalEnvironmentBuiltIn' -TargetObject $Name
            return
        }
        $Values = @{
            Name                     = $Current.Name
            AzureADEndpoint          = $(if ($AzureADEndpoint) { $AzureADEndpoint.OriginalString } else { $Current.AzureADEndpoint })
            GraphEndpoint            = $(if ($GraphEndpoint) { $GraphEndpoint.OriginalString } else { $Current.GraphEndpoint })
            DisableInstanceDiscovery = $(if ($PSBoundParameters.ContainsKey('DisableInstanceDiscovery')) { [bool] $DisableInstanceDiscovery } else { $Current.DisableInstanceDiscovery })
        }
        try {
            $Environment = ConvertTo-MsalEnvironment $Values -Type UserDefined
        }
        catch {
            Write-Error -Message $_.Exception.Message -Category InvalidArgument -ErrorId 'MsalEnvironmentInvalid' -TargetObject $Name
            return
        }
        if ($PSCmdlet.ShouldProcess($Name, 'Change environment')) {
            $Index = $script:ModuleState.Environments.IndexOf($Current)
            $script:ModuleState.Environments[$Index] = $Environment
            Export-MsalEnvironment
            $Environment
        }
    }
}
