[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '', Justification = 'Variables set in BeforeDiscovery / BeforeAll / BeforeEach are read by the It blocks.')]
param ()

BeforeDiscovery {
    $ModuleRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
    $BuiltIn = (Import-PowerShellDataFile -Path (Join-Path (Join-Path $ModuleRoot 'Data') 'MsalEnvironment.psd1')).Environments
    $InstanceCases = @($BuiltIn | Where-Object { $_.AzureCloudInstance } | ForEach-Object { @{ Instance = $_.AzureCloudInstance; Name = $_.Name; AzureADEndpoint = $_.AzureADEndpoint } })
}

BeforeAll {
    $ModuleRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
    Import-Module (Join-Path $ModuleRoot 'Posh-MSAL.psd1') -Force -ErrorAction Stop
    function Get-TestSecret {
        $Secret = New-Object System.Security.SecureString
        foreach ($Char in 'not-a-secret'.ToCharArray()) { $Secret.AppendChar($Char) }
        $Secret
    }
    $Saved = InModuleScope Posh-MSAL { $script:ModuleState.EnvironmentFile }
}

AfterAll {
    InModuleScope Posh-MSAL -Parameters @{ Saved = $Saved } {
        param ($Saved)
        $script:ModuleState.EnvironmentFile = $Saved
        $script:ModuleState.Environments = [System.Collections.Generic.List[psobject]] @(Import-MsalEnvironment)
    }
    Remove-Module Posh-MSAL -ErrorAction SilentlyContinue
}

Describe 'Built-in environments' {
    BeforeEach {
        Clear-MsalTokenCache
        $ClientId = [guid]::NewGuid().Guid
        $TenantId = [guid]::NewGuid().Guid
    }

    It 'lists the seven built-in clouds in order' {
        @(Get-MsalEnvironment | Where-Object Type -eq 'BuiltIn' | ForEach-Object Name) | Should -Be @('Global', 'USGov', 'USGovDoD', 'China', 'BleuCloud', 'DelosCloud', 'GovSGCloud')
    }

    Context '<Name>' -ForEach $BuiltIn {
        It 'builds the application on <AzureADEndpoint> with the tenant' {
            $App = New-MsalClientApplication -ClientId $ClientId -TenantId $TenantId -Environment $Name
            $App.AppConfig.Authority.AuthorityInfo.CanonicalAuthority.AbsoluteUri | Should -Be ('{0}/{1}/' -f $AzureADEndpoint, $TenantId)
        }

        It 'defaults the redirect URI to the environment on Windows PowerShell, to localhost on PowerShell 7' {
            $App = New-MsalClientApplication -ClientId $ClientId -Environment $Name
            $Expected = if ($PSVersionTable.PSEdition -eq 'Desktop') { '{0}/common/oauth2/nativeclient' -f $AzureADEndpoint } else { 'http://localhost' }
            $App.AppConfig.RedirectUri | Should -Be $Expected
        }

        It 'gives the default scope <GraphEndpoint>/.default' {
            $App = New-MsalClientApplication -ClientId $ClientId -Environment $Name
            $Resolved = InModuleScope Posh-MSAL -Parameters @{ App = $App; Name = $Name } { param ($App, $Name) Resolve-MsalEnvironment -Environment $Name -ApplicationAuthority $App.AppConfig.Authority.AuthorityInfo.CanonicalAuthority }
            $Resolved.DefaultScope | Should -Be ('{0}/.default' -f $GraphEndpoint)
        }
    }

    It '-AzureCloudInstance <Instance> maps onto <Name>' -ForEach $InstanceCases {
        $App = New-MsalClientApplication -ClientId $ClientId -AzureCloudInstance $Instance
        $App.AppConfig.Authority.AuthorityInfo.CanonicalAuthority.AbsoluteUri | Should -Be ('{0}/common/' -f $AzureADEndpoint)
    }

    It 'defaults to Global and the common tenant' {
        $App = New-MsalClientApplication -ClientId $ClientId
        $App.AppConfig.Authority.AuthorityInfo.CanonicalAuthority.AbsoluteUri | Should -Be 'https://login.microsoftonline.com/common/'
    }

    It 'infers USGov, not USGovDoD, from the shared authority host' {
        $App = New-MsalClientApplication -ClientId $ClientId -Authority "https://login.microsoftonline.us/$TenantId"
        $Resolved = InModuleScope Posh-MSAL -Parameters @{ App = $App } { param ($App) Resolve-MsalEnvironment -ApplicationAuthority $App.AppConfig.Authority.AuthorityInfo.CanonicalAuthority }
        $Resolved.Environment.Name | Should -Be 'USGov'
        $Resolved.DefaultScope | Should -Be 'https://graph.microsoft.us/.default'
        $DoD = InModuleScope Posh-MSAL -Parameters @{ App = $App } { param ($App) Resolve-MsalEnvironment -Environment USGovDoD -ApplicationAuthority $App.AppConfig.Authority.AuthorityInfo.CanonicalAuthority }
        $DoD.DefaultScope | Should -Be 'https://dod-graph.microsoft.us/.default'
    }

    It 'accepts -Environment USGovDoD with -AzureCloudInstance AzureUsGovernment (same host)' {
        $App = New-MsalClientApplication -ClientId $ClientId -Environment USGovDoD -AzureCloudInstance AzureUsGovernment
        $App.AppConfig.Authority.AuthorityInfo.Host | Should -Be 'login.microsoftonline.us'
    }
}

Describe 'Conflicts and errors' {
    BeforeEach {
        $ClientId = [guid]::NewGuid().Guid
        $TenantId = [guid]::NewGuid().Guid
    }

    It 'rejects <Case>' -ForEach @(
        @{ Case = '-Environment and -AzureCloudInstance of two clouds'; Parameters = @{ Environment = 'BleuCloud'; AzureCloudInstance = 'AzurePublic' }; Message = '*name different clouds*' }
        @{ Case = '-Authority outside -Environment'; Parameters = @{ Environment = 'Global'; Authority = 'https://login.sovcloud-identity.fr/contoso.onmicrosoft.com' }; Message = '*not in the Global environment*' }
        @{ Case = '-TenantId differing from the tenant of -Authority'; Parameters = @{ Authority = 'https://login.microsoftonline.com/tenant-a'; TenantId = 'tenant-b' }; Message = '*differ*' }
        @{ Case = 'AzureGermany'; Parameters = @{ AzureCloudInstance = 'AzureGermany' }; Message = '*closed in 2021*' }
        @{ Case = 'an unknown environment'; Parameters = @{ Environment = 'Nowhere' }; Message = '*Unknown environment "Nowhere"*' }
        @{ Case = '-TenantId with an authority no environment knows'; Parameters = @{ Authority = 'https://adfs.contoso.com/adfs'; TenantId = 'x' }; Message = '*put the tenant in -Authority*' }
    ) {
        { New-MsalClientApplication -ClientId $ClientId @Parameters } | Should -Throw -ErrorId 'MsalEnvironmentResolution*' -ExpectedMessage $Message
    }

    It 'keeps an -Authority no environment knows as given' {
        $App = New-MsalClientApplication -ClientId $ClientId -Authority 'https://contoso.b2clogin.com/tfp/contoso.onmicrosoft.com/B2C_1_signin'
        $App.AppConfig.Authority.AuthorityInfo.Host | Should -Be 'contoso.b2clogin.com'
    }

    It 'Get-MsalToken refuses another cloud than the application''s, before any request' {
        $App = New-MsalClientApplication -ClientId $ClientId -TenantId $TenantId -ClientSecret (Get-TestSecret) -Environment BleuCloud
        { $App | Get-MsalToken -Environment Global } | Should -Throw -ExpectedMessage '*built for login.sovcloud-identity.fr, not login.microsoftonline.com*'
    }

    It 'Get-MsalToken asks for -Scopes when no environment knows the authority' {
        $App = New-MsalClientApplication -ClientId $ClientId -ClientSecret (Get-TestSecret) -Authority 'https://adfs.contoso.com/adfs'
        { Get-MsalToken -ConfidentialClientApplication $App } | Should -Throw -ErrorId 'MsalNoDefaultScope*'
    }
}

Describe 'Client application cache' {
    BeforeEach {
        Clear-MsalTokenCache
        $ClientId = [guid]::NewGuid().Guid
    }

    It 'keeps one application per tenant' {
        $A = Select-MsalClientApplication -ClientId $ClientId -TenantId ([guid]::NewGuid().Guid)
        $B = Select-MsalClientApplication -ClientId $ClientId -TenantId ([guid]::NewGuid().Guid)
        [object]::ReferenceEquals($A, $B) | Should -BeFalse
        @(Get-MsalClientApplication -ClientId $ClientId) | Should -HaveCount 2
    }

    It 'Get-MsalClientApplication filters on -Environment, -TenantId and -ClientSecret' {
        $Secret = Get-TestSecret
        $TenantId = [guid]::NewGuid().Guid
        [void] (Select-MsalClientApplication -ClientId $ClientId -ClientSecret $Secret -TenantId $TenantId -Environment BleuCloud)
        [void] (Select-MsalClientApplication -ClientId $ClientId -ClientSecret $Secret -TenantId $TenantId -Environment Global)
        @(Get-MsalClientApplication -ClientSecret $Secret) | Should -HaveCount 2
        @(Get-MsalClientApplication -ClientSecret $Secret -Environment BleuCloud) | Should -HaveCount 1
        @(Get-MsalClientApplication -ClientSecret $Secret -TenantId $TenantId) | Should -HaveCount 2
    }
}

Describe 'User-defined environments' {
    BeforeEach {
        $File = Join-Path ([System.IO.Path]::GetTempPath()) ('posh-msal-env-' + [guid]::NewGuid().Guid + '.json')
        InModuleScope Posh-MSAL -Parameters @{ File = $File } {
            param ($File)
            $script:ModuleState.EnvironmentFile = $File
            $script:ModuleState.Environments = [System.Collections.Generic.List[psobject]] @(Import-MsalEnvironment)
        }
    }
    AfterEach {
        Remove-Item -LiteralPath $File -Force -ErrorAction SilentlyContinue
    }

    It 'adds, persists, changes and removes an environment' {
        $Added = Add-MsalEnvironment -Name Contoso -AzureADEndpoint 'https://Login.Contoso.com/' -GraphEndpoint 'https://graph.contoso.com'
        $Added.AzureADEndpoint | Should -Be 'https://login.contoso.com'
        $Added.Type | Should -Be 'UserDefined'
        @(Get-Content -LiteralPath $File -Raw | ConvertFrom-Json).Name | Should -Be 'Contoso'

        # A new session reads it back.
        $Reloaded = InModuleScope Posh-MSAL { Import-MsalEnvironment }
        ($Reloaded | Where-Object Name -eq 'Contoso').GraphEndpoint | Should -Be 'https://graph.contoso.com'

        (Set-MsalEnvironment -Name Contoso -GraphEndpoint 'https://graph2.contoso.com').GraphEndpoint | Should -Be 'https://graph2.contoso.com'
        (Get-MsalEnvironment Contoso).GraphEndpoint | Should -Be 'https://graph2.contoso.com'

        Remove-MsalEnvironment -Name Contoso -Confirm:$false
        Get-MsalEnvironment -Name Contoso -ErrorAction SilentlyContinue | Should -BeNullOrEmpty
        Test-Path -LiteralPath $File | Should -BeFalse
    }

    It 'warns and turns instance discovery off only when the environment asks for it' {
        [void] (Add-MsalEnvironment -Name Private1 -AzureADEndpoint 'https://login.private.example' -GraphEndpoint 'https://graph.private.example' -DisableInstanceDiscovery)
        $App = New-MsalClientApplication -ClientId ([guid]::NewGuid().Guid) -Environment Private1 -WarningVariable Warnings -WarningAction SilentlyContinue
        "$Warnings" | Should -BeLike '*Instance discovery and authority validation are off*'
        $App.AppConfig.IsInstanceDiscoveryEnabled | Should -BeFalse
        $App.AppConfig.Authority.AuthorityInfo.Host | Should -Be 'login.private.example'

        $Global = New-MsalClientApplication -ClientId ([guid]::NewGuid().Guid) -WarningVariable GlobalWarnings
        $GlobalWarnings | Should -BeNullOrEmpty
        $Global.AppConfig.IsInstanceDiscoveryEnabled | Should -BeTrue
    }

    It 'refuses to <Case>' -ForEach @(
        @{ Case = 'reuse a built-in name'; Command = { Add-MsalEnvironment -Name BleuCloud -AzureADEndpoint 'https://login.x.example' -GraphEndpoint 'https://graph.x.example' -ErrorAction Stop }; ErrorId = 'MsalEnvironmentExists*' }
        @{ Case = 'take an http endpoint'; Command = { Add-MsalEnvironment -Name Bad -AzureADEndpoint 'http://login.x.example' -GraphEndpoint 'https://graph.x.example' -ErrorAction Stop }; ErrorId = 'MsalEnvironmentInvalid*' }
        @{ Case = 'take an endpoint with a path'; Command = { Add-MsalEnvironment -Name Bad -AzureADEndpoint 'https://login.x.example/tenant' -GraphEndpoint 'https://graph.x.example' -ErrorAction Stop }; ErrorId = 'MsalEnvironmentInvalid*' }
        @{ Case = 'change a built-in environment'; Command = { Set-MsalEnvironment -Name Global -GraphEndpoint 'https://graph.x.example' -ErrorAction Stop }; ErrorId = 'MsalEnvironmentBuiltIn*' }
        @{ Case = 'remove a built-in environment'; Command = { Remove-MsalEnvironment -Name Global -Confirm:$false -ErrorAction Stop }; ErrorId = 'MsalEnvironmentBuiltIn*' }
    ) {
        $Command | Should -Throw -ErrorId $ErrorId
        Test-Path -LiteralPath $File | Should -BeFalse
    }

    It 'skips a damaged file with a warning and keeps the built-ins' {
        Set-Content -LiteralPath $File -Value '{ not json'
        $Loaded = InModuleScope Posh-MSAL { Import-MsalEnvironment -WarningVariable Warnings -WarningAction SilentlyContinue; $Warnings }
        @($Loaded | Where-Object { $_ -is [System.Management.Automation.WarningRecord] }) | Should -HaveCount 1
        @($Loaded | Where-Object { $_ -isnot [System.Management.Automation.WarningRecord] } | ForEach-Object { $_ } | Where-Object Type -eq 'BuiltIn') | Should -HaveCount 7
    }
}

Describe 'Environment helpers' {
    It 'ConvertTo-MsalEnvironment normalises a valid environment and rejects an invalid one' {
        InModuleScope Posh-MSAL {
            $Environment = ConvertTo-MsalEnvironment @{ Name = 'Lab'; AzureADEndpoint = 'https://LOGIN.lab.example/'; GraphEndpoint = 'https://graph.lab.example' } -Type UserDefined
            $Environment.AzureADEndpoint | Should -Be 'https://login.lab.example'
            $Environment.DisableInstanceDiscovery | Should -BeFalse
            $Environment.AzureCloudInstance | Should -BeNullOrEmpty
            $FromObject = ConvertTo-MsalEnvironment ([PSCustomObject] @{ Name = 'Lab2'; AzureADEndpoint = 'https://login.lab.example'; GraphEndpoint = 'https://graph.lab.example'; DisableInstanceDiscovery = $true }) -Type UserDefined
            $FromObject.DisableInstanceDiscovery | Should -BeTrue
            { ConvertTo-MsalEnvironment @{ Name = 'bad name'; AzureADEndpoint = 'https://a.example'; GraphEndpoint = 'https://b.example' } -Type UserDefined } | Should -Throw -ExpectedMessage '*Invalid environment name*'
        }
    }

    It 'ConvertTo-MsalEnvironment maps AzureCloudInstance case-insensitively, and leaves it empty when the loaded MSAL.NET lacks the value' {
        InModuleScope Posh-MSAL {
            $Entry = @{ Name = 'Lab'; AzureADEndpoint = 'https://login.lab.example'; GraphEndpoint = 'https://graph.lab.example'; AzureCloudInstance = 'govfr' }
            (ConvertTo-MsalEnvironment $Entry -Type BuiltIn).AzureCloudInstance | Should -Be ([Microsoft.Identity.Client.AzureCloudInstance]::GovFr)
            # An older MSAL.NET, loaded first by another module, has no GovFr: stands in with a value no version has.
            $Entry.AzureCloudInstance = 'GovNowhere'
            $Environment = ConvertTo-MsalEnvironment $Entry -Type BuiltIn -Verbose 4>&1 | Where-Object { $_ -isnot [System.Management.Automation.VerboseRecord] }
            $Environment.Name | Should -Be 'Lab'
            $Environment.AzureCloudInstance | Should -BeNullOrEmpty
        }
    }

    It 'Get-MsalEnvironmentByName finds an environment, case-insensitively, and names the known ones otherwise' {
        InModuleScope Posh-MSAL {
            (Get-MsalEnvironmentByName 'bleucloud').Name | Should -Be 'BleuCloud'
            { Get-MsalEnvironmentByName 'Nowhere' } | Should -Throw -ExpectedMessage '*Known environments: Global, USGov*'
        }
    }

    It 'Export-MsalEnvironment writes the user-defined environments only' {
        $File = Join-Path ([System.IO.Path]::GetTempPath()) ('posh-msal-env-' + [guid]::NewGuid().Guid + '.json')
        try {
            InModuleScope Posh-MSAL -Parameters @{ File = $File } {
                param ($File)
                $Saved = @{ File = $script:ModuleState.EnvironmentFile; Environments = $script:ModuleState.Environments }
                try {
                    $script:ModuleState.EnvironmentFile = $File
                    $script:ModuleState.Environments = [System.Collections.Generic.List[psobject]] @(Import-MsalEnvironment)
                    $script:ModuleState.Environments.Add((ConvertTo-MsalEnvironment @{ Name = 'Lab'; AzureADEndpoint = 'https://login.lab.example'; GraphEndpoint = 'https://graph.lab.example' } -Type UserDefined))
                    Export-MsalEnvironment
                    $Written = Get-Content -LiteralPath $File -Raw | ConvertFrom-Json
                    @($Written).Name | Should -Be @('Lab')
                }
                finally {
                    $script:ModuleState.EnvironmentFile = $Saved.File
                    $script:ModuleState.Environments = $Saved.Environments
                }
            }
        }
        finally { Remove-Item -LiteralPath $File -Force -ErrorAction SilentlyContinue }
    }
}
