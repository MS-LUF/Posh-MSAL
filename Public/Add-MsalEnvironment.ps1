<#
.SYNOPSIS
    Adds a user-defined cloud (environment).
.DESCRIPTION
    Adds an environment for a cloud the built-in ones do not cover, and saves it in the
    environments.json file of the Posh-MSAL folder of ApplicationData, so that later sessions have
    it. The endpoints must be https URLs with a host only, and the name must not be taken.

    DisableInstanceDiscovery is only needed for an authority host MSAL.NET does not know. It also
    turns off MSAL's authority validation, so only use it for an authority you trust.
.EXAMPLE
    Add-MsalEnvironment -Name 'Contoso' -AzureADEndpoint 'https://login.contoso.com' -GraphEndpoint 'https://graph.contoso.com'
    Adds an environment, then usable with Get-MsalToken -Environment Contoso.
.INPUTS
    System.Management.Automation.PSObject
.OUTPUTS
    System.Management.Automation.PSCustomObject
.LINK
    Get-MsalEnvironment
.LINK
    Set-MsalEnvironment
.LINK
    Remove-MsalEnvironment
#>
function Add-MsalEnvironment {
    [CmdletBinding(SupportsShouldProcess = $true)]
    [OutputType([psobject])]
    param (
        # Name of the environment (letters, digits, "-" and "_").
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipelineByPropertyName = $true)]
        [string] $Name,
        # Authority host, e.g. https://login.microsoftonline.com.
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [uri] $AzureADEndpoint,
        # Microsoft Graph endpoint, which gives the default scope, e.g. https://graph.microsoft.com.
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [uri] $GraphEndpoint,
        # Turn off MSAL instance discovery (and authority validation) for this environment.
        [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)]
        [switch] $DisableInstanceDiscovery
    )

    process {
        if ($script:ModuleState.Environments | Where-Object Name -eq $Name) {
            Write-Error -Message ('An environment named "{0}" already exists; use Set-MsalEnvironment to change a user-defined one.' -f $Name) -Category ResourceExists -ErrorId 'MsalEnvironmentExists' -TargetObject $Name
            return
        }
        try {
            $Environment = ConvertTo-MsalEnvironment @{ Name = $Name; AzureADEndpoint = $AzureADEndpoint.OriginalString; GraphEndpoint = $GraphEndpoint.OriginalString; DisableInstanceDiscovery = [bool] $DisableInstanceDiscovery } -Type UserDefined
        }
        catch {
            Write-Error -Message $_.Exception.Message -Category InvalidArgument -ErrorId 'MsalEnvironmentInvalid' -TargetObject $Name
            return
        }
        if ($PSCmdlet.ShouldProcess($Name, 'Add environment')) {
            $script:ModuleState.Environments.Add($Environment)
            Export-MsalEnvironment
            $Environment
        }
    }
}
