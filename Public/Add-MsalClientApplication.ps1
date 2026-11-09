<#
.SYNOPSIS
    Adds a client application to the applications kept for the session.
.DESCRIPTION
    Posh-MSAL keeps a list of client applications for the session so that Get-MsalToken and
    Select-MsalClientApplication reuse them, and with them their token caches. This cmdlet adds an
    application built with New-MsalClientApplication to that list.

    Adding an application already in the list is an error (AddMsalClientApplicationFailureAlreadyExists).
.EXAMPLE
    New-MsalClientApplication -ClientId '00000000-0000-0000-0000-000000000000' -TenantId 'contoso.onmicrosoft.com' | Add-MsalClientApplication
    Builds a public client application and keeps it for the session.
.EXAMPLE
    $ClientApplication | Add-MsalClientApplication -PassThru | Enable-MsalTokenCacheOnDisk
    Keeps the application for the session, then makes it keep its tokens on disk.
.INPUTS
    Microsoft.Identity.Client.IPublicClientApplication, Microsoft.Identity.Client.IConfidentialClientApplication
.OUTPUTS
    With -PassThru, the application added; otherwise nothing.
.LINK
    Get-MsalClientApplication
.LINK
    Remove-MsalClientApplication
#>
function Add-MsalClientApplication {
    [CmdletBinding(DefaultParameterSetName = 'PublicClient')]
    [OutputType([Microsoft.Identity.Client.PublicClientApplication], [Microsoft.Identity.Client.ConfidentialClientApplication])]
    param
    (
        # Public client application to use, from New-MsalClientApplication or Select-MsalClientApplication.
        [Parameter(Mandatory = $true, ParameterSetName = 'PublicClient', Position = 0, ValueFromPipeline = $true)]
        [Microsoft.Identity.Client.IPublicClientApplication] $PublicClientApplication,
        # Confidential client application to use, from New-MsalClientApplication or Select-MsalClientApplication.
        [Parameter(Mandatory = $true, ParameterSetName = 'ConfidentialClient', Position = 0, ValueFromPipeline = $true)]
        [Microsoft.Identity.Client.IConfidentialClientApplication] $ConfidentialClientApplication,
        # Returns the client application.
        [Parameter(Mandatory = $false)]
        [switch] $PassThru
    )

    process {
        switch ($PSCmdlet.ParameterSetName) {
            "PublicClient" {
                $ClientApplication = $PublicClientApplication
                if (!$PublicClientApplications.Contains($ClientApplication)) {
                    $PublicClientApplications.Add($ClientApplication)
                }
                else {
                    $Exception = New-Object ArgumentException -ArgumentList 'The client application provided already exists in the session cache.'
                    Write-Error -Exception $Exception -Category ([System.Management.Automation.ErrorCategory]::ResourceExists) -CategoryActivity $MyInvocation.MyCommand -ErrorId 'AddMsalClientApplicationFailureAlreadyExists' -TargetObject $ClientApplication #-ErrorAction Stop
                }
                break
            }
            "ConfidentialClient" {
                $ClientApplication = $ConfidentialClientApplication
                if (!$ConfidentialClientApplications.Contains($ClientApplication)) {
                    $ConfidentialClientApplications.Add($ClientApplication)
                }
                else {
                    $Exception = New-Object ArgumentException -ArgumentList 'The client application provided already exists in the session cache.'
                    Write-Error -Exception $Exception -Category ([System.Management.Automation.ErrorCategory]::ResourceExists) -CategoryActivity $MyInvocation.MyCommand -ErrorId 'AddMsalClientApplicationFailureAlreadyExists' -TargetObject $ClientApplication #-ErrorAction Stop
                }
                break
            }
        }

        if ($PassThru) {
            Write-Output $ClientApplication
        }
    }
}

