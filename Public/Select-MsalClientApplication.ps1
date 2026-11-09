<#
.SYNOPSIS
    Returns the session's client application for these settings, creating and keeping one if there is none.
.DESCRIPTION
    Builds an application with the same parameters as New-MsalClientApplication, then returns the
    application kept for the session that matches it (client id, credentials, redirect URI and
    authority, host and tenant). When none matches, the new application is added to the session list
    and returned. Get-MsalToken does the same, so the tokens an application caches are reused by
    later calls.

    Use it to get the application Get-MsalToken works with, for instance to pass it to
    Enable-MsalTokenCacheOnDisk or Get-MsalAccount.
.EXAMPLE
    Select-MsalClientApplication -ClientId '00000000-0000-0000-0000-000000000000' -TenantId 'contoso.onmicrosoft.com' | Enable-MsalTokenCacheOnDisk
    Makes the application Get-MsalToken uses for this client id and tenant keep its tokens on disk.
.EXAMPLE
    Select-MsalClientApplication -ClientId '00000000-0000-0000-0000-000000000000' -Environment 'USGov'
    Returns the session's public client application for the US Government cloud.
.INPUTS
    System.String, Microsoft.Identity.Client.PublicClientApplicationOptions, Microsoft.Identity.Client.ConfidentialClientApplicationOptions
.OUTPUTS
    Microsoft.Identity.Client.PublicClientApplication, Microsoft.Identity.Client.ConfidentialClientApplication
.LINK
    New-MsalClientApplication
.LINK
    Get-MsalToken
#>
function Select-MsalClientApplication {
    [CmdletBinding(DefaultParameterSetName = 'PublicClient')]
    [OutputType([Microsoft.Identity.Client.PublicClientApplication], [Microsoft.Identity.Client.ConfidentialClientApplication])]
    param
    (
        # Identifier of the client requesting the token.
        [Parameter(Mandatory = $true, ParameterSetName = 'PublicClient', Position = 0, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [Parameter(Mandatory = $false, ParameterSetName = 'PublicClient-InputObject', Position = 1, ValueFromPipelineByPropertyName = $true)]
        [Parameter(Mandatory = $true, ParameterSetName = 'ConfidentialClientSecret', Position = 0, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [Parameter(Mandatory = $true, ParameterSetName = 'ConfidentialClientCertificate', Position = 0, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [Parameter(Mandatory = $false, ParameterSetName = 'ConfidentialClient-InputObject', Position = 1, ValueFromPipelineByPropertyName = $true)]
        [string] $ClientId,
        # Secure secret of the client requesting the token.
        [Parameter(Mandatory = $true, ParameterSetName = 'ConfidentialClientSecret', ValueFromPipelineByPropertyName = $true)]
        [Parameter(Mandatory = $false, ParameterSetName = 'ConfidentialClient-InputObject', ValueFromPipelineByPropertyName = $true)]
        [securestring] $ClientSecret,
        # Client assertion certificate of the client requesting the token.
        [Parameter(Mandatory = $true, ParameterSetName = 'ConfidentialClientCertificate', ValueFromPipelineByPropertyName = $true)]
        [Parameter(Mandatory = $false, ParameterSetName = 'ConfidentialClient-InputObject', ValueFromPipelineByPropertyName = $true)]
        [System.Security.Cryptography.X509Certificates.X509Certificate2] $ClientCertificate,
        # Address to return to upon receiving a response from the authority.
        [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)]
        [uri] $RedirectUri,
        # Cloud to sign in to, as an MSAL.NET AzureCloudInstance value; -Environment covers more clouds. AzureGermany is refused (closed in 2021).
        [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)]
        [Microsoft.Identity.Client.AzureCloudInstance] $AzureCloudInstance,
        # Cloud to sign in to: a built-in or user-defined environment (Get-MsalEnvironment).
        [Parameter(Mandatory = $false)]
        [ArgumentCompleter( { $Word = $args[2]; (Get-MsalEnvironment).Name | Where-Object { $_ -like "$Word*" } })]
        [string] $Environment,
        # Tenant identifier of the authority to issue token.
        [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)]
        [string] $TenantId,
        # Address of the authority to issue token.
        [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)]
        [uri] $Authority,
        # Sign in through the Windows authentication broker (WAM); Windows only.
        [Parameter(Mandatory = $false, ParameterSetName = 'PublicClient', ValueFromPipelineByPropertyName = $true)]
        [Parameter(Mandatory = $false, ParameterSetName = 'PublicClient-InputObject', ValueFromPipelineByPropertyName = $true)]
        [switch] $AuthenticationBroker,
        # MSAL.NET options of a public client application, used instead of -ClientId; its authority is kept unless a cloud or tenant parameter is given.
        [Parameter(Mandatory = $true, ParameterSetName = 'PublicClient-InputObject', Position = 0, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [Microsoft.Identity.Client.PublicClientApplicationOptions] $PublicClientOptions,
        # MSAL.NET options of a confidential client application, used instead of -ClientId; its authority is kept unless a cloud or tenant parameter is given.
        [Parameter(Mandatory = $true, ParameterSetName = 'ConfidentialClient-InputObject', Position = 0, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [Microsoft.Identity.Client.ConfidentialClientApplicationOptions] $ConfidentialClientOptions
    )

    process {
        $paramNewMsalClientApplication = Select-MsalBoundParameter $PSBoundParameters -CommandName New-MsalClientApplication -ExcludeParameters ErrorAction
        $NewClientApplication = New-MsalClientApplication -ErrorAction Stop @paramNewMsalClientApplication
        switch -Wildcard ($PSCmdlet.ParameterSetName) {
            "PublicClient*" {
                [Microsoft.Identity.Client.IPublicClientApplication] $ClientApplication = $PublicClientApplications | Where-Object { $_.AppConfig.ClientId -eq $NewClientApplication.AppConfig.ClientId -and $_.AppConfig.Authority.AuthorityInfo.CanonicalAuthority -eq $NewClientApplication.AppConfig.Authority.AuthorityInfo.CanonicalAuthority -and $_.AppConfig.RedirectUri -eq $NewClientApplication.AppConfig.RedirectUri -and $_.AppConfig.IsBrokerEnabled -eq $NewClientApplication.AppConfig.IsBrokerEnabled } | Select-Object -Last 1
                break
            }
            "ConfidentialClientSecret" {
                [Microsoft.Identity.Client.IConfidentialClientApplication] $ClientApplication = $ConfidentialClientApplications | Where-Object { $_.AppConfig.ClientId -eq $NewClientApplication.AppConfig.ClientId -and $_.AppConfig.Authority.AuthorityInfo.CanonicalAuthority -eq $NewClientApplication.AppConfig.Authority.AuthorityInfo.CanonicalAuthority -and $_.AppConfig.ClientSecret -eq $NewClientApplication.AppConfig.ClientSecret -and $_.AppConfig.RedirectUri -eq $NewClientApplication.AppConfig.RedirectUri } | Select-Object -Last 1
                break
            }
            "ConfidentialClientCertificate" {
                [Microsoft.Identity.Client.IConfidentialClientApplication] $ClientApplication = $ConfidentialClientApplications | Where-Object { $_.AppConfig.ClientId -eq $NewClientApplication.AppConfig.ClientId -and $_.AppConfig.Authority.AuthorityInfo.CanonicalAuthority -eq $NewClientApplication.AppConfig.Authority.AuthorityInfo.CanonicalAuthority -and $_.AppConfig.ClientCredentialCertificate -eq $NewClientApplication.AppConfig.ClientCredentialCertificate -and $_.AppConfig.RedirectUri -eq $NewClientApplication.AppConfig.RedirectUri } | Select-Object -Last 1
                break
            }
            "ConfidentialClient-InputObject" {
                if ($NewClientApplication.AppConfig.ClientSecret) {
                    [Microsoft.Identity.Client.IConfidentialClientApplication] $ClientApplication = $ConfidentialClientApplications | Where-Object { $_.AppConfig.ClientId -eq $NewClientApplication.AppConfig.ClientId -and $_.AppConfig.Authority.AuthorityInfo.CanonicalAuthority -eq $NewClientApplication.AppConfig.Authority.AuthorityInfo.CanonicalAuthority -and $_.AppConfig.ClientSecret -eq $NewClientApplication.AppConfig.ClientSecret -and $_.AppConfig.RedirectUri -eq $NewClientApplication.AppConfig.RedirectUri } | Select-Object -Last 1
                }
                else {
                    [Microsoft.Identity.Client.IConfidentialClientApplication] $ClientApplication = $ConfidentialClientApplications | Where-Object { $_.AppConfig.ClientId -eq $NewClientApplication.AppConfig.ClientId -and $_.AppConfig.Authority.AuthorityInfo.CanonicalAuthority -eq $NewClientApplication.AppConfig.Authority.AuthorityInfo.CanonicalAuthority -and $_.AppConfig.ClientCredentialCertificate -eq $NewClientApplication.AppConfig.ClientCredentialCertificate -and $_.AppConfig.RedirectUri -eq $NewClientApplication.AppConfig.RedirectUri } | Select-Object -Last 1
                }
                break
            }
        }

        if (!$ClientApplication) {
            $ClientApplication = $NewClientApplication
            Write-Debug ('Adding Application with ClientId [{0}] and RedirectUri [{1}] to cache.' -f $ClientApplication.AppConfig.ClientId, $ClientApplication.AppConfig.RedirectUri)
            Add-MsalClientApplication $ClientApplication
        }
        else {
            Write-Debug ('Using Application with ClientId [{0}] and RedirectUri [{1}] from cache.' -f $ClientApplication.AppConfig.ClientId, $ClientApplication.AppConfig.RedirectUri)
        }

        return $ClientApplication
    }
}

