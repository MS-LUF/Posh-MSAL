[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '', Justification = 'Variables set in BeforeDiscovery / BeforeAll / BeforeEach are read by the It blocks.')]
param ()

BeforeDiscovery {
    $OnWindows = [System.Runtime.InteropServices.RuntimeInformation]::IsOSPlatform([System.Runtime.InteropServices.OSPlatform]::Windows)
}

BeforeAll {
    $ModuleRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
    Import-Module (Join-Path $ModuleRoot 'Posh-MSAL.psd1') -Force -ErrorAction Stop
    $Secret = New-Object System.Security.SecureString
    foreach ($Char in 'not-a-secret'.ToCharArray()) { $Secret.AppendChar($Char) }
    function Get-TestResult ([string[]] $Granted = @('https://graph.microsoft.com/.default')) {
        New-Object Microsoft.Identity.Client.AuthenticationResult ('token', $false, 'uid', [DateTimeOffset]::Now.AddHours(1), [DateTimeOffset]::Now.AddHours(1), 'tenant', $null, $null, $Granted, [guid]::NewGuid(), 'Bearer', $null, $null, $null, $null)
    }
}

AfterAll {
    Remove-Module Posh-MSAL -ErrorAction SilentlyContinue
}

Describe 'Get-MsalToken' {
    BeforeEach {
        Clear-MsalTokenCache
        $ClientId = [guid]::NewGuid().Guid
        $TenantId = [guid]::NewGuid().Guid
        $Result = Get-TestResult
        # Nothing reaches the network: the one call to MSAL's ExecuteAsync is replaced.
        Mock -ModuleName Posh-MSAL Invoke-MsalRequest { $Result }
    }

    Context 'confidential client' {
        It 'returns the result of a client credential request with the default scope of the cloud' {
            Get-MsalToken -ClientId $ClientId -ClientSecret $Secret -TenantId $TenantId -Environment BleuCloud | Should -Be $Result
            Should -Invoke -ModuleName Posh-MSAL Invoke-MsalRequest -Times 1 -Exactly -ParameterFilter { $Request -is [Microsoft.Identity.Client.AcquireTokenForClientParameterBuilder] }
        }

        It 'asks for the scopes given, or else the environment''s default' {
            Mock -ModuleName Posh-MSAL Get-MsalClientCredentialRequest { $Application.AcquireTokenForClient($Scopes) }
            [void] (Get-MsalToken -ClientId $ClientId -ClientSecret $Secret -TenantId $TenantId -Environment USGovDoD)
            [void] (Get-MsalToken -ClientId $ClientId -ClientSecret $Secret -TenantId $TenantId -Scopes 'api://contoso/.default')
            Should -Invoke -ModuleName Posh-MSAL Get-MsalClientCredentialRequest -Times 1 -Exactly -ParameterFilter { $Scopes -eq 'https://dod-graph.microsoft.us/.default' }
            Should -Invoke -ModuleName Posh-MSAL Get-MsalClientCredentialRequest -Times 1 -Exactly -ParameterFilter { $Scopes -eq 'api://contoso/.default' }
        }

        It 'builds <Type> for <Case>' -ForEach @(
            @{ Case = 'an authorization code'; Extra = @{ AuthorizationCode = 'code' }; Type = 'AcquireTokenByAuthorizationCodeParameterBuilder' }
            @{ Case = 'a user assertion'; Extra = @{ UserAssertion = 'eyJ0eXAiOiJKV1QifQ.e30.' }; Type = 'AcquireTokenOnBehalfOfParameterBuilder' }
        ) {
            [void] (Get-MsalToken -ClientId $ClientId -ClientSecret $Secret -TenantId $TenantId @Extra)
            Should -Invoke -ModuleName Posh-MSAL Invoke-MsalRequest -Times 1 -Exactly -ParameterFilter { $Request.GetType().Name -eq $Type }
        }

        It 'changes the tenant per request only on an application passed in' {
            Mock -ModuleName Posh-MSAL Add-MsalRequestOption { $Request }
            $App = New-MsalClientApplication -ClientId $ClientId -ClientSecret $Secret -TenantId $TenantId
            $Other = [guid]::NewGuid().Guid
            [void] ($App | Get-MsalToken -TenantId $Other)
            [void] (Get-MsalToken -ClientId $ClientId -ClientSecret $Secret -TenantId $TenantId)
            Should -Invoke -ModuleName Posh-MSAL Add-MsalRequestOption -Times 1 -Exactly -ParameterFilter { $PesterBoundParameters['TenantId'] -eq $Other }
            Should -Invoke -ModuleName Posh-MSAL Add-MsalRequestOption -Times 1 -Exactly -ParameterFilter { -not $PesterBoundParameters.ContainsKey('TenantId') }
        }

        It 'passes -CorrelationId and -ExtraQueryParameters on' {
            Mock -ModuleName Posh-MSAL Add-MsalRequestOption { $Request }
            $Correlation = [guid]::NewGuid()
            [void] (Get-MsalToken -ClientId $ClientId -ClientSecret $Secret -TenantId $TenantId -CorrelationId $Correlation -ExtraQueryParameters @{ slice = 'test' })
            Should -Invoke -ModuleName Posh-MSAL Add-MsalRequestOption -Times 1 -Exactly -ParameterFilter { $CorrelationId -eq $Correlation -and $ExtraQueryParameters.slice -eq 'test' }
        }

        It 'processes every application piped in' {
            $Apps = 1..3 | ForEach-Object { New-MsalClientApplication -ClientId ([guid]::NewGuid().Guid) -ClientSecret $Secret -TenantId $TenantId }
            @($Apps | Get-MsalToken) | Should -HaveCount 3
            Should -Invoke -ModuleName Posh-MSAL Invoke-MsalRequest -Times 3 -Exactly
        }
    }

    Context 'errors' {
        It 'reports <Exception> as <ErrorId>' -ForEach @(
            @{ Exception = 'MsalServiceException'; Make = { New-Object Microsoft.Identity.Client.MsalServiceException ('invalid_client', 'AADSTS7000215') }; ErrorId = 'GetMsalTokenFailureAuthenticationError' }
            @{ Exception = 'TimeoutException'; Make = { New-Object System.TimeoutException 'too slow' }; ErrorId = 'GetMsalTokenFailureOperationTimeout' }
            @{ Exception = 'TaskCanceledException'; Make = { New-Object System.Threading.Tasks.TaskCanceledException 'stopped' }; ErrorId = 'GetMsalTokenFailureOperationStopped' }
        ) {
            $Thrown = & $Make
            Mock -ModuleName Posh-MSAL Invoke-MsalRequest { throw $Thrown }
            $Caught = $null
            try { Get-MsalToken -ClientId $ClientId -ClientSecret $Secret -TenantId $TenantId } catch { $Caught = $_ }
            $Caught.FullyQualifiedErrorId | Should -Be ('{0},Get-MsalToken' -f $ErrorId)
            [object]::ReferenceEquals($Caught.Exception, $Thrown) | Should -BeTrue
        }
    }

    Context 'public client' {
        It 'builds <Type> for <Case>' -ForEach @(
            @{ Case = '-DeviceCode'; Extra = @{ DeviceCode = $true }; Type = 'AcquireTokenWithDeviceCodeParameterBuilder' }
            @{ Case = '-Silent'; Extra = @{ Silent = $true }; Type = 'AcquireTokenSilentParameterBuilder' }
            @{ Case = '-IntegratedWindowsAuth'; Extra = @{ IntegratedWindowsAuth = $true }; Type = 'AcquireTokenByIntegratedWindowsAuthParameterBuilder' }
        ) {
            [void] (Get-MsalToken -ClientId $ClientId -TenantId $TenantId @Extra -WarningAction SilentlyContinue)
            Should -Invoke -ModuleName Posh-MSAL Invoke-MsalRequest -Times 1 -Exactly -ParameterFilter { $Request.GetType().Name -eq $Type }
        }

        It 'hands the device-code queue to the request' {
            [void] (Get-MsalToken -ClientId $ClientId -TenantId $TenantId -DeviceCode)
            Should -Invoke -ModuleName Posh-MSAL Invoke-MsalRequest -Times 1 -Exactly -ParameterFilter { $DeviceCodeQueue -is [System.Collections.Concurrent.ConcurrentQueue[string]] }
        }

        It 'warns for the deprecated username/password flow' {
            $Credential = New-Object System.Management.Automation.PSCredential ('user@contoso.com', $Secret)
            [void] (Get-MsalToken -ClientId $ClientId -TenantId $TenantId -UserCredential $Credential -WarningVariable Warnings -WarningAction SilentlyContinue)
            "$Warnings" | Should -BeLike '*ROPC*deprecated*'
            Should -Invoke -ModuleName Posh-MSAL Invoke-MsalRequest -Times 1 -Exactly -ParameterFilter { $Request -is [Microsoft.Identity.Client.AcquireTokenByUsernamePasswordParameterBuilder] }
        }

        It 'default flow: returns the cached token when it has every scope' {
            [void] (Get-MsalToken -ClientId $ClientId -TenantId $TenantId)
            Should -Invoke -ModuleName Posh-MSAL Invoke-MsalRequest -Times 1 -Exactly
            Should -Invoke -ModuleName Posh-MSAL Invoke-MsalRequest -Times 1 -Exactly -ParameterFilter { $Request -is [Microsoft.Identity.Client.AcquireTokenSilentParameterBuilder] }
        }

        It 'default flow: falls back to integrated Windows authentication, then interactive, without warning' -Skip:(-not $OnWindows) {
            Mock -ModuleName Posh-MSAL Invoke-MsalRequest {
                if ($Request -is [Microsoft.Identity.Client.AcquireTokenSilentParameterBuilder]) { throw (New-Object Microsoft.Identity.Client.MsalUiRequiredException ('no_account', 'sign-in needed')) }
                if ($Request -is [Microsoft.Identity.Client.AcquireTokenByIntegratedWindowsAuthParameterBuilder]) { throw (New-Object Microsoft.Identity.Client.MsalClientException ('unknown_user', 'not on a domain')) }
                $Result
            }
            # -WarningVariable would also record the silenced warning: read the warning stream itself.
            $Output = Get-MsalToken -ClientId $ClientId -TenantId $TenantId 3>&1
            @($Output | Where-Object { $_ -is [System.Management.Automation.WarningRecord] }) | Should -HaveCount 0
            @($Output | Where-Object { $_ -is [Microsoft.Identity.Client.AuthenticationResult] }) | Should -Be @($Result)
            Should -Invoke -ModuleName Posh-MSAL Invoke-MsalRequest -Times 3 -Exactly
            Should -Invoke -ModuleName Posh-MSAL Invoke-MsalRequest -Times 1 -Exactly -ParameterFilter { $Request -is [Microsoft.Identity.Client.AcquireTokenInteractiveParameterBuilder] }
        }

        It 'default flow: goes interactive when the cached token lacks a scope' -Skip:(-not $OnWindows) {
            $Partial = Get-TestResult @('User.Read')
            Mock -ModuleName Posh-MSAL Invoke-MsalRequest { if ($Request -is [Microsoft.Identity.Client.AcquireTokenSilentParameterBuilder]) { $Partial } else { $Result } }
            Get-MsalToken -ClientId $ClientId -TenantId $TenantId -Scopes 'User.Read', 'Mail.Read' | Should -Be $Result
            Should -Invoke -ModuleName Posh-MSAL Invoke-MsalRequest -Times 1 -Exactly -ParameterFilter { $Request -is [Microsoft.Identity.Client.AcquireTokenInteractiveParameterBuilder] }
        }

        It 'interactive: waits two minutes at most for the system browser on PowerShell 7' -Skip:(-not $OnWindows -or $PSVersionTable.PSEdition -ne 'Core') {
            [void] (Get-MsalToken -ClientId $ClientId -TenantId $TenantId -Interactive)
            Should -Invoke -ModuleName Posh-MSAL Invoke-MsalRequest -Times 1 -Exactly -ParameterFilter { $Request -is [Microsoft.Identity.Client.AcquireTokenInteractiveParameterBuilder] -and $Timeout -eq [timespan]::FromMinutes(2) }
        }

        It 'interactive: keeps -Timeout when given' -Skip:(-not $OnWindows) {
            [void] (Get-MsalToken -ClientId $ClientId -TenantId $TenantId -Interactive -UseEmbeddedWebView:($PSVersionTable.PSEdition -eq 'Desktop') -Timeout ([timespan]::FromSeconds(30)))
            Should -Invoke -ModuleName Posh-MSAL Invoke-MsalRequest -Times 1 -Exactly -ParameterFilter { $Timeout -eq [timespan]::FromSeconds(30) }
        }
    }
}
