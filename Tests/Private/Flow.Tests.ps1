[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '', Justification = 'Variables set in BeforeDiscovery / BeforeAll are read by the It blocks.')]
param ()

BeforeDiscovery {
    $OnWindows = [System.Runtime.InteropServices.RuntimeInformation]::IsOSPlatform([System.Runtime.InteropServices.OSPlatform]::Windows)
}

BeforeAll {
    $ModuleRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
    Import-Module (Join-Path $ModuleRoot 'Posh-MSAL.psd1') -Force -ErrorAction Stop
    $Public = New-MsalClientApplication -ClientId ([guid]::NewGuid().Guid)
    $Secret = New-Object System.Security.SecureString
    foreach ($Char in 'not-a-secret'.ToCharArray()) { $Secret.AppendChar($Char) }
    $Confidential = New-MsalClientApplication -ClientId ([guid]::NewGuid().Guid) -ClientSecret $Secret -TenantId ([guid]::NewGuid().Guid)
    $Scopes = [string[]] @('https://graph.microsoft.com/.default')
}

AfterAll {
    Remove-Module Posh-MSAL -ErrorAction SilentlyContinue
}

Describe 'Resolve-MsalTokenFlow' {
    It 'picks <Flow> for <Case>' -ForEach @(
        @{ Case = 'a client secret'; Set = 'ConfidentialClientSecret'; Bound = @{ ClientSecret = 1 }; Flow = 'ClientCredential' }
        @{ Case = 'an authorization code'; Set = 'ConfidentialClientSecret-AuthorizationCode'; Bound = @{ AuthorizationCode = 'x' }; Flow = 'AuthorizationCode' }
        @{ Case = 'a user assertion'; Set = 'ConfidentialClientCertificate-OnBehalfOf'; Bound = @{ UserAssertion = 'x' }; Flow = 'OnBehalfOf' }
        @{ Case = 'a confidential application passed in'; Set = 'ConfidentialClient-InputObject'; Bound = @{}; Flow = 'ClientCredential' }
        @{ Case = 'a user credential'; Set = 'PublicClient-UsernamePassword'; Bound = @{ UserCredential = 1 }; Flow = 'UsernamePassword' }
        @{ Case = '-DeviceCode'; Set = 'PublicClient-DeviceCode'; Bound = @{ DeviceCode = $true }; Flow = 'DeviceCode' }
        @{ Case = '-IntegratedWindowsAuth'; Set = 'PublicClient-IntegratedWindowsAuth'; Bound = @{ IntegratedWindowsAuth = $true }; Flow = 'IntegratedWindowsAuth' }
        @{ Case = '-Silent'; Set = 'PublicClient-Silent'; Bound = @{ Silent = $true }; Flow = 'Silent' }
        @{ Case = 'no flow switch'; Set = 'PublicClient'; Bound = @{}; Flow = 'Default' }
        @{ Case = '-Silent:$false'; Set = 'PublicClient-InputObject'; Bound = @{ Silent = $false }; Flow = 'Default' }
    ) {
        InModuleScope Posh-MSAL -Parameters @{ Set = $Set; Bound = $Bound; App = $(if ($Set -like 'Confidential*') { $Confidential } else { $Public }) } {
            param ($Set, $Bound, $App)
            Resolve-MsalTokenFlow $Set $Bound $App
        } | Should -Be $Flow
    }

    It 'turns -Interactive into device code without an embedded browser and a localhost redirect URI' {
        $App = New-MsalClientApplication -ClientId ([guid]::NewGuid().Guid) -RedirectUri 'https://login.microsoftonline.com/common/oauth2/nativeclient'
        InModuleScope Posh-MSAL -Parameters @{ App = $App } {
            param ($App)
            $Saved = $script:ModuleFeatureSupport.EmbeddedWebViewSupport
            try {
                $script:ModuleFeatureSupport.EmbeddedWebViewSupport = $false
                Resolve-MsalTokenFlow 'PublicClient-Interactive' @{ Interactive = $true } $App | Should -Be 'DeviceCode'
                $script:ModuleFeatureSupport.EmbeddedWebViewSupport = $true
                Resolve-MsalTokenFlow 'PublicClient-Interactive' @{ Interactive = $true } $App | Should -Be 'Interactive'
            }
            finally { $script:ModuleFeatureSupport.EmbeddedWebViewSupport = $Saved }
        }
    }

    It 'keeps -Interactive with the localhost redirect URI' {
        $App = New-MsalClientApplication -ClientId ([guid]::NewGuid().Guid) -RedirectUri 'http://localhost:8400/'
        InModuleScope Posh-MSAL -Parameters @{ App = $App } { param ($App) Resolve-MsalTokenFlow 'PublicClient-Interactive' @{ Interactive = $true } $App } | Should -Be 'Interactive'
    }
}

Describe 'Request builders' {
    It '<Function> builds a <Type>' -ForEach @(
        @{ Function = 'Get-MsalClientCredentialRequest'; Type = 'AcquireTokenForClientParameterBuilder'; IsConfidential = $true; Extra = @{ ForceRefresh = $true; SendX5C = $true } }
        @{ Function = 'Get-MsalOnBehalfOfRequest'; Type = 'AcquireTokenOnBehalfOfParameterBuilder'; IsConfidential = $true; Extra = @{ UserAssertion = 'eyJ0eXAiOiJKV1QifQ.e30.'; UserAssertionType = 'urn:ietf:params:oauth:grant-type:jwt-bearer' } }
        @{ Function = 'Get-MsalAuthorizationCodeRequest'; Type = 'AcquireTokenByAuthorizationCodeParameterBuilder'; IsConfidential = $true; Extra = @{ AuthorizationCode = 'code'; SendX5C = $true } }
        @{ Function = 'Get-MsalDeviceCodeRequest'; Type = 'AcquireTokenWithDeviceCodeParameterBuilder'; IsConfidential = $false; Extra = @{ DeviceCodeCallback = $true } }
        @{ Function = 'Get-MsalSilentRequest'; Type = 'AcquireTokenSilentParameterBuilder'; IsConfidential = $false; Extra = @{ LoginHint = 'user@contoso.com'; ForceRefresh = $false } }
        @{ Function = 'Get-MsalSilentRequest'; Type = 'AcquireTokenSilentParameterBuilder'; IsConfidential = $false; Extra = @{} }
        @{ Function = 'Get-MsalUsernamePasswordRequest'; Type = 'AcquireTokenByUsernamePasswordParameterBuilder'; IsConfidential = $false; Extra = @{ Credential = $true } }
        @{ Function = 'Get-MsalIntegratedWindowsAuthRequest'; Type = 'AcquireTokenByIntegratedWindowsAuthParameterBuilder'; IsConfidential = $false; Extra = @{ LoginHint = 'user@contoso.com' } }
        @{ Function = 'Get-MsalInteractiveRequest'; Type = 'AcquireTokenInteractiveParameterBuilder'; IsConfidential = $false; Extra = @{ LoginHint = 'user@contoso.com'; Prompt = 'SelectAccount'; ExtraScopesToConsent = [string[]] @('User.Read'); UseEmbeddedWebView = $false } }
    ) {
        $Arguments = @{ Application = $(if ($IsConfidential) { $Confidential } else { $Public }); Scopes = $Scopes }
        foreach ($Key in $Extra.Keys) { $Arguments[$Key] = $Extra[$Key] }
        if ($Arguments.ContainsKey('Credential')) { $Arguments['Credential'] = New-Object System.Management.Automation.PSCredential ('user@contoso.com', $Secret) }
        $Request = InModuleScope Posh-MSAL -Parameters @{ Function = $Function; Arguments = $Arguments } {
            param ($Function, $Arguments)
            if ($Arguments.ContainsKey('DeviceCodeCallback')) { $Arguments.Remove('DeviceCodeCallback'); $Arguments['Callback'] = (Get-MsalDeviceCodeCallback).Callback }
            & $Function @Arguments -WarningAction SilentlyContinue
        }
        $Request.GetType().Name | Should -Be $Type
    }

    It '<Function> warns that the flow is deprecated' -ForEach @(
        @{ Function = 'Get-MsalIntegratedWindowsAuthRequest'; Expected = '*Integrated Windows Authentication is deprecated*' }
        @{ Function = 'Get-MsalUsernamePasswordRequest'; Expected = '*username/password flow (ROPC) is deprecated*' }
    ) {
        $Credential = New-Object System.Management.Automation.PSCredential ('user@contoso.com', $Secret)
        $Warnings = InModuleScope Posh-MSAL -Parameters @{ Function = $Function; App = $Public; Scopes = $Scopes; Credential = $Credential } {
            param ($Function, $App, $Scopes, [pscredential] $Credential)
            $Arguments = @{ Scopes = $Scopes }
            if ($Function -eq 'Get-MsalUsernamePasswordRequest') { $Arguments['Credential'] = $Credential }
            [void] (& $Function $App @Arguments -WarningVariable Found -WarningAction SilentlyContinue)
            $Found
        }
        "$Warnings" | Should -BeLike $Expected
    }
}

Describe 'Add-MsalRequestOption' {
    It 'applies tenant, correlation id and extra query parameters, and returns the same request' {
        InModuleScope Posh-MSAL -Parameters @{ App = $Confidential; Scopes = $Scopes } {
            param ($App, $Scopes)
            $Request = $App.AcquireTokenForClient($Scopes)
            $Returned = Add-MsalRequestOption $Request -TenantId ([guid]::NewGuid().Guid) -CorrelationId ([guid]::NewGuid()) -ExtraQueryParameters @{ slice = 'testslice' }
            [object]::ReferenceEquals($Returned, $Request) | Should -BeTrue
        }
    }

    It 'leaves a request untouched without options' {
        InModuleScope Posh-MSAL -Parameters @{ App = $Confidential; Scopes = $Scopes } {
            param ($App, $Scopes)
            $Request = $App.AcquireTokenForClient($Scopes)
            [object]::ReferenceEquals((Add-MsalRequestOption $Request), $Request) | Should -BeTrue
        }
    }
}

Describe 'ConvertTo-MsalExtraQueryParameter' {
    It 'gives the dictionary MSAL 4.92 takes, values kept out of the cache key' {
        $Result = InModuleScope Posh-MSAL { ConvertTo-MsalExtraQueryParameter @{ slice = 'testslice'; dc = 'ESTS' } }
        $Result.GetType().GetGenericTypeDefinition() | Should -Be ([System.Collections.Generic.Dictionary`2])
        $Result.GetType().GetGenericArguments()[1] | Should -Be ([System.ValueTuple[string, bool]])
        $Result.Count | Should -Be 2
        $Result['slice'].Item1 | Should -Be 'testslice'
        $Result['slice'].Item2 | Should -BeFalse
    }
}

Describe 'Get-MsalClientAssertionCallback' {
    It 'returns the assertion when MSAL calls it from a thread-pool thread' {
        $Callback = InModuleScope Posh-MSAL { Get-MsalClientAssertionCallback 'header.payload.signature' }
        $Options = New-Object Microsoft.Identity.Client.AssertionRequestOptions
        $Invoke = [System.Linq.Expressions.Expression]::Invoke([System.Linq.Expressions.Expression]::Constant($Callback), [System.Linq.Expressions.Expression]::Constant($Options))
        $OnThreadPool = [System.Linq.Expressions.Expression]::Lambda([System.Func[System.Threading.Tasks.Task[string]]], $Invoke).Compile()
        [System.Threading.Tasks.Task]::Run($OnThreadPool).GetAwaiter().GetResult() | Should -Be 'header.payload.signature'
    }
}

Describe 'Test-MsalMissingScope' {
    BeforeAll {
        function Get-TestResult ([string[]] $Granted) {
            New-Object Microsoft.Identity.Client.AuthenticationResult ('token', $false, 'uid', [DateTimeOffset]::Now.AddHours(1), [DateTimeOffset]::Now.AddHours(1), 'tenant', $null, $null, $Granted, [guid]::NewGuid(), 'Bearer', $null, $null, $null, $null)
        }
    }

    It 'is <Expected> when <Case>' -ForEach @(
        @{ Case = 'every scope was granted'; Granted = @('User.Read', 'Mail.Read'); Requested = @('User.Read'); Expected = $false }
        @{ Case = 'a scope is missing'; Granted = @('User.Read'); Requested = @('User.Read', 'Mail.Read'); Expected = $true }
    ) {
        $Result = Get-TestResult $Granted
        InModuleScope Posh-MSAL -Parameters @{ Result = $Result; Requested = $Requested } { param ($Result, $Requested) Test-MsalMissingScope $Result $Requested } | Should -Be $Expected
    }
}
