[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '', Justification = 'Variables set in BeforeDiscovery and BeforeAll are read by the Describe and It blocks.')]
param ()

BeforeDiscovery {
    $ModuleRoot = Split-Path -Parent $PSScriptRoot
    $Pins = Import-PowerShellDataFile -Path (Join-Path (Join-Path $ModuleRoot 'Data') 'MsalDependency.psd1')
    $PinnedFiles = @(foreach ($Package in $Pins.Packages) { foreach ($File in $Package.Files) { @{ Package = $Package.Id; Version = $Package.Version; Target = $File.Target; Sha256 = $File.Sha256 } } })
}

BeforeAll {
    $ModuleRoot = Split-Path -Parent $PSScriptRoot
    $LibPath = Join-Path $ModuleRoot 'lib'
    $Pins = Import-PowerShellDataFile -Path (Join-Path (Join-Path $ModuleRoot 'Data') 'MsalDependency.psd1')
}

Describe 'lib/ against Data/MsalDependency.psd1' {
    It '<Target> (<Package> <Version>) is present with its pinned SHA-256' -ForEach $PinnedFiles {
        $Path = Join-Path $LibPath $Target
        $Path | Should -Exist
        (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash | Should -Be $Sha256
    }

    It 'holds no file that is not pinned' {
        $Pinned = @($Pins.Packages | ForEach-Object { $_.Files } | ForEach-Object { $_.Target })
        $Present = @(Get-ChildItem -Path $LibPath -Recurse -File | ForEach-Object { $_.FullName.Substring($LibPath.Length + 1).Replace('\', '/') })
        @($Present | Where-Object { $Pinned -notcontains $_ }) | Should -BeNullOrEmpty
    }

    It 'pins every package once, with a SHA-512' {
        # A script block: under Windows PowerShell, Group-Object does not read hashtable keys by name.
        @($Pins.Packages | Group-Object { $_.Id } | Where-Object Count -gt 1) | Should -BeNullOrEmpty
        foreach ($Package in $Pins.Packages) { [System.Convert]::FromBase64String($Package.Sha512).Length | Should -Be 64 }
    }

    It 'gives each edition a Microsoft.Identity.Client build' {
        foreach ($TargetFramework in 'net472', 'net8.0') {
            Join-Path (Join-Path $LibPath $TargetFramework) 'Microsoft.Identity.Client.dll' | Should -Exist
        }
    }
}
