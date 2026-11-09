[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '', Justification = 'Variables set in BeforeAll / BeforeEach are read by the It blocks.')]
param ()

BeforeAll {
    $ModuleRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
    Import-Module (Join-Path $ModuleRoot 'Posh-MSAL.psd1') -Force -ErrorAction Stop
    $Secret = New-Object System.Security.SecureString
    foreach ($Char in 'not-a-secret'.ToCharArray()) { $Secret.AppendChar($Char) }
}

AfterAll {
    Remove-Module Posh-MSAL -ErrorAction SilentlyContinue
}

Describe 'New-MsalClientApplication' {
    It 'builds a public client by default and a confidential client with a credential' {
        New-MsalClientApplication -ClientId ([guid]::NewGuid().Guid) | Should -BeOfType ([Microsoft.Identity.Client.IPublicClientApplication])
        New-MsalClientApplication -ClientId ([guid]::NewGuid().Guid) -ClientSecret $Secret | Should -BeOfType ([Microsoft.Identity.Client.IConfidentialClientApplication])
    }

    It 'builds one application per client id piped in' {
        $Ids = 1..3 | ForEach-Object { [guid]::NewGuid().Guid }
        @($Ids | New-MsalClientApplication | ForEach-Object { $_.AppConfig.ClientId }) | Should -Be $Ids
    }

    It 'takes MSAL option objects' {
        $Options = New-Object Microsoft.Identity.Client.PublicClientApplicationOptions
        $Options.ClientId = [guid]::NewGuid().Guid
        $Options.TenantId = [guid]::NewGuid().Guid
        $App = $Options | New-MsalClientApplication
        $App.AppConfig.ClientId | Should -Be $Options.ClientId
    }

    It 'accepts a client assertion, extra query parameters and experimental features' {
        $App = New-MsalClientApplication -ClientId ([guid]::NewGuid().Guid) -ClientAssertion 'header.payload.signature' -ExtraQueryParameters @{ slice = 'test' } -EnableExperimentalFeatures
        $App | Should -BeOfType ([Microsoft.Identity.Client.IConfidentialClientApplication])
        $App.AppConfig.ExperimentalFeaturesEnabled | Should -BeTrue
    }

    It 'refuses the broker where there is none' -Skip:([System.Runtime.InteropServices.RuntimeInformation]::IsOSPlatform([System.Runtime.InteropServices.OSPlatform]::Windows)) {
        { New-MsalClientApplication -ClientId ([guid]::NewGuid().Guid) -AuthenticationBroker } | Should -Throw -ErrorId 'NewMsalClientApplicationBrokerNotSupported*'
    }

    It 'enables the broker on Windows' -Skip:(-not [System.Runtime.InteropServices.RuntimeInformation]::IsOSPlatform([System.Runtime.InteropServices.OSPlatform]::Windows)) {
        (New-MsalClientApplication -ClientId ([guid]::NewGuid().Guid) -AuthenticationBroker).AppConfig.IsBrokerEnabled | Should -BeTrue
    }
}

Describe 'Session applications' {
    BeforeEach {
        Clear-MsalTokenCache
        $Public = New-MsalClientApplication -ClientId ([guid]::NewGuid().Guid)
        $Confidential = New-MsalClientApplication -ClientId ([guid]::NewGuid().Guid) -ClientSecret $Secret
    }

    It 'Add-MsalClientApplication adds public and confidential applications, once' {
        Add-MsalClientApplication $Public
        Add-MsalClientApplication -ConfidentialClientApplication $Confidential -PassThru | Should -Be $Confidential
        # Without a credential, every application of the session; with one, the matching confidential ones.
        @(Get-MsalClientApplication) | Should -HaveCount 2
        @(Get-MsalClientApplication -ClientSecret $Secret) | Should -Be @($Confidential)
        { Add-MsalClientApplication $Public -ErrorAction Stop } | Should -Throw -ErrorId 'AddMsalClientApplicationFailureAlreadyExists*'
    }

    It 'Add- and Remove-MsalClientApplication process every application piped in' {
        $More = 1..2 | ForEach-Object { New-MsalClientApplication -ClientId ([guid]::NewGuid().Guid) }
        $More | Add-MsalClientApplication
        @(Get-MsalClientApplication) | Should -HaveCount 2
        $More | Remove-MsalClientApplication
        @(Get-MsalClientApplication) | Should -HaveCount 0
    }

    It 'Remove-MsalClientApplication honours -WhatIf and fails on an unknown application' {
        # "What if:" is written to the host, not to a stream, so it cannot be redirected; a separate
        # runspace has no console host and keeps it out of the test output.
        $Isolated = [powershell]::Create()
        try {
            $Count = $Isolated.AddScript({
                    param ($ManifestPath)
                    Import-Module $ManifestPath -ErrorAction Stop
                    $App = New-MsalClientApplication -ClientId ([guid]::NewGuid().Guid)
                    Add-MsalClientApplication $App
                    Remove-MsalClientApplication $App -WhatIf
                    @(Get-MsalClientApplication).Count
                }).AddArgument((Join-Path $ModuleRoot 'Posh-MSAL.psd1')).Invoke()
            $Isolated.Streams.Error | Should -BeNullOrEmpty
            $Count | Should -Be 1
        }
        finally {
            $Isolated.Dispose()
        }
        Add-MsalClientApplication $Public
        Remove-MsalClientApplication $Public
        { Remove-MsalClientApplication $Public } | Should -Throw -ErrorId 'RemoveMsalClientApplicationFailureNotFound*'
    }

    It 'Select-MsalClientApplication returns one application per set of settings piped in' {
        $Ids = [guid]::NewGuid().Guid, [guid]::NewGuid().Guid
        @($Ids | Select-MsalClientApplication) | Should -HaveCount 2
        @($Ids | Select-MsalClientApplication) | Should -HaveCount 2
        @(Get-MsalClientApplication) | Should -HaveCount 2
    }

    It 'Select-MsalClientApplication keeps confidential clients apart by credential' {
        $ClientId = [guid]::NewGuid().Guid
        $Other = New-Object System.Security.SecureString
        foreach ($Char in 'another-secret'.ToCharArray()) { $Other.AppendChar($Char) }
        $A = Select-MsalClientApplication -ClientId $ClientId -ClientSecret $Secret
        $B = Select-MsalClientApplication -ClientId $ClientId -ClientSecret $Other
        $C = Select-MsalClientApplication -ClientId $ClientId -ClientSecret $Secret
        [object]::ReferenceEquals($A, $B) | Should -BeFalse
        [object]::ReferenceEquals($A, $C) | Should -BeTrue
    }

    It 'Clear-MsalTokenCache forgets the session''s applications' {
        Add-MsalClientApplication $Public
        Add-MsalClientApplication $Confidential
        Clear-MsalTokenCache
        @(Get-MsalClientApplication) | Should -HaveCount 0
        @(Get-MsalClientApplication -ClientSecret $Secret) | Should -HaveCount 0
    }

    It 'Test-MsalApplicationMatch compares client id, redirect URI, tenant, authority and host' {
        $TenantId = [guid]::NewGuid().Guid
        $App = New-MsalClientApplication -ClientId ([guid]::NewGuid().Guid) -TenantId $TenantId -Environment BleuCloud -RedirectUri 'http://localhost'
        InModuleScope Posh-MSAL -Parameters @{ App = $App; TenantId = $TenantId } {
            param ($App, $TenantId)
            Test-MsalApplicationMatch $App | Should -BeTrue
            Test-MsalApplicationMatch $App -ClientId $App.AppConfig.ClientId -TenantId $TenantId -AuthorityHost 'login.sovcloud-identity.fr' -RedirectUri 'http://localhost' | Should -BeTrue
            Test-MsalApplicationMatch $App -Authority "https://login.sovcloud-identity.fr/$TenantId" | Should -BeTrue
            Test-MsalApplicationMatch $App -ClientId ([guid]::NewGuid().Guid) | Should -BeFalse
            Test-MsalApplicationMatch $App -TenantId 'other' | Should -BeFalse
            Test-MsalApplicationMatch $App -AuthorityHost 'login.microsoftonline.com' | Should -BeFalse
            Test-MsalApplicationMatch $App -RedirectUri 'http://localhost:9999' | Should -BeFalse
        }
    }
}

Describe 'Get-MsalAccount' {
    It 'returns no account from an empty cache, for each application piped in' {
        $Apps = 1..2 | ForEach-Object { New-MsalClientApplication -ClientId ([guid]::NewGuid().Guid) }
        @($Apps | Get-MsalAccount) | Should -HaveCount 0
    }

    It 'lists the accounts of the cache, filtered by -Username, from an application or from accounts' {
        # Two accounts with their refresh tokens, in the MSAL v3 cache format, loaded through a
        # plain cache file in a temporary folder.
        $ClientId = [guid]::NewGuid().Guid
        $EnvHost = 'login.microsoftonline.com'
        $Cache = @{ Account = @{}; RefreshToken = @{} }
        foreach ($User in 'a@contoso.com', 'b@contoso.com') {
            $Uid = [guid]::NewGuid().Guid; $Utid = [guid]::NewGuid().Guid; $AccountId = "$Uid.$Utid"
            $Cache.Account["$AccountId-$EnvHost-$Utid"] = @{ home_account_id = $AccountId; environment = $EnvHost; realm = $Utid; local_account_id = $Uid; username = $User; authority_type = 'MSSTS' }
            $Cache.RefreshToken["$AccountId-$EnvHost-refreshtoken-$ClientId--"] = @{ home_account_id = $AccountId; environment = $EnvHost; credential_type = 'RefreshToken'; client_id = $ClientId; secret = 'not-a-token' }
        }
        $Folder = Join-Path ([System.IO.Path]::GetTempPath()) ('posh-msal-account-' + [guid]::NewGuid().Guid.Substring(0, 8))
        try {
            $Properties = (New-Object Microsoft.Identity.Client.Extensions.Msal.StorageCreationPropertiesBuilder ('accounts.bin', $Folder)).WithUnprotectedFile().Build()
            $Helper = [Microsoft.Identity.Client.Extensions.Msal.MsalCacheHelper]::CreateAsync($Properties, $null).GetAwaiter().GetResult()
            $Helper.SaveUnencryptedTokenCache([System.Text.Encoding]::UTF8.GetBytes((ConvertTo-Json $Cache -Depth 5)))
            $App = New-MsalClientApplication -ClientId $ClientId
            $Helper.RegisterCache($App.UserTokenCache)

            @(Get-MsalAccount $App | ForEach-Object Username | Sort-Object) | Should -Be @('a@contoso.com', 'b@contoso.com')
            (Get-MsalAccount $App -Username 'b@contoso.com').Username | Should -Be 'b@contoso.com'
            $Accounts = Get-MsalAccount $App
            (Get-MsalAccount -Accounts $Accounts -Username 'a@contoso.com').Username | Should -Be 'a@contoso.com'
            $Helper.UnregisterCache($App.UserTokenCache)
        }
        finally {
            Remove-Item -LiteralPath $Folder -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
}

Describe 'Get-MsalFeatureSupport' {
    It 'reports the loaded MSAL version and what works here' {
        $Features = Get-MsalFeatureSupport
        $Features.MsalVersion | Should -Match '^4\.\d+\.\d+\.\d+$'
        $Features.DeviceCodeSupport | Should -BeTrue
        $Features.AuthBrokerSupport | Should -Be ([System.Runtime.InteropServices.RuntimeInformation]::IsOSPlatform([System.Runtime.InteropServices.OSPlatform]::Windows))
    }
}
