[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '', Justification = 'Variables set in BeforeDiscovery and BeforeAll are read by the Describe and It blocks.')]
param ()

BeforeDiscovery {
    $ModuleRoot = Split-Path -Parent $PSScriptRoot
    $PublicFiles = @(Get-ChildItem -Path (Join-Path $ModuleRoot 'Public') -Filter '*.ps1' | ForEach-Object { @{ File = $_ } })
    $PrivateFiles = @(Get-ChildItem -Path (Join-Path $ModuleRoot 'Private') -Filter '*.ps1' -Recurse | ForEach-Object { @{ File = $_ } })
    $ScriptFiles = $PublicFiles + $PrivateFiles + @(
        @{ File = Get-Item (Join-Path $ModuleRoot 'Posh-MSAL.psm1') }
        @{ File = Get-Item (Join-Path $ModuleRoot 'Posh-MSAL.psd1') }
    )
}

BeforeAll {
    $ModuleRoot = Split-Path -Parent $PSScriptRoot
    $ManifestPath = Join-Path $ModuleRoot 'Posh-MSAL.psd1'
    $Manifest = Import-PowerShellDataFile -Path $ManifestPath
    $Module = Import-Module $ManifestPath -Force -PassThru -ErrorAction Stop

    # Lists the top-level functions a file defines, from its syntax tree, without running it.
    function Get-FunctionName ([string] $Path) {
        $Ast = [System.Management.Automation.Language.Parser]::ParseFile($Path, [ref] $null, [ref] $null)
        @($Ast.FindAll({ param($Node) $Node -is [System.Management.Automation.Language.FunctionDefinitionAst] }, $false) | ForEach-Object { $_.Name })
    }
}

AfterAll {
    Remove-Module Posh-MSAL -ErrorAction SilentlyContinue
}

Describe 'Manifest' {
    It 'is a valid module manifest' {
        { Test-ModuleManifest -Path $ManifestPath -ErrorAction Stop } | Should -Not -Throw
    }

    It 'carries the Posh-MSAL identity, not the upstream MSAL.PS one' {
        $Manifest.RootModule | Should -Be 'Posh-MSAL.psm1'
        $Manifest.GUID | Should -Not -Be 'c765c957-c730-4520-9c36-6a522e35d60b'
        $Manifest.Author | Should -Be 'MS-LUF'
        $Manifest.CompanyName | Should -Not -Match 'Microsoft'
    }

    It 'exports the same functions as the loader' {
        $LoaderAst = [System.Management.Automation.Language.Parser]::ParseFile((Join-Path $ModuleRoot 'Posh-MSAL.psm1'), [ref] $null, [ref] $null)
        $ExportCall = $LoaderAst.Find({ param($Node) $Node -is [System.Management.Automation.Language.CommandAst] -and $Node.GetCommandName() -eq 'Export-ModuleMember' }, $true)
        $LoaderExports = @($ExportCall.FindAll({ param($Node) $Node -is [System.Management.Automation.Language.StringConstantExpressionAst] -and $Node.Parent -isnot [System.Management.Automation.Language.CommandAst] }, $true) | ForEach-Object { $_.Value })
        @($LoaderExports | Sort-Object) | Should -Be @($Manifest.FunctionsToExport | Sort-Object)
    }
}

Describe 'Module import' {
    It 'exports exactly the public cmdlets' {
        $PublicNames = @(Get-ChildItem -Path (Join-Path $ModuleRoot 'Public') -Filter '*.ps1' | ForEach-Object { $_.BaseName })
        @($Module.ExportedFunctions.Keys | Sort-Object) | Should -Be @($PublicNames | Sort-Object)
        @($Module.ExportedFunctions.Keys | Sort-Object) | Should -Be @($Manifest.FunctionsToExport | Sort-Object)
    }

    It 'exports no cmdlet, alias or variable' {
        $Module.ExportedCmdlets.Count | Should -Be 0
        $Module.ExportedAliases.Count | Should -Be 0
        $Module.ExportedVariables.Count | Should -Be 0
    }

    It 'loads the pinned MSAL.NET from lib/' {
        $Pins = Import-PowerShellDataFile -Path (Join-Path (Join-Path $ModuleRoot 'Data') 'MsalDependency.psd1')
        $Pinned = ($Pins.Packages | Where-Object Id -eq 'Microsoft.Identity.Client').Version
        $Msal = 'Microsoft.Identity.Client.PublicClientApplication' -as [type]
        $Msal | Should -Not -BeNullOrEmpty
        $Msal.Assembly.Location | Should -BeLike (Join-Path (Join-Path $ModuleRoot 'lib') '*')
        (Get-MsalFeatureSupport).MsalVersion | Should -Be ('{0}.0' -f $Pinned)
    }

    It 'reports the feature support flags' {
        $Features = Get-MsalFeatureSupport
        @($Features.psobject.Properties.Name) | Should -Be @('EmbeddedWebViewSupport', 'DeviceCodeSupport', 'TokenCacheSupport', 'AuthBrokerSupport', 'MsalVersion', 'AssemblyConflicts')
        $Features.EmbeddedWebViewSupport | Should -Be ($PSVersionTable.PSEdition -eq 'Desktop')
        @($Features.AssemblyConflicts).Count | Should -Be 0
    }
}

Describe 'Source file <File.Name>' -ForEach $PublicFiles {
    It 'defines one function, named after the file' {
        Get-FunctionName $File.FullName | Should -Be @($File.BaseName)
    }
}

Describe 'Private file <File.Name>' -ForEach $PrivateFiles {
    It 'defines one function, named after the file' {
        Get-FunctionName $File.FullName | Should -Be @($File.BaseName)
    }

    It 'uses an approved verb and the Msal noun prefix' {
        $Verb, $Noun = $File.BaseName -split '-', 2
        (Get-Verb).Verb | Should -Contain $Verb
        $Noun | Should -BeLike 'Msal*'
    }

    It 'is not exported' {
        $Module.ExportedFunctions.Keys | Should -Not -Contain $File.BaseName
    }
}

Describe 'Script file <File.Name>' -ForEach $ScriptFiles {
    It 'carries no upstream Authenticode signature block' {
        Get-Content -LiteralPath $File.FullName -Raw | Should -Not -Match '# SIG # Begin signature block'
    }
}

Describe 'Unit tests' {
    It 'name every public and private function in a test file of their own' {
        # The structural tests of this file and the documentation tests list every function
        # generically, so they do not count.
        $TestText = (Get-ChildItem -Path (Join-Path $ModuleRoot 'Tests') -Recurse -Filter '*.Tests.ps1' |
                Where-Object { $_.Name -notin 'Module.Tests.ps1', 'Documentation.Tests.ps1' } |
                ForEach-Object { [System.IO.File]::ReadAllText($_.FullName) }) -join "`n"
        $Untested = @(Get-ChildItem -Path (Join-Path $ModuleRoot 'Public'), (Join-Path $ModuleRoot 'Private') -Recurse -Filter '*.ps1' |
                Where-Object { $TestText -notmatch ('\b{0}\b' -f [regex]::Escape($_.BaseName)) } |
                ForEach-Object { $_.BaseName })
        $Untested | Should -BeNullOrEmpty -Because ('no test names these functions: {0}' -f ($Untested -join ', '))
    }
}
