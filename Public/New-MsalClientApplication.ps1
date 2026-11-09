<#
.SYNOPSIS
    Builds a public or confidential client application for one cloud and tenant.
.DESCRIPTION
    Returns a new MSAL.NET client application, to pass to Get-MsalToken or to keep for the session
    with Add-MsalClientApplication. Without a credential it is a public client, for users signing
    in; with ClientSecret, ClientCertificate (with ClientClaims or not) or ClientAssertion it is a
    confidential client. MSAL.NET application options can be piped in instead of ClientId.

    The authority comes from Environment, AzureCloudInstance or Authority, with TenantId (the public
    cloud and the common tenant by default); parameters that point at different clouds are an
    error. An application signs in to one cloud only: Get-MsalToken refuses a request for another.

    Without RedirectUri, a public client gets MSAL's default redirect URI; on Windows PowerShell 5.1
    it is the nativeclient page of the chosen cloud's authority host. AuthenticationBroker makes it
    sign in through the Windows broker (WAM).

    This cmdlet does not keep the application: Get-MsalToken and Select-MsalClientApplication build
    and keep their own.
.EXAMPLE
    New-MsalClientApplication -ClientId '00000000-0000-0000-0000-000000000000' -TenantId 'contoso.onmicrosoft.com'
    Builds a public client application for a tenant of the public cloud.
.EXAMPLE
    New-MsalClientApplication -ClientId '00000000-0000-0000-0000-000000000000' -TenantId 'contoso.onmicrosoft.com' -ClientCertificate (Get-Item 'Cert:\CurrentUser\My\0000000000000000000000000000000000000000') -Environment 'DelosCloud'
    Builds a confidential client application for Delos that signs in with a certificate.
.EXAMPLE
    [Microsoft.Identity.Client.PublicClientApplicationOptions] @{ ClientId = '00000000-0000-0000-0000-000000000000' } | New-MsalClientApplication -TenantId 'contoso.onmicrosoft.com'
    Builds a public client application from MSAL.NET options.
.INPUTS
    System.String, Microsoft.Identity.Client.PublicClientApplicationOptions, Microsoft.Identity.Client.ConfidentialClientApplicationOptions
.OUTPUTS
    Microsoft.Identity.Client.PublicClientApplication, Microsoft.Identity.Client.ConfidentialClientApplication
.LINK
    Select-MsalClientApplication
.LINK
    Add-MsalClientApplication
.LINK
    Get-MsalToken
#>
function New-MsalClientApplication {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '', Justification = 'Builds an object in memory and changes nothing on the system.')]
    [CmdletBinding(DefaultParameterSetName = 'PublicClient')]
    [OutputType([Microsoft.Identity.Client.PublicClientApplication], [Microsoft.Identity.Client.ConfidentialClientApplication])]
    param
    (
        # Identifier of the client requesting the token.
        [Parameter(Mandatory = $true, ParameterSetName = 'PublicClient', Position = 0, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [Parameter(Mandatory = $false, ParameterSetName = 'PublicClient-InputObject', Position = 1, ValueFromPipelineByPropertyName = $true)]
        [Parameter(Mandatory = $true, ParameterSetName = 'ConfidentialClientSecret', Position = 0, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [Parameter(Mandatory = $true, ParameterSetName = 'ConfidentialClientCertificate', Position = 0, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [Parameter(Mandatory = $true, ParameterSetName = 'ConfidentialClientClaims', Position = 0, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [Parameter(Mandatory = $true, ParameterSetName = 'ConfidentialClientAssertion', Position = 0, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [Parameter(Mandatory = $false, ParameterSetName = 'ConfidentialClient-InputObject', Position = 1, ValueFromPipelineByPropertyName = $true)]
        [string] $ClientId,
        # Secure secret of the client requesting the token.
        [Parameter(Mandatory = $false, ParameterSetName = 'ConfidentialClientSecret', ValueFromPipelineByPropertyName = $true)]
        [Parameter(Mandatory = $false, ParameterSetName = 'ConfidentialClient-InputObject', ValueFromPipelineByPropertyName = $true)]
        [securestring] $ClientSecret,
        # Client assertion certificate of the client requesting the token.
        [Parameter(Mandatory = $true, ParameterSetName = 'ConfidentialClientCertificate', ValueFromPipelineByPropertyName = $true)]
        [Parameter(Mandatory = $true, ParameterSetName = 'ConfidentialClientClaims', ValueFromPipelineByPropertyName = $true)]
        [Parameter(Mandatory = $false, ParameterSetName = 'ConfidentialClient-InputObject', ValueFromPipelineByPropertyName = $true)]
        [System.Security.Cryptography.X509Certificates.X509Certificate2] $ClientCertificate,
        # Set the specific client claims to sign. ClientCertificate must also be specified.
        [Parameter(Mandatory = $true, ParameterSetName = 'ConfidentialClientClaims', ValueFromPipelineByPropertyName = $true)]
        [Parameter(Mandatory = $false, ParameterSetName = 'ConfidentialClient-InputObject', ValueFromPipelineByPropertyName = $true)]
        [hashtable] $ClientClaims,
        # Set client assertion used to prove the identity of the application to Azure AD. This is a Base-64 encoded JWT.
        [Parameter(Mandatory = $true, ParameterSetName = 'ConfidentialClientAssertion', ValueFromPipelineByPropertyName = $true)]
        [Parameter(Mandatory = $false, ParameterSetName = 'ConfidentialClient-InputObject', ValueFromPipelineByPropertyName = $true)]
        [string] $ClientAssertion,
        # Address to return to upon receiving a response from the authority.
        [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)]
        [uri] $RedirectUri,
        # Cloud to sign in to, as an MSAL.NET AzureCloudInstance value; -Environment covers more clouds. AzureGermany is refused (closed in 2021).
        [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)]
        [Microsoft.Identity.Client.AzureCloudInstance] $AzureCloudInstance,
        # Cloud to sign in to: a built-in or user-defined environment (Get-MsalEnvironment). Gives the authority host and, on Windows PowerShell, the default redirect URI.
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
        # Sets Extra Query Parameters for the query string in the HTTP authentication request.
        [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)]
        [hashtable] $ExtraQueryParameters,
        # Allows usage of experimental features and APIs.
        [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)]
        [switch] $EnableExperimentalFeatures,
        # MSAL.NET options of a public client application, used instead of -ClientId; its authority is kept unless a cloud or tenant parameter is given.
        [Parameter(Mandatory = $true, ParameterSetName = 'PublicClient-InputObject', Position = 0, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [Microsoft.Identity.Client.PublicClientApplicationOptions] $PublicClientOptions,
        # MSAL.NET options of a confidential client application, used instead of -ClientId; its authority is kept unless a cloud or tenant parameter is given.
        [Parameter(Mandatory = $true, ParameterSetName = 'ConfidentialClient-InputObject', Position = 0, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [Microsoft.Identity.Client.ConfidentialClientApplicationOptions] $ConfidentialClientOptions
    )

    process {
        ## Cloud and authority. An options object with no cloud parameter keeps its own authority.
        $CloudParameters = @{}
        foreach ($Key in 'Environment', 'AzureCloudInstance', 'Authority', 'TenantId') { if ($PSBoundParameters.ContainsKey($Key)) { $CloudParameters[$Key] = $PSBoundParameters[$Key] } }
        $Resolved = $null
        if ($CloudParameters.Count -gt 0 -or -not ($PublicClientOptions -or $ConfidentialClientOptions)) {
            try { $Resolved = Resolve-MsalEnvironment @CloudParameters }
            catch { $PSCmdlet.ThrowTerminatingError((New-Object System.Management.Automation.ErrorRecord ($_.Exception, 'MsalEnvironmentResolution', [System.Management.Automation.ErrorCategory]::InvalidArgument, $null))) }
        }

        switch -Wildcard ($PSCmdlet.ParameterSetName) {
            "PublicClient*" {
                if ($PublicClientOptions) {
                    $ClientApplicationBuilder = [Microsoft.Identity.Client.PublicClientApplicationBuilder]::CreateWithApplicationOptions($PublicClientOptions)
                }
                else {
                    $ClientApplicationBuilder = [Microsoft.Identity.Client.PublicClientApplicationBuilder]::Create($ClientId)
                }

                if ($PSBoundParameters.ContainsKey('EnableExperimentalFeatures')) { [void] $ClientApplicationBuilder.WithExperimentalFeatures($EnableExperimentalFeatures) }  # Must be called before other experimental features
                if ($RedirectUri) { [void] $ClientApplicationBuilder.WithRedirectUri($RedirectUri.AbsoluteUri) }
                elseif (!$PublicClientOptions -or !$PublicClientOptions.RedirectUri) {
                    # MSAL's default on .NET Framework is the public cloud's nativeclient page: use the environment's host instead.
                    if ($PSVersionTable.PSEdition -eq 'Desktop' -and $Resolved -and $Resolved.Environment) { [void] $ClientApplicationBuilder.WithRedirectUri(('{0}/common/oauth2/nativeclient' -f $Resolved.Environment.AzureADEndpoint)) }
                    else { [void] $ClientApplicationBuilder.WithDefaultRedirectUri() }
                }
                if ($AuthenticationBroker) {
                    if (!$script:ModuleFeatureSupport.AuthBrokerSupport) {
                        Write-Error -Exception (New-Object System.PlatformNotSupportedException 'The authentication broker is only supported on Windows.') -Category ([System.Management.Automation.ErrorCategory]::NotImplemented) -ErrorId 'NewMsalClientApplicationBrokerNotSupported' -ErrorAction Stop
                    }
                    $BrokerOptions = New-Object Microsoft.Identity.Client.BrokerOptions ([Microsoft.Identity.Client.BrokerOptions+OperatingSystems]::Windows)
                    $ClientApplicationBuilder = [Microsoft.Identity.Client.Broker.BrokerExtension]::WithBroker($ClientApplicationBuilder, $BrokerOptions)
                }

                $ClientOptions = $PublicClientOptions
            }
            "ConfidentialClient*" {
                if ($ConfidentialClientOptions) {
                    $ClientApplicationBuilder = [Microsoft.Identity.Client.ConfidentialClientApplicationBuilder]::CreateWithApplicationOptions($ConfidentialClientOptions)
                }
                else {
                    $ClientApplicationBuilder = [Microsoft.Identity.Client.ConfidentialClientApplicationBuilder]::Create($ClientId)
                }

                if ($PSBoundParameters.ContainsKey('EnableExperimentalFeatures')) { [void] $ClientApplicationBuilder.WithExperimentalFeatures($EnableExperimentalFeatures) }  # Must be called before other experimental features
                if ($ClientSecret) { [void] $ClientApplicationBuilder.WithClientSecret((ConvertFrom-MsalSecureString $ClientSecret -Force)) }
                if ($ClientAssertion) { [void] $ClientApplicationBuilder.WithClientAssertion((Get-MsalClientAssertionCallback $ClientAssertion)) }
                # WithClientClaims is obsolete in MSAL 4.92 but still works; its replacement applies per request, not to the application, so it stays until MSAL removes it.
                if ($ClientClaims) { [void] $ClientApplicationBuilder.WithClientClaims($ClientCertificate, (ConvertTo-MsalDictionary $ClientClaims -KeyType ([string]) -ValueType ([string]))) }
                elseif ($ClientCertificate) { [void] $ClientApplicationBuilder.WithCertificate($ClientCertificate) }
                if ($RedirectUri) { [void] $ClientApplicationBuilder.WithRedirectUri($RedirectUri.AbsoluteUri) }

                $ClientOptions = $ConfidentialClientOptions
            }
            "*" {
                if ($ClientId) { [void] $ClientApplicationBuilder.WithClientId($ClientId) }
                if ($Resolved) {
                    if ($Resolved.DisableInstanceDiscovery) {
                        Write-Warning ('Instance discovery and authority validation are off for the {0} environment ({1}).' -f $Resolved.Environment.Name, $Resolved.Authority)
                        [void] $ClientApplicationBuilder.WithInstanceDiscovery($false)
                    }
                    [void] $ClientApplicationBuilder.WithAuthority([string] $Resolved.Authority, (-not $Resolved.DisableInstanceDiscovery))
                }
                if (!$ClientOptions -or !($ClientOptions.ClientName -or $ClientOptions.ClientVersion)) {
                    [void] $ClientApplicationBuilder.WithClientName("PowerShell $($PSVersionTable.PSEdition)")
                    [void] $ClientApplicationBuilder.WithClientVersion($PSVersionTable.PSVersion)
                }
                if ($ExtraQueryParameters) { [void] $ClientApplicationBuilder.WithExtraQueryParameters((ConvertTo-MsalExtraQueryParameter $ExtraQueryParameters)) }

                $ClientApplication = $ClientApplicationBuilder.Build()
                break
            }
        }

        return $ClientApplication
    }
}

