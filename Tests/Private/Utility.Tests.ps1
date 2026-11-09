[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '', Justification = 'Variables set in BeforeAll / BeforeEach are read by the It blocks.')]
param ()

BeforeAll {
    $ModuleRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
    $ManifestPath = Join-Path $ModuleRoot 'Posh-MSAL.psd1'
    Import-Module $ManifestPath -Force -ErrorAction Stop
}

AfterAll {
    Remove-Module Posh-MSAL -ErrorAction SilentlyContinue
}

Describe 'Select-MsalBoundParameter' {
    It 'keeps only the parameters of the command, its parameter set, and not the excluded ones' {
        InModuleScope Posh-MSAL {
            $Bound = @{ ClientId = 'id'; Interactive = $true; NotAParameter = 1; Verbose = $true }
            $All = Select-MsalBoundParameter $Bound -CommandName Get-MsalToken
            @($All.Keys | Sort-Object) | Should -Be @('ClientId', 'Interactive', 'Verbose')
            $Set = Select-MsalBoundParameter $Bound -CommandName Select-MsalClientApplication -CommandParameterSets 'PublicClient'
            @($Set.Keys | Sort-Object) | Should -Be @('ClientId', 'Verbose')
            $Excluded = Select-MsalBoundParameter $Bound -CommandName Get-MsalToken -ExcludeParameters Verbose
            @($Excluded.Keys | Sort-Object) | Should -Be @('ClientId', 'Interactive')
            $Bound.Count | Should -Be 4
        }
    }
}

Describe 'ConvertTo-MsalDictionary' {
    It 'turns each hashtable into a typed dictionary' {
        InModuleScope Posh-MSAL {
            $Result = @(@{ a = '1' }, @{ b = '2'; c = '3' } | ConvertTo-MsalDictionary -KeyType ([string]) -ValueType ([string]))
            $Result | Should -HaveCount 2
            $Result[0] | Should -BeOfType ([System.Collections.Generic.Dictionary[string, string]])
            $Result[1]['c'] | Should -Be '3'
        }
    }
}

Describe 'ConvertFrom-MsalSecureString' {
    It 'returns the plain text of each secure string piped in' {
        InModuleScope Posh-MSAL {
            $Strings = foreach ($Text in 'first', 'second') {
                $Secure = New-Object System.Security.SecureString
                foreach ($Char in $Text.ToCharArray()) { $Secure.AppendChar($Char) }
                $Secure
            }
            @($Strings | ConvertFrom-MsalSecureString -Force) | Should -Be @('first', 'second')
        }
    }
}

Describe 'Get-MsalObjectPropertyValue' {
    It 'reads <Case>' -ForEach @(
        @{ Case = 'an object property'; InputObject = [PSCustomObject] @{ title = 'value' }; Property = @('title'); Expected = 'value' }
        @{ Case = 'a hashtable key'; InputObject = @{ title = 'value' }; Property = @('title'); Expected = 'value' }
        @{ Case = 'a nested property'; InputObject = [PSCustomObject] @{ outer = [PSCustomObject] @{ inner = 'deep' } }; Property = @('outer', 'inner'); Expected = 'deep' }
        @{ Case = 'a missing property as null'; InputObject = @{ title = 'value' }; Property = @('other'); Expected = $null }
    ) {
        InModuleScope Posh-MSAL -Parameters @{ InputObject = $InputObject; Property = $Property } {
            param ($InputObject, $Property)
            Get-MsalObjectPropertyValue $InputObject -Property $Property
        } | Should -Be $Expected
    }
}

Describe 'Assert-MsalDirectory' {
    BeforeEach {
        $Root = Join-Path ([System.IO.Path]::GetTempPath()) ('posh-msal-dir-' + [guid]::NewGuid().Guid.Substring(0, 8))
    }
    AfterEach {
        Remove-Item -LiteralPath $Root -Recurse -Force -ErrorAction SilentlyContinue
    }

    It 'creates missing folders, relative ones under -BaseDirectory, and returns only those it created' {
        [void] (New-Item -ItemType Directory -Path $Root)
        $Created = InModuleScope Posh-MSAL -Parameters @{ Root = $Root } {
            param ($Root)
            Assert-MsalDirectory @((Join-Path $Root 'absolute'), 'relative', (New-Object System.IO.FileInfo (Join-Path $Root 'forfile/file.txt'))) -BaseDirectory $Root
        }
        @($Created | ForEach-Object Name | Sort-Object) | Should -Be @('absolute', 'forfile', 'relative')
        Join-Path $Root 'relative' | Should -Exist
        @(InModuleScope Posh-MSAL -Parameters @{ Root = $Root } { param ($Root) Assert-MsalDirectory (Join-Path $Root 'absolute') }) | Should -HaveCount 0
    }
}

Describe 'Module configuration' {
    BeforeEach {
        $Folder = Join-Path ([System.IO.Path]::GetTempPath()) ('posh-msal-config-' + [guid]::NewGuid().Guid.Substring(0, 8))
        $Saved = InModuleScope Posh-MSAL -Parameters @{ Folder = $Folder } {
            param ($Folder)
            $Previous = @{ Directory = $script:ModuleState.ConfigDirectory; Config = $script:ModuleConfig.psobject.Copy() }
            $script:ModuleState.ConfigDirectory = $Folder
            $Previous
        }
    }
    AfterEach {
        InModuleScope Posh-MSAL -Parameters @{ Saved = $Saved } {
            param ($Saved)
            $script:ModuleState.ConfigDirectory = $Saved.Directory
            $script:ModuleConfig = $Saved.Config
        }
        Remove-Item -LiteralPath $Folder -Recurse -Force -ErrorAction SilentlyContinue
    }

    It 'Export-MsalConfig writes only what differs from the defaults, and Import-MsalConfig reads it back' {
        InModuleScope Posh-MSAL {
            $Config = $script:ModuleConfigDefault.psobject.Copy()
            $Config.'dll.lenientLoading' = $true
            Export-MsalConfig $Config
            $File = Join-Path $script:ModuleState.ConfigDirectory 'config.json'
            $File | Should -Exist
            @((Get-Content -LiteralPath $File -Raw | ConvertFrom-Json).psobject.Properties.Name) | Should -Be @('dll.lenientLoading')
            (Import-MsalConfig).'dll.lenientLoading' | Should -BeTrue
        }
    }

    It 'Import-MsalConfig returns nothing without a file' {
        InModuleScope Posh-MSAL { Import-MsalConfig } | Should -BeNullOrEmpty
    }

    It 'Set-MsalConfig takes an object, a hashtable or parameters, and warns about unknown settings' {
        InModuleScope Posh-MSAL {
            $Config = $script:ModuleConfigDefault.psobject.Copy()
            Set-MsalConfig @{ 'dll.lenientLoading' = $true; 'unknown.setting' = 1 } -OutConfig ([ref] $Config) -WarningVariable Warnings -WarningAction SilentlyContinue
            $Config.'dll.lenientLoading' | Should -BeTrue
            "$Warnings" | Should -BeLike '*unknown.setting*'
            Set-MsalConfig -DllLenientLoadingPrompt $false -OutConfig ([ref] $Config)
            $Config.'dll.lenientLoadingPrompt' | Should -BeFalse
        }
    }
}

Describe 'Assembly loading' {
    It 'Import-MsalAssembly can run again on a loaded module' {
        { InModuleScope Posh-MSAL { Import-MsalAssembly } } | Should -Not -Throw
    }

    It 'Find-MsalLoadedAssembly finds another version loaded from elsewhere, and nothing else' {
        InModuleScope Posh-MSAL {
            # System.Management.Automation is loaded from outside the module: a different version is a conflict.
            $Sma = [System.Management.Automation.PSObject].Assembly
            Find-MsalLoadedAssembly -Name 'System.Management.Automation' -Version '0.0.0.1' | Should -Be $Sma
            Find-MsalLoadedAssembly -Name 'System.Management.Automation' -Version $Sma.GetName().Version | Should -BeNullOrEmpty
            # The module's own MSAL.NET, whatever version is asked, is never a conflict.
            Find-MsalLoadedAssembly -Name 'Microsoft.Identity.Client' -Version '0.0.0.1' | Should -BeNullOrEmpty
            Find-MsalLoadedAssembly -Name 'Not.Loaded.Anywhere' -Version '1.0.0.0' | Should -BeNullOrEmpty
        }
    }

    It 'Resolve-MsalAssemblyLoadError <Case>' -ForEach @(
        @{ Case = 'rethrows when no assembly of that name is loaded'; Name = 'Not.Loaded.Anywhere.dll'; Lenient = $false; Expect = 'throw' }
        @{ Case = 'ignores an assembly the module loaded itself'; Name = 'Microsoft.Identity.Client.dll'; Lenient = $false; Expect = 'nothing' }
        @{ Case = 'rethrows on a conflict when lenient loading is off'; Name = 'System.Management.Automation.dll'; Lenient = $false; Expect = 'throw' }
        @{ Case = 'records a conflict when lenient loading is on'; Name = 'System.Management.Automation.dll'; Lenient = $true; Expect = 'conflict' }
    ) {
        InModuleScope Posh-MSAL -Parameters @{ Name = $Name; Lenient = $Lenient; Expect = $Expect } {
            param ($Name, $Lenient, $Expect)
            $SavedConfig = $script:ModuleConfig.psobject.Copy()
            $Before = $script:ModuleState.AssemblyConflicts.Count
            try {
                $script:ModuleConfig.'dll.lenientLoading' = $Lenient
                $script:ModuleConfig.'dll.lenientLoadingPrompt' = $false
                $Path = Join-Path ([System.IO.Path]::GetTempPath()) $Name
                $Result = $null
                $Thrown = $false
                try {
                    try { throw 'load failed' }
                    catch { $Result = Resolve-MsalAssemblyLoadError $Path -WarningAction SilentlyContinue }
                }
                catch { $Thrown = $true }
                switch ($Expect) {
                    'throw' { $Thrown | Should -BeTrue }
                    'nothing' { $Thrown | Should -BeFalse; $Result | Should -BeNullOrEmpty }
                    'conflict' {
                        $Thrown | Should -BeFalse
                        $Result | Should -Be ([System.Management.Automation.PSObject].Assembly.Location)
                        $script:ModuleState.AssemblyConflicts.Count | Should -Be ($Before + 1)
                    }
                }
            }
            finally {
                $script:ModuleConfig = $SavedConfig
                while ($script:ModuleState.AssemblyConflicts.Count -gt $Before) { $script:ModuleState.AssemblyConflicts.RemoveAt($script:ModuleState.AssemblyConflicts.Count - 1) }
            }
        }
    }
}

Describe 'Write-MsalHostPrompt' {
    It 'writes a non-terminating error instead of prompting when the session is not interactive' {
        # A child process started with -NonInteractive: a prompt there fails at once instead of waiting.
        $Executable = (Get-Process -Id $PID).Path
        $Script = "Import-Module '$ManifestPath'; & (Get-Module Posh-MSAL) { `$Answer = Write-MsalHostPrompt 'Caption' 'Message' -Choices '&Yes', '&No' -DefaultChoice 2 -ErrorAction SilentlyContinue -ErrorVariable Failed; 'answer=' + [string] `$Answer; 'errors=' + @(`$Failed).Count }"
        $Output = & $Executable -NoProfile -NonInteractive -Command $Script 2>&1
        # No answer, and the failure reported as an error rather than a prompt or a crash.
        "$Output" | Should -Match 'answer= errors=[1-9]'
    }
}
