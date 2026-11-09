<#
.SYNOPSIS
    Removes a client application from the applications kept for the session.
.DESCRIPTION
    Removes an application from the session list used by Get-MsalToken and
    Select-MsalClientApplication; the next call with the same settings builds a new application,
    with an empty token cache unless the cache on disk is enabled.

    An application that is not in the list is a terminating error
    (RemoveMsalClientApplicationFailureNotFound). The cmdlet supports WhatIf and Confirm.
.EXAMPLE
    Get-MsalClientApplication -ClientId '00000000-0000-0000-0000-000000000000' | Remove-MsalClientApplication
    Removes every session application with this client id.
.INPUTS
    Microsoft.Identity.Client.IPublicClientApplication, Microsoft.Identity.Client.IConfidentialClientApplication
.OUTPUTS
    None.
.LINK
    Get-MsalClientApplication
.LINK
    Clear-MsalTokenCache
#>
function Remove-MsalClientApplication {
    [CmdletBinding(DefaultParameterSetName = 'PublicClient', SupportsShouldProcess = $true, ConfirmImpact = 'Low')]
    [OutputType([System.Void])]
    param
    (
        # Public client application to use, from New-MsalClientApplication or Select-MsalClientApplication.
        [Parameter(Mandatory = $true, ParameterSetName = 'PublicClient', Position = 0, ValueFromPipeline = $true)]
        [Microsoft.Identity.Client.IPublicClientApplication] $PublicClientApplication,
        # Confidential client application to use, from New-MsalClientApplication or Select-MsalClientApplication.
        [Parameter(Mandatory = $true, ParameterSetName = 'ConfidentialClient', Position = 0, ValueFromPipeline = $true)]
        [Microsoft.Identity.Client.IConfidentialClientApplication] $ConfidentialClientApplication
    )

    process {
        if ($PSCmdlet.ParameterSetName -eq 'PublicClient') { $ClientApplication = $PublicClientApplication; $List = $script:PublicClientApplications }
        else { $ClientApplication = $ConfidentialClientApplication; $List = $script:ConfidentialClientApplications }

        if (-not $List.Contains($ClientApplication)) {
            $Exception = New-Object ArgumentException -ArgumentList 'The client application provided was not found in session cache.'
            Write-Error -Exception $Exception -Category ([System.Management.Automation.ErrorCategory]::ObjectNotFound) -CategoryActivity $MyInvocation.MyCommand -ErrorId 'RemoveMsalClientApplicationFailureNotFound' -TargetObject $ClientApplication -ErrorAction Stop
        }
        if ($PSCmdlet.ShouldProcess(('{0} ({1})' -f $ClientApplication.AppConfig.ClientId, $ClientApplication.Authority), 'Remove client application from the session')) {
            [void] $List.Remove($ClientApplication)
        }
    }
}

