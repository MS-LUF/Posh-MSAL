<#
.SYNOPSIS
    Gets an OAuth token from Microsoft Entra ID, in the public cloud or a sovereign cloud.
.DESCRIPTION
    Gets a token through MSAL.NET for a public client (a user signs in) or a confidential client (the
    application signs in with a secret, a certificate or an assertion). Unless an application is
    piped in, the cmdlet uses the session's application for these settings, as
    Select-MsalClientApplication does, so the tokens it caches are reused by later calls.

    The flow follows the parameters. A confidential client uses the client credentials, or the
    authorization code with AuthorizationCode, or on-behalf-of with UserAssertion. A public client
    signs in with UserCredential (username and password), DeviceCode, Interactive,
    IntegratedWindowsAuth or Silent; with none of them, it tries the token cache, then integrated
    Windows authentication, then an interactive sign-in. Integrated Windows authentication and
    username and password are deprecated by MSAL.NET and warn when asked for.

    The cloud comes from Environment, AzureCloudInstance or Authority (the public cloud by default);
    parameters that point at different clouds are an error. Without Scopes, the scope is the Graph
    endpoint of the cloud followed by /.default. On an application piped in, only the tenant can
    change per request.

    Interactive sign-in uses MSAL's embedded window on Windows PowerShell 5.1 and the system browser
    on PowerShell 7, which needs an http://localhost redirect URI on the app registration; without
    one, PowerShell 7 falls back to device code. With the system browser, the cmdlet gives up after
    2 minutes unless Timeout says otherwise. Device code messages go to the information stream.

    A failure is a terminating error: GetMsalTokenFailureAuthenticationError (the MSAL.NET exception
    is in the error record), GetMsalTokenFailureOperationTimeout or GetMsalTokenFailureOperationStopped.
.EXAMPLE
    Get-MsalToken -ClientId '00000000-0000-0000-0000-000000000000' -TenantId 'contoso.onmicrosoft.com' -ClientSecret (Read-Host -AsSecureString -Prompt 'Client secret')
    Gets an application token for Microsoft Graph in the public cloud, with a client secret.
.EXAMPLE
    Get-MsalToken -ClientId '00000000-0000-0000-0000-000000000000' -TenantId 'contoso.onmicrosoft.com' -ClientCertificate (Get-Item 'Cert:\CurrentUser\My\0000000000000000000000000000000000000000') -Environment 'BleuCloud'
    Gets an application token in Bleu with a certificate; the scope is the Bleu Graph default.
.EXAMPLE
    Get-MsalToken -ClientId '00000000-0000-0000-0000-000000000000' -TenantId 'contoso.onmicrosoft.com' -Interactive -Scopes 'https://graph.microsoft.com/User.Read' -LoginHint 'user@contoso.com'
    Signs a user in interactively, with the user name filled in.
.EXAMPLE
    Get-MsalToken -ClientId '00000000-0000-0000-0000-000000000000' -TenantId 'contoso.onmicrosoft.com' -Silent -Scopes 'https://graph.microsoft.com/User.Read'
    Gets a user token from the token cache, refreshing it when needed, without any sign-in.
.EXAMPLE
    Get-MsalToken -ClientId '00000000-0000-0000-0000-000000000000' -TenantId 'contoso.onmicrosoft.com' -DeviceCode
    Signs a user in on another device, for a machine with no browser.
.EXAMPLE
    Get-MsalClientApplication -ClientId '00000000-0000-0000-0000-000000000000' | Get-MsalToken -TenantId 'fabrikam.onmicrosoft.com'
    Uses the session's application with this client id for another tenant of the same cloud.
.INPUTS
    Microsoft.Identity.Client.IPublicClientApplication, Microsoft.Identity.Client.IConfidentialClientApplication, System.String
.OUTPUTS
    Microsoft.Identity.Client.AuthenticationResult
.LINK
    Select-MsalClientApplication
.LINK
    Get-MsalEnvironment
.LINK
    Enable-MsalTokenCacheOnDisk
#>
function Get-MsalToken {
    [CmdletBinding(DefaultParameterSetName = 'PublicClient')]
    [OutputType([Microsoft.Identity.Client.AuthenticationResult])]
    param
    (
        # Identifier of the client requesting the token.
        [Parameter(Mandatory = $true, ParameterSetName = 'PublicClient', Position = 0, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [Parameter(Mandatory = $true, ParameterSetName = 'PublicClient-Interactive', Position = 0, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [Parameter(Mandatory = $true, ParameterSetName = 'PublicClient-IntegratedWindowsAuth', Position = 0, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [Parameter(Mandatory = $true, ParameterSetName = 'PublicClient-Silent', Position = 0, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [Parameter(Mandatory = $true, ParameterSetName = 'PublicClient-UsernamePassword', Position = 0, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [Parameter(Mandatory = $true, ParameterSetName = 'PublicClient-DeviceCode', Position = 0, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [Parameter(Mandatory = $true, ParameterSetName = 'ConfidentialClientSecret', Position = 0, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [Parameter(Mandatory = $true, ParameterSetName = 'ConfidentialClientSecret-AuthorizationCode', Position = 0, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [Parameter(Mandatory = $true, ParameterSetName = 'ConfidentialClientSecret-OnBehalfOf', Position = 0, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [Parameter(Mandatory = $true, ParameterSetName = 'ConfidentialClientCertificate', Position = 0, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [Parameter(Mandatory = $true, ParameterSetName = 'ConfidentialClientCertificate-AuthorizationCode', Position = 0, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [Parameter(Mandatory = $true, ParameterSetName = 'ConfidentialClientCertificate-OnBehalfOf', Position = 0, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [string] $ClientId,

        # Secure secret of the client requesting the token.
        [Parameter(Mandatory = $true, ParameterSetName = 'ConfidentialClientSecret', ValueFromPipelineByPropertyName = $true)]
        [Parameter(Mandatory = $true, ParameterSetName = 'ConfidentialClientSecret-AuthorizationCode', ValueFromPipelineByPropertyName = $true)]
        [Parameter(Mandatory = $true, ParameterSetName = 'ConfidentialClientSecret-OnBehalfOf', ValueFromPipelineByPropertyName = $true)]
        [securestring] $ClientSecret,

        # Client assertion certificate of the client requesting the token.
        [Parameter(Mandatory = $true, ParameterSetName = 'ConfidentialClientCertificate', ValueFromPipelineByPropertyName = $true)]
        [Parameter(Mandatory = $true, ParameterSetName = 'ConfidentialClientCertificate-AuthorizationCode', ValueFromPipelineByPropertyName = $true)]
        [Parameter(Mandatory = $true, ParameterSetName = 'ConfidentialClientCertificate-OnBehalfOf', ValueFromPipelineByPropertyName = $true)]
        [System.Security.Cryptography.X509Certificates.X509Certificate2] $ClientCertificate,

        # Specifies if the x5c claim (public key of the certificate) should be sent to the STS.
        [Parameter(Mandatory = $false, ParameterSetName = 'ConfidentialClient-InputObject')]
        [Parameter(Mandatory = $false, ParameterSetName = 'ConfidentialClientCertificate')]
        [Parameter(Mandatory = $false, ParameterSetName = 'ConfidentialClientCertificate-AuthorizationCode')]
        [Parameter(Mandatory = $false, ParameterSetName = 'ConfidentialClientCertificate-OnBehalfOf')]
        [switch] $SendX5C,

        # The authorization code received from service authorization endpoint.
        [Parameter(Mandatory = $false, ParameterSetName = 'ConfidentialClient-InputObject')]
        [Parameter(Mandatory = $true, ParameterSetName = 'ConfidentialClientSecret-AuthorizationCode')]
        [Parameter(Mandatory = $true, ParameterSetName = 'ConfidentialClientCertificate-AuthorizationCode')]
        [string] $AuthorizationCode,

        # Assertion representing the user.
        [Parameter(Mandatory = $false, ParameterSetName = 'ConfidentialClient-InputObject', ValueFromPipelineByPropertyName = $true)]
        [Parameter(Mandatory = $true, ParameterSetName = 'ConfidentialClientSecret-OnBehalfOf', ValueFromPipelineByPropertyName = $true)]
        [Parameter(Mandatory = $true, ParameterSetName = 'ConfidentialClientCertificate-OnBehalfOf', ValueFromPipelineByPropertyName = $true)]
        [string] $UserAssertion,

        # Type of the assertion representing the user.
        [Parameter(Mandatory = $false, ParameterSetName = 'ConfidentialClient-InputObject', ValueFromPipelineByPropertyName = $true)]
        [Parameter(Mandatory = $false, ParameterSetName = 'ConfidentialClientSecret-OnBehalfOf', ValueFromPipelineByPropertyName = $true)]
        [Parameter(Mandatory = $false, ParameterSetName = 'ConfidentialClientCertificate-OnBehalfOf', ValueFromPipelineByPropertyName = $true)]
        [string] $UserAssertionType,

        # Address to return to upon receiving a response from the authority.
        [Parameter(Mandatory = $false, ParameterSetName = 'PublicClient', ValueFromPipelineByPropertyName = $true)]
        [Parameter(Mandatory = $false, ParameterSetName = 'PublicClient-Interactive', ValueFromPipelineByPropertyName = $true)]
        [Parameter(Mandatory = $false, ParameterSetName = 'PublicClient-IntegratedWindowsAuth', ValueFromPipelineByPropertyName = $true)]
        [Parameter(Mandatory = $false, ParameterSetName = 'PublicClient-Silent', ValueFromPipelineByPropertyName = $true)]
        [Parameter(Mandatory = $false, ParameterSetName = 'PublicClient-UsernamePassword', ValueFromPipelineByPropertyName = $true)]
        [Parameter(Mandatory = $false, ParameterSetName = 'PublicClient-DeviceCode', ValueFromPipelineByPropertyName = $true)]
        [Parameter(Mandatory = $false, ParameterSetName = 'ConfidentialClientSecret', ValueFromPipelineByPropertyName = $true)]
        [Parameter(Mandatory = $false, ParameterSetName = 'ConfidentialClientSecret-AuthorizationCode', ValueFromPipelineByPropertyName = $true)]
        [Parameter(Mandatory = $false, ParameterSetName = 'ConfidentialClientSecret-OnBehalfOf', ValueFromPipelineByPropertyName = $true)]
        [Parameter(Mandatory = $false, ParameterSetName = 'ConfidentialClientCertificate', ValueFromPipelineByPropertyName = $true)]
        [Parameter(Mandatory = $false, ParameterSetName = 'ConfidentialClientCertificate-AuthorizationCode', ValueFromPipelineByPropertyName = $true)]
        [Parameter(Mandatory = $false, ParameterSetName = 'ConfidentialClientCertificate-OnBehalfOf', ValueFromPipelineByPropertyName = $true)]
        [uri] $RedirectUri,

        # Cloud to sign in to, as an MSAL.NET AzureCloudInstance value; -Environment covers more clouds. AzureGermany is refused (closed in 2021).
        [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)]
        [Microsoft.Identity.Client.AzureCloudInstance] $AzureCloudInstance,

        # Cloud to sign in to: a built-in or user-defined environment (Get-MsalEnvironment). Gives the authority and the default scope.
        [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)]
        [ArgumentCompleter( { $Word = $args[2]; (Get-MsalEnvironment).Name | Where-Object { $_ -like "$Word*" } })]
        [string] $Environment,

        # Tenant identifier of the authority to issue token. It can also contain the value "consumers" or "organizations".
        [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)]
        [string] $TenantId,

        # Address of the authority to issue token.
        [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)]
        [uri] $Authority,

        # Sign in through the Windows authentication broker (WAM); Windows only.
        [Parameter(Mandatory = $false, ParameterSetName = 'PublicClient', ValueFromPipelineByPropertyName = $true)]
        [Parameter(Mandatory = $false, ParameterSetName = 'PublicClient-Interactive', ValueFromPipelineByPropertyName = $true)]
        [Parameter(Mandatory = $false, ParameterSetName = 'PublicClient-InputObject', ValueFromPipelineByPropertyName = $true)]
        [switch] $AuthenticationBroker,

        # Public client application to use, from New-MsalClientApplication or Select-MsalClientApplication.
        [Parameter(Mandatory = $true, ParameterSetName = 'PublicClient-InputObject', Position = 0, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [Microsoft.Identity.Client.IPublicClientApplication] $PublicClientApplication,

        # Confidential client application to use, from New-MsalClientApplication or Select-MsalClientApplication.
        [Parameter(Mandatory = $true, ParameterSetName = 'ConfidentialClient-InputObject', Position = 0, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [Microsoft.Identity.Client.IConfidentialClientApplication] $ConfidentialClientApplication,

        # Interactive request to acquire a token for the specified scopes.
        [Parameter(Mandatory = $true, ParameterSetName = 'PublicClient-Interactive')]
        [Parameter(Mandatory = $false, ParameterSetName = 'PublicClient-InputObject')]
        [switch] $Interactive,

        # Non-interactive request to acquire a security token for the signed-in user in Windows, via Integrated Windows Authentication.
        [Parameter(Mandatory = $true, ParameterSetName = 'PublicClient-IntegratedWindowsAuth')]
        [Parameter(Mandatory = $false, ParameterSetName = 'PublicClient-InputObject')]
        [switch] $IntegratedWindowsAuth,

        # Attempts to acquire an access token from the user token cache.
        [Parameter(Mandatory = $true, ParameterSetName = 'PublicClient-Silent')]
        [Parameter(Mandatory = $false, ParameterSetName = 'PublicClient-InputObject')]
        [switch] $Silent,

        # Acquires a security token on a device without a Web browser, by letting the user authenticate on another device.
        [Parameter(Mandatory = $true, ParameterSetName = 'PublicClient-DeviceCode')]
        [Parameter(Mandatory = $false, ParameterSetName = 'PublicClient-Interactive')]
        [Parameter(Mandatory = $false, ParameterSetName = 'PublicClient-InputObject')]
        [switch] $DeviceCode,

        # Array of scopes requested for resource. Default: https://<GraphEndpoint>/.default of the environment.
        [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)]
        [string[]] $Scopes,

        # Array of scopes for which a developer can request consent upfront.
        [Parameter(Mandatory = $false, ParameterSetName = 'PublicClient', ValueFromPipelineByPropertyName = $true)]
        [Parameter(Mandatory = $false, ParameterSetName = 'PublicClient-Interactive', ValueFromPipelineByPropertyName = $true)]
        [Parameter(Mandatory = $false, ParameterSetName = 'PublicClient-InputObject', ValueFromPipelineByPropertyName = $true)]
        [string[]] $ExtraScopesToConsent,

        # Identifier of the user. Generally a UPN.
        [Parameter(Mandatory = $false, ParameterSetName = 'PublicClient', ValueFromPipelineByPropertyName = $true)]
        [Parameter(Mandatory = $false, ParameterSetName = 'PublicClient-Interactive', ValueFromPipelineByPropertyName = $true)]
        [Parameter(Mandatory = $false, ParameterSetName = 'PublicClient-IntegratedWindowsAuth', ValueFromPipelineByPropertyName = $true)]
        [Parameter(Mandatory = $false, ParameterSetName = 'PublicClient-Silent', ValueFromPipelineByPropertyName = $true)]
        [Parameter(Mandatory = $false, ParameterSetName = 'PublicClient-InputObject', ValueFromPipelineByPropertyName = $true)]
        [string] $LoginHint,

        # Specifies the what the interactive experience is for the user. To force an interactive authentication, use the -Interactive switch.
        [Parameter(Mandatory = $false, ParameterSetName = 'PublicClient', ValueFromPipelineByPropertyName = $true)]
        [Parameter(Mandatory = $false, ParameterSetName = 'PublicClient-Interactive', ValueFromPipelineByPropertyName = $true)]
        [Parameter(Mandatory = $false, ParameterSetName = 'PublicClient-InputObject', ValueFromPipelineByPropertyName = $true)]
        [ArgumentCompleter( {
                $wordToComplete = $args[2]
                [Microsoft.Identity.Client.Prompt].DeclaredFields | Where-Object { $_.IsPublic -eq $true -and $_.IsStatic -eq $true -and $_.Name -like "$wordToComplete*" } | Select-Object -ExpandProperty Name
            })]
        [string] $Prompt,

        # Identifier of the user with associated password.
        [Parameter(Mandatory = $true, ParameterSetName = 'PublicClient-UsernamePassword', ValueFromPipelineByPropertyName = $true)]
        [Parameter(Mandatory = $false, ParameterSetName = 'PublicClient-InputObject', ValueFromPipelineByPropertyName = $true)]
        [pscredential]
        [System.Management.Automation.Credential()]
        $UserCredential,

        # Correlation id to be used in the authentication request.
        [Parameter(Mandatory = $false)]
        [guid] $CorrelationId,

        # This parameter will be appended as is to the query string in the HTTP authentication request to the authority.
        [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)]
        [hashtable] $ExtraQueryParameters,

        # Ignore any access token in the user token cache and attempt to acquire new access token using the refresh token for the account if one is available.
        [Parameter(Mandatory = $false, ParameterSetName = 'PublicClient')]
        [Parameter(Mandatory = $false, ParameterSetName = 'PublicClient-Silent')]
        [Parameter(Mandatory = $false, ParameterSetName = 'PublicClient-InputObject')]
        [Parameter(Mandatory = $false, ParameterSetName = 'ConfidentialClientSecret')]
        [Parameter(Mandatory = $false, ParameterSetName = 'ConfidentialClientCertificate')]
        [Parameter(Mandatory = $false, ParameterSetName = 'ConfidentialClient-InputObject')]
        [switch] $ForceRefresh,

        # Specifies if the public client application should used an embedded web browser or the system default browser
        [Parameter(Mandatory = $false, ParameterSetName = 'PublicClient', ValueFromPipelineByPropertyName = $true)]
        [Parameter(Mandatory = $false, ParameterSetName = 'PublicClient-Interactive', ValueFromPipelineByPropertyName = $true)]
        [Parameter(Mandatory = $false, ParameterSetName = 'PublicClient-InputObject', ValueFromPipelineByPropertyName = $true)]
        [switch] $UseEmbeddedWebView,

        # Specifies the timeout threshold for MSAL.net operations.
        [Parameter(Mandatory = $false)]
        [timespan] $Timeout
    )


    process {
        ## The application: passed in, or the session's one for these settings (built when missing).
        switch -Wildcard ($PSCmdlet.ParameterSetName) {
            "PublicClient-InputObject" {
                [Microsoft.Identity.Client.IPublicClientApplication] $ClientApplication = $PublicClientApplication
                break
            }
            "ConfidentialClient-InputObject" {
                [Microsoft.Identity.Client.IConfidentialClientApplication] $ClientApplication = $ConfidentialClientApplication
                break
            }
            "PublicClient*" {
                $paramSelectMsalClientApplication = Select-MsalBoundParameter $PSBoundParameters -CommandName Select-MsalClientApplication -CommandParameterSets "PublicClient"
                [Microsoft.Identity.Client.IPublicClientApplication] $ClientApplication = Select-MsalClientApplication @paramSelectMsalClientApplication
                break
            }
            "ConfidentialClientSecret*" {
                $paramSelectMsalClientApplication = Select-MsalBoundParameter $PSBoundParameters -CommandName Select-MsalClientApplication -CommandParameterSets "ConfidentialClientSecret"
                [Microsoft.Identity.Client.IConfidentialClientApplication] $ClientApplication = Select-MsalClientApplication @paramSelectMsalClientApplication
                break
            }
            "ConfidentialClientCertificate*" {
                $paramSelectMsalClientApplication = Select-MsalBoundParameter $PSBoundParameters -CommandName Select-MsalClientApplication -CommandParameterSets "ConfidentialClientCertificate"
                [Microsoft.Identity.Client.IConfidentialClientApplication] $ClientApplication = Select-MsalClientApplication @paramSelectMsalClientApplication
                break
            }
        }

        ## Cloud of the request, checked against the application's; the default scope comes from it.
        $CloudParameters = @{}
        foreach ($Key in 'Environment', 'AzureCloudInstance', 'Authority', 'TenantId') { if ($PSBoundParameters.ContainsKey($Key)) { $CloudParameters[$Key] = $PSBoundParameters[$Key] } }
        # A piped application binds its own Authority property to -Authority: that one asks for nothing.
        $ApplicationAuthority = $ClientApplication.AppConfig.Authority.AuthorityInfo.CanonicalAuthority
        if ($CloudParameters.ContainsKey('Authority') -and $PSCmdlet.ParameterSetName -like '*-InputObject' -and ([uri] $CloudParameters['Authority']).AbsoluteUri.TrimEnd('/') -eq $ApplicationAuthority.AbsoluteUri.TrimEnd('/')) {
            $CloudParameters.Remove('Authority')
        }
        try { $Resolved = Resolve-MsalEnvironment @CloudParameters -ApplicationAuthority $ApplicationAuthority }
        catch { $PSCmdlet.ThrowTerminatingError((New-Object System.Management.Automation.ErrorRecord ($_.Exception, 'MsalEnvironmentResolution', [System.Management.Automation.ErrorCategory]::InvalidArgument, $null))) }
        if (-not $PSBoundParameters.ContainsKey('Scopes')) {
            if (-not $Resolved.DefaultScope) {
                $Message = 'No environment has the authority host {0}, so there is no default scope: give -Scopes, or add the cloud with Add-MsalEnvironment.' -f $ClientApplication.AppConfig.Authority.AuthorityInfo.Host
                $PSCmdlet.ThrowTerminatingError((New-Object System.Management.Automation.ErrorRecord ((New-Object System.ArgumentException $Message), 'MsalNoDefaultScope', [System.Management.Automation.ErrorCategory]::InvalidArgument, $null)))
            }
            $Scopes = $Resolved.DefaultScope
        }

        $Flow = Resolve-MsalTokenFlow $PSCmdlet.ParameterSetName $PSBoundParameters $ClientApplication
        Write-Debug ('Acquiring a token for application [{0}] with the {1} flow' -f $ClientApplication.AppConfig.ClientId, $Flow)

        if ($Flow -eq 'Default') {
            ## The token cache first, then integrated Windows authentication, then interactive.
            $paramGetMsalToken = Select-MsalBoundParameter -NamedParameter $PSBoundParameters -CommandName 'Get-MsalToken' -CommandParameterSet 'PublicClient-InputObject' -ExcludeParameters 'PublicClientApplication'
            Write-Verbose ('Attempting Silent Authentication to Application with ClientId [{0}]' -f $ClientApplication.AppConfig.ClientId)
            try {
                $AuthenticationResult = Get-MsalToken -Silent -PublicClientApplication $ClientApplication @paramGetMsalToken
                if (Test-MsalMissingScope $AuthenticationResult $Scopes) {
                    $AuthenticationResult = Get-MsalToken -Interactive -PublicClientApplication $ClientApplication @paramGetMsalToken
                }
            }
            catch [Microsoft.Identity.Client.MsalUiRequiredException] {
                Write-Debug ('{0}: {1}' -f $_.Exception.GetType().Name, $_.Exception.Message)
                Write-Verbose ('Attempting Integrated Windows Authentication to Application with ClientId [{0}]' -f $ClientApplication.AppConfig.ClientId)
                try {
                    # An attempt the caller did not ask for: no deprecation warning for it.
                    $AuthenticationResult = Get-MsalToken -IntegratedWindowsAuth -PublicClientApplication $ClientApplication -WarningAction SilentlyContinue @paramGetMsalToken
                    if (Test-MsalMissingScope $AuthenticationResult $Scopes) {
                        $AuthenticationResult = Get-MsalToken -Interactive -PublicClientApplication $ClientApplication @paramGetMsalToken
                    }
                }
                catch {
                    Write-Debug ('{0}: {1}' -f $_.Exception.GetType().Name, $_.Exception.Message)
                    Write-Verbose ('Attempting Interactive Authentication to Application with ClientId [{0}]' -f $ClientApplication.AppConfig.ClientId)
                    $AuthenticationResult = Get-MsalToken -Interactive -PublicClientApplication $ClientApplication @paramGetMsalToken
                }
            }
            return $AuthenticationResult
        }

        ## One request builder per flow.
        $ForceRefreshValue = $null
        if ($PSBoundParameters.ContainsKey('ForceRefresh')) { $ForceRefreshValue = [bool] $ForceRefresh }
        $DeviceCodeCallback = $null
        # -WarningAction does not reach the module's private functions on its own: pass it on.
        $WarningParameters = @{}
        if ($PSBoundParameters.ContainsKey('WarningAction')) { $WarningParameters['WarningAction'] = $PSBoundParameters['WarningAction'] }
        switch ($Flow) {
            'UsernamePassword' { $Request = Get-MsalUsernamePasswordRequest $ClientApplication -Scopes $Scopes -Credential $UserCredential @WarningParameters }
            'DeviceCode' {
                $DeviceCodeCallback = Get-MsalDeviceCodeCallback
                $Request = Get-MsalDeviceCodeRequest $ClientApplication -Scopes $Scopes -Callback $DeviceCodeCallback.Callback
            }
            'Interactive' {
                $EmbeddedWebView = $null
                if ($PSBoundParameters.ContainsKey('UseEmbeddedWebView')) { $EmbeddedWebView = [bool] $UseEmbeddedWebView }
                $Request = Get-MsalInteractiveRequest $ClientApplication -Scopes $Scopes -ExtraScopesToConsent $ExtraScopesToConsent -LoginHint $LoginHint -Prompt $Prompt -UseEmbeddedWebView $EmbeddedWebView
                # The system browser cannot tell when the person gives up: do not wait forever.
                if (!$Timeout -and ($EmbeddedWebView -eq $false -or $PSVersionTable.PSEdition -eq 'Core')) { $Timeout = New-TimeSpan -Minutes 2 }
            }
            'IntegratedWindowsAuth' { $Request = Get-MsalIntegratedWindowsAuthRequest $ClientApplication -Scopes $Scopes -LoginHint $LoginHint @WarningParameters }
            'Silent' { $Request = Get-MsalSilentRequest $ClientApplication -Scopes $Scopes -LoginHint $LoginHint -ForceRefresh $ForceRefreshValue }
            'ClientCredential' { $Request = Get-MsalClientCredentialRequest $ClientApplication -Scopes $Scopes -ForceRefresh $ForceRefreshValue -SendX5C:$SendX5C }
            'OnBehalfOf' { $Request = Get-MsalOnBehalfOfRequest $ClientApplication -Scopes $Scopes -UserAssertion $UserAssertion -UserAssertionType $UserAssertionType -SendX5C:$SendX5C }
            'AuthorizationCode' { $Request = Get-MsalAuthorizationCodeRequest $ClientApplication -Scopes $Scopes -AuthorizationCode $AuthorizationCode -SendX5C:$SendX5C }
        }

        $Options = @{}
        # Only the tenant can change per request; an application built here already has it.
        if ($Resolved.TenantId -and $PSCmdlet.ParameterSetName -like '*-InputObject') { $Options['TenantId'] = $Resolved.TenantId }
        if ($PSBoundParameters.ContainsKey('CorrelationId')) { $Options['CorrelationId'] = $CorrelationId }
        if ($ExtraQueryParameters) { $Options['ExtraQueryParameters'] = $ExtraQueryParameters }
        [void] (Add-MsalRequestOption $Request @Options)

        if (!$Timeout) { $Timeout = [timespan]::Zero }
        $Queue = $null
        if ($DeviceCodeCallback) { $Queue = $DeviceCodeCallback.Queue }
        try {
            return (Invoke-MsalRequest $Request -Timeout $Timeout -DeviceCodeQueue $Queue)
        }
        catch {
            $Exception = $_.Exception
            if ($Exception -is [System.TimeoutException]) { $ErrorId = 'GetMsalTokenFailureOperationTimeout'; $Category = [System.Management.Automation.ErrorCategory]::OperationTimeout }
            elseif ($Exception -is [System.Threading.Tasks.TaskCanceledException]) { $ErrorId = 'GetMsalTokenFailureOperationStopped'; $Category = [System.Management.Automation.ErrorCategory]::OperationStopped }
            else { $ErrorId = 'GetMsalTokenFailureAuthenticationError'; $Category = [System.Management.Automation.ErrorCategory]::AuthenticationError }
            $PSCmdlet.ThrowTerminatingError((New-Object System.Management.Automation.ErrorRecord ($Exception, $ErrorId, $Category, $Request)))
        }
    }
}
