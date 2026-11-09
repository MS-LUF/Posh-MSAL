[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '', Justification = 'Variables set in BeforeDiscovery and BeforeAll are read by the It blocks.')]
param ()

BeforeDiscovery {
    $ModuleRoot = Split-Path -Parent $PSScriptRoot
    $PublicCases = @(Get-ChildItem -Path (Join-Path $ModuleRoot 'Public') -Filter '*.ps1' | ForEach-Object { @{ Name = $_.BaseName } })
    $PrivateCases = @(Get-ChildItem -Path (Join-Path $ModuleRoot 'Private') -Filter '*.ps1' -Recurse | ForEach-Object { @{ Name = $_.BaseName } })
    $ExportedCases = @((Import-PowerShellDataFile -Path (Join-Path $ModuleRoot 'Posh-MSAL.psd1')).FunctionsToExport | Sort-Object)
}

BeforeAll {
    $ModuleRoot = Split-Path -Parent $PSScriptRoot
    Import-Module (Join-Path $ModuleRoot 'Posh-MSAL.psd1') -Force -ErrorAction Stop
}

AfterAll {
    Remove-Module Posh-MSAL -ErrorAction SilentlyContinue
}

Describe 'Internal design documents' {
    It 'are not referenced from any other file' {
        # They are for people working on this repository: code, help, the manifest and the user
        # documentation must stand on their own. The names are assembled so that this file does not
        # match its own search.
        $InternalNames = @(('Archi' + 'tecture.md'), ('CLAU' + 'DE.md'))
        $Root = (Resolve-Path $ModuleRoot).Path
        $Offenders = Get-ChildItem -Path $Root -Recurse -File -Include '*.ps1', '*.psm1', '*.psd1', '*.json', '*.md', '*.txt', '*.yml', '*.csproj', '*.cs' |
            Where-Object { $_.FullName.Substring($Root.Length) -notmatch '^[\\/](\.git|lib)[\\/]' -and $InternalNames -notcontains $_.Name } |
            Where-Object {
                $Content = [System.IO.File]::ReadAllText($_.FullName)
                @($InternalNames | Where-Object { $Content.IndexOf($_, [System.StringComparison]::OrdinalIgnoreCase) -ge 0 }).Count -gt 0
            } |
            ForEach-Object { $_.FullName.Substring($Root.Length).TrimStart('\', '/') }
        $Offenders | Should -BeNullOrEmpty -Because ('these files mention an internal design document: {0}' -f ($Offenders -join ', '))
    }
}

Describe 'User documentation' {
    It 'has a README and a HowTo' {
        Join-Path $ModuleRoot 'README.md' | Should -Exist
        Join-Path $ModuleRoot 'HowTo.md' | Should -Exist
    }

    It 'lists every exported cmdlet in the README' {
        $Readme = Get-Content -LiteralPath (Join-Path $ModuleRoot 'README.md') -Raw
        $Missing = @((Get-Module Posh-MSAL).ExportedFunctions.Keys | Where-Object {
                # A row may group cmdlets of one noun: "Add-MsalEnvironment / Set- / Remove-".
                $Verb, $Noun = $_ -split '-', 2
                $Readme -notmatch [regex]::Escape($_) -and $Readme -notmatch ('`{0}-`[^\r\n]*{1}|{1}`[^\r\n]*`{0}-`' -f [regex]::Escape($Verb), [regex]::Escape($Noun))
            })
        $Missing | Should -BeNullOrEmpty
    }

    It 'keeps the manifest release notes to one line' {
        $Notes = (Import-PowerShellDataFile -Path (Join-Path $ModuleRoot 'Posh-MSAL.psd1')).PrivateData.PSData.ReleaseNotes
        $Notes | Should -Not -Match '\n'
        $Notes | Should -BeLike ('{0}:*' -f (Get-Module Posh-MSAL).Version.ToString(3))
    }
}

Describe 'Comment-based help of <Name>' -ForEach $PublicCases {
    BeforeAll {
        # A help line starting with a dot-prefixed word (".NET", ".default") is read as an unknown
        # keyword and silently drops the whole block: GetHelpContent then returns nothing.
        $Help = (Get-Command -Name $Name).ScriptBlock.Ast.GetHelpContent()
    }

    It 'is recognised by PowerShell, with a synopsis, a description and an example' {
        $Help | Should -Not -BeNullOrEmpty
        $Help.Synopsis | Should -Not -BeNullOrEmpty
        $Help.Description | Should -Not -BeNullOrEmpty
        @($Help.Examples).Count | Should -BeGreaterThan 0
    }

    It 'gives its inputs and outputs, each on one line' {
        # The generated help turns every line of these sections into a separate type entry.
        foreach ($Section in @($Help.Inputs) + @($Help.Outputs)) { $Section.Trim() | Should -Not -Match '\n' }
        @($Help.Inputs).Count | Should -Be 1
        @($Help.Outputs).Count | Should -Be 1
    }

    It 'has one line of code per example' {
        # The generated help keeps only the first line of an example as code, the rest as its text;
        # so the second line must not look like a command.
        foreach ($Example in $Help.Examples) {
            $Lines = @($Example.Trim() -split '\r?\n')
            $Lines.Count | Should -BeGreaterThan 1 -Because 'an example says what it does under its code'
            $Lines[1].Trim() | Should -Not -Match '^(PS [^>]*>|\$|[A-Z][a-z]+-Msal)' -Because ('"{0}" should be one line of code' -f $Lines[0].Trim())
        }
    }

    It 'describes every parameter' {
        $Command = Get-Command -Name $Name
        $Common = [System.Management.Automation.PSCmdlet]::CommonParameters + [System.Management.Automation.PSCmdlet]::OptionalCommonParameters
        $Missing = @(Get-Help -Name $Name -Full | ForEach-Object { $_.parameters.parameter } |
                Where-Object { $Common -notcontains $_.name -and $Command.Parameters.ContainsKey($_.name) -and -not ($_.description | Out-String).Trim() } |
                ForEach-Object { $_.name })
        $Missing | Should -BeNullOrEmpty
    }
}

Describe 'Comment-based help of the private function <Name>' -ForEach $PrivateCases {
    It 'is recognised by PowerShell, with a synopsis and an example' {
        $Help = & (Get-Module Posh-MSAL) { param ($FunctionName) (Get-Command -Name $FunctionName).ScriptBlock.Ast.GetHelpContent() } $Name
        $Help | Should -Not -BeNullOrEmpty
        $Help.Synopsis | Should -Not -BeNullOrEmpty
        @($Help.Examples).Count | Should -BeGreaterThan 0
    }
}

Describe 'Generated help' {
    BeforeAll {
        $DocsPath = Join-Path $ModuleRoot 'Docs'
        $Module = Get-Module Posh-MSAL
        $Exported = @($Module.ExportedFunctions.Keys | Sort-Object)
    }

    It 'has a module page listing every exported cmdlet, for this version' {
        $Page = Get-Content -LiteralPath (Join-Path $DocsPath 'Posh-MSAL.md') -Raw
        $Page | Should -Match ('(?m)^Help Version: {0}\.0\s*$' -f [regex]::Escape($Module.Version.ToString(3)))
        $Page | Should -Match ('(?m)^Module Guid: {0}\s*$' -f $Module.Guid)
        foreach ($Name in $Exported) { $Page | Should -Match ('(?m)^### \[{0}\]\({0}\.md\)\r?\n{1}\s*$' -f $Name, [regex]::Escape((Get-Help $Name).Synopsis)) }
    }

    It 'has no page left to fill in or for a cmdlet that no longer exists' {
        $Pages = @(Get-ChildItem -LiteralPath $DocsPath -Filter '*.md' | Where-Object BaseName -ne 'Posh-MSAL')
        @($Pages.BaseName | Sort-Object) | Should -Be $Exported
        $Pages | Select-String -Pattern '{{' -SimpleMatch | Should -BeNullOrEmpty
    }

    It 'matches the comment-based help of <_>' -ForEach $ExportedCases {
        # Fails when a cmdlet's help or parameters changed without regenerating Docs and en-US.
        $Page = Get-Content -LiteralPath (Join-Path (Join-Path $ModuleRoot 'Docs') ('{0}.md' -f $_)) -Raw
        $Synopsis = [regex]::Match($Page, '(?s)## SYNOPSIS\r?\n(.*?)\r?\n\r?\n## ').Groups[1].Value
        ($Synopsis -replace '\s+', ' ').Trim() | Should -Be ((Get-Help $_).Synopsis -replace '\s+', ' ').Trim()
        $Command = Get-Command $_
        $Common = [System.Management.Automation.PSCmdlet]::CommonParameters + [System.Management.Automation.PSCmdlet]::OptionalCommonParameters
        $Documented = @([regex]::Matches($Page, '(?m)^### -(\w+)\s*$') | ForEach-Object { $_.Groups[1].Value } | Where-Object { $Common -notcontains $_ } | Sort-Object)
        $Documented | Should -Be @($Command.Parameters.Keys | Where-Object { $Common -notcontains $_ } | Sort-Object)
    }

    It 'has the external help file with every exported cmdlet' {
        [xml] $Xml = Get-Content -LiteralPath (Join-Path (Join-Path $ModuleRoot 'en-US') 'Posh-MSAL-help.xml') -Raw
        $Names = @($Xml.helpItems.command | ForEach-Object { $_.details.name.Trim() } | Sort-Object)
        $Names | Should -Be $Exported
    }
}
