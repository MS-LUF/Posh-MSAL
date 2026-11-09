[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '', Justification = 'Variables set in BeforeEach are read by the It blocks.')]
param ()

BeforeAll {
    $ModuleRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
    Import-Module (Join-Path $ModuleRoot 'Posh-MSAL.psd1') -Force -ErrorAction Stop
}

AfterAll {
    Remove-Module Posh-MSAL -ErrorAction SilentlyContinue
}

Describe 'Select-MsalClientApplication' {
    BeforeEach {
        Clear-MsalTokenCache
        $ClientId = [guid]::NewGuid().Guid
        $Tenant = [guid]::NewGuid().Guid
    }

    It 'returns the cached application for the same client and cloud' {
        $First = Select-MsalClientApplication -ClientId $ClientId -Authority "https://login.microsoftonline.com/$Tenant"
        $Second = Select-MsalClientApplication -ClientId $ClientId -Authority "https://login.microsoftonline.com/$Tenant"
        [object]::ReferenceEquals($First, $Second) | Should -BeTrue
    }

    It 'never returns an application of another cloud for the same client id' {
        # MSAL 4.92 rejects a request for another cloud than its application (authority_host_mismatch).
        $Public = Select-MsalClientApplication -ClientId $ClientId -Authority "https://login.microsoftonline.com/$Tenant"
        $Bleu = Select-MsalClientApplication -ClientId $ClientId -Authority "https://login.sovcloud-identity.fr/$Tenant"
        [object]::ReferenceEquals($Public, $Bleu) | Should -BeFalse
        $Public.AppConfig.Authority.AuthorityInfo.Host | Should -Be 'login.microsoftonline.com'
        $Bleu.AppConfig.Authority.AuthorityInfo.Host | Should -Be 'login.sovcloud-identity.fr'
    }
}
