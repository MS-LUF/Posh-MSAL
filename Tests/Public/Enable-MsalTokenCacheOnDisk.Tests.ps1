[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '', Justification = 'Variables set in BeforeAll / BeforeEach are read by the It blocks.')]
param ()

BeforeDiscovery {
    $OnWindows = [System.Runtime.InteropServices.RuntimeInformation]::IsOSPlatform([System.Runtime.InteropServices.OSPlatform]::Windows)
}

BeforeAll {
    $ModuleRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
    Import-Module (Join-Path $ModuleRoot 'Posh-MSAL.psd1') -Force -ErrorAction Stop
    if ($PSVersionTable.PSEdition -eq 'Desktop') { Add-Type -AssemblyName System.Security }

    # An MSAL v3 cache (the format MSAL.PS 4.37 wrote) with one account and its refresh token.
    function Get-TestCacheJson ([string] $ClientId, [string] $Username) {
        $Uid = [guid]::NewGuid().Guid
        $Utid = [guid]::NewGuid().Guid
        $AccountId = "$Uid.$Utid"
        $EnvHost = 'login.microsoftonline.com'
        @{
            Account      = @{ "$AccountId-$EnvHost-$Utid" = @{ home_account_id = $AccountId; environment = $EnvHost; realm = $Utid; local_account_id = $Uid; username = $Username; authority_type = 'MSSTS' } }
            RefreshToken = @{ "$AccountId-$EnvHost-refreshtoken-$ClientId--" = @{ home_account_id = $AccountId; environment = $EnvHost; credential_type = 'RefreshToken'; client_id = $ClientId; secret = 'not-a-token' } }
        } | ConvertTo-Json -Depth 5
    }
    function Write-TestLegacyCache ([string] $Path, [string] $Json) {
        $Bytes = [System.Security.Cryptography.ProtectedData]::Protect([System.Text.Encoding]::UTF8.GetBytes($Json), $null, [System.Security.Cryptography.DataProtectionScope]::CurrentUser)
        [System.IO.File]::WriteAllBytes($Path, $Bytes)
    }
    function Initialize-TestCacheState ([string] $Root) {
        InModuleScope Posh-MSAL -Parameters @{ Root = $Root } {
            param ($Root)
            $script:ModuleState.TokenCacheDirectory = Join-Path $Root 'cache'
            $script:ModuleState.LegacyTokenCachePath = Join-Path $Root 'MSAL.PS.msalcache.bin3'
            $script:ModuleState.TokenCacheHelpers = @{}
        }
    }
    function Get-TestSecret {
        $Secret = New-Object System.Security.SecureString
        foreach ($Char in 'not-a-secret'.ToCharArray()) { $Secret.AppendChar($Char) }
        $Secret
    }
    $Saved = InModuleScope Posh-MSAL { $script:ModuleState.Clone() }
}

AfterAll {
    InModuleScope Posh-MSAL -Parameters @{ Saved = $Saved } { param ($Saved) $script:ModuleState = $Saved }
    Remove-Module Posh-MSAL -ErrorAction SilentlyContinue
}

Describe 'Enable-MsalTokenCacheOnDisk' {
    BeforeEach {
        $Root = Join-Path ([System.IO.Path]::GetTempPath()) ('posh-msal-test-' + [guid]::NewGuid().Guid.Substring(0, 8))
        [void] (New-Item -ItemType Directory -Path $Root)
        Initialize-TestCacheState $Root
        Clear-MsalTokenCache
        $ClientId = [guid]::NewGuid().Guid
        $TenantId = [guid]::NewGuid().Guid
        $LegacyPath = Join-Path $Root 'MSAL.PS.msalcache.bin3'
        $UserCachePath = Join-Path (Join-Path $Root 'cache') 'Posh-MSAL.usercache.bin'
    }
    AfterEach {
        Initialize-TestCacheState $Root
        Remove-Item -LiteralPath $Root -Recurse -Force -ErrorAction SilentlyContinue
    }

    Context 'on Windows (DPAPI)' -Skip:(-not $OnWindows) {
        It 'migrates the MSAL.PS cache once, encrypted, and leaves the old file untouched' {
            Write-TestLegacyCache $LegacyPath (Get-TestCacheJson $ClientId 'legacy@contoso.com')
            $LegacyHash = (Get-FileHash -LiteralPath $LegacyPath).Hash
            $App = New-MsalClientApplication -ClientId $ClientId -TenantId $TenantId
            Enable-MsalTokenCacheOnDisk $App

            @(Get-MsalAccount $App).Username | Should -Be @('legacy@contoso.com')
            (Get-FileHash -LiteralPath $LegacyPath).Hash | Should -Be $LegacyHash
            # DPAPI output, not the JSON itself.
            [System.IO.File]::ReadAllBytes($UserCachePath)[0] | Should -Not -Be ([byte][char]'{')
        }

        It 'does not migrate again once the new cache holds data' {
            Write-TestLegacyCache $LegacyPath (Get-TestCacheJson $ClientId 'first@contoso.com')
            Enable-MsalTokenCacheOnDisk (New-MsalClientApplication -ClientId $ClientId -TenantId $TenantId)
            # A new session, and a different old cache.
            Initialize-TestCacheState $Root
            Clear-MsalTokenCache
            Write-TestLegacyCache $LegacyPath (Get-TestCacheJson $ClientId 'second@contoso.com')
            $App = New-MsalClientApplication -ClientId $ClientId -TenantId $TenantId
            Enable-MsalTokenCacheOnDisk $App
            @(Get-MsalAccount $App).Username | Should -Be @('first@contoso.com')
        }

        It 'warns and starts empty when the old cache cannot be read' {
            [System.IO.File]::WriteAllBytes($LegacyPath, [byte[]] (1..64))
            $App = New-MsalClientApplication -ClientId $ClientId -TenantId $TenantId
            Enable-MsalTokenCacheOnDisk $App -WarningVariable Warnings -WarningAction SilentlyContinue
            $Warnings | Should -HaveCount 1
            "$Warnings" | Should -BeLike '*was not migrated*'
            @(Get-MsalAccount $App) | Should -HaveCount 0
        }

        It 'Get-MsalCacheHelper keeps one helper per store for the session' {
            InModuleScope Posh-MSAL {
                $First = Get-MsalCacheHelper User
                [object]::ReferenceEquals((Get-MsalCacheHelper User), $First) | Should -BeTrue
                [object]::ReferenceEquals((Get-MsalCacheHelper App), $First) | Should -BeFalse
            }
        }

        It 'Import-MsalLegacyTokenCache does nothing without an old cache file' {
            InModuleScope Posh-MSAL {
                $Helper = Get-MsalCacheHelper User
                Import-MsalLegacyTokenCache $Helper -WarningVariable Warnings
                $Warnings | Should -BeNullOrEmpty
                $Helper.LoadUnencryptedTokenCache().Length | Should -Be 0
            }
        }

        It 'keeps the user and the app tokens of a confidential client in separate stores' {
            $App = New-MsalClientApplication -ClientId $ClientId -TenantId $TenantId -ClientSecret (Get-TestSecret)
            Enable-MsalTokenCacheOnDisk $App
            $Paths = InModuleScope Posh-MSAL { foreach ($Store in 'User', 'App') { (Get-MsalCacheStorageProperty $Store).CacheFilePath } }
            $Paths[0] | Should -Not -Be $Paths[1]
            @(InModuleScope Posh-MSAL { $script:ModuleState.TokenCacheHelpers.Keys } | Sort-Object) | Should -Be @('App', 'User')
        }

        It 'Clear-MsalTokenCache -FromDisk deletes the new cache and the old file' {
            Write-TestLegacyCache $LegacyPath (Get-TestCacheJson $ClientId 'legacy@contoso.com')
            $App = New-MsalClientApplication -ClientId $ClientId -TenantId $TenantId
            Enable-MsalTokenCacheOnDisk $App
            Test-Path -LiteralPath $UserCachePath | Should -BeTrue

            Clear-MsalTokenCache -FromDisk
            Test-Path -LiteralPath $UserCachePath | Should -BeFalse
            Test-Path -LiteralPath $LegacyPath | Should -BeFalse
            # The registered application reads the store again: it is empty.
            @(Get-MsalAccount $App) | Should -HaveCount 0
        }
    }

    Context 'when the cache cannot be encrypted' {
        BeforeEach {
            # One mock for both cases: Pester 6 no longer falls back to the real command when a filter does not match.
            # The unprotected helper is built the way Get-MsalCacheStorageProperty -Unprotected does.
            Mock -ModuleName Posh-MSAL New-MsalCacheHelper {
                if (-not $Unprotected) { throw (New-Object System.InvalidOperationException 'no keyring in this session') }
                $Properties = InModuleScope Posh-MSAL -Parameters @{ Store = $Store } { param ($Store) Get-MsalCacheStorageProperty $Store -Unprotected }
                [Microsoft.Identity.Client.Extensions.Msal.MsalCacheHelper]::CreateAsync($Properties, $null).GetAwaiter().GetResult()
            }
        }

        It 'fails and names -AllowUnencryptedStorage' {
            $App = New-MsalClientApplication -ClientId $ClientId -TenantId $TenantId
            { Enable-MsalTokenCacheOnDisk $App } | Should -Throw -ErrorId 'MsalTokenCacheNotProtected*' -ExpectedMessage '*no keyring in this session*-AllowUnencryptedStorage*'
            Test-Path -LiteralPath (Join-Path $Root 'cache') | Should -BeFalse
        }

        It 'with -AllowUnencryptedStorage, warns and uses a plain file' {
            $App = New-MsalClientApplication -ClientId $ClientId -TenantId $TenantId
            Enable-MsalTokenCacheOnDisk $App -AllowUnencryptedStorage -WarningVariable Warnings -WarningAction SilentlyContinue
            "$Warnings" | Should -BeLike '*NOT encrypted*Posh-MSAL.usercache.unprotected.bin*'
            $Helper = InModuleScope Posh-MSAL { $script:ModuleState.TokenCacheHelpers['User.Unprotected'] }
            $Helper.SaveUnencryptedTokenCache([System.Text.Encoding]::UTF8.GetBytes((Get-TestCacheJson $ClientId 'plain@contoso.com')))
            @(Get-MsalAccount $App).Username | Should -Be @('plain@contoso.com')
            Get-Content -LiteralPath (Join-Path (Join-Path $Root 'cache') 'Posh-MSAL.usercache.unprotected.bin') -Raw | Should -BeLike '*plain@contoso.com*'

            Clear-MsalTokenCache -FromDisk
            Test-Path -LiteralPath (Join-Path (Join-Path $Root 'cache') 'Posh-MSAL.usercache.unprotected.bin') | Should -BeFalse
        }
    }
}

Describe 'Module configuration' {
    It 'lives in the Posh-MSAL folder' {
        InModuleScope Posh-MSAL { Split-Path -Leaf $script:ModuleState.ConfigDirectory } | Should -Be 'Posh-MSAL'
    }

    It 'reads poshmsal.* environment variables and ignores msalps.*' {
        try {
            ${env:poshmsal.dll.lenientLoadingPrompt} = 'false'
            ${env:msalps.dll.lenientLoading} = 'true'
            $Config = InModuleScope Posh-MSAL {
                $Config = $script:ModuleConfigDefault.psobject.Copy()
                Set-MsalConfig -ResolveFromEnvironmentVariables -OutConfig ([ref] $Config)
                $Config
            }
            $Config.'dll.lenientLoadingPrompt' | Should -Be 'false'
            $Config.'dll.lenientLoading' | Should -BeFalse
        }
        finally {
            Remove-Item -LiteralPath 'env:poshmsal.dll.lenientLoadingPrompt', 'env:msalps.dll.lenientLoading' -ErrorAction SilentlyContinue
        }
    }
}
