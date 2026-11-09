BeforeAll {
    $ModuleRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
    Import-Module (Join-Path $ModuleRoot 'Posh-MSAL.psd1') -Force -ErrorAction Stop
}

AfterAll {
    Remove-Module Posh-MSAL -ErrorAction SilentlyContinue
}

Describe 'Get-MsalDeviceCodeCallback' {
    It 'queues the device-code message when MSAL calls it from a thread-pool thread' {
        InModuleScope Posh-MSAL {
            $DeviceCode = Get-MsalDeviceCodeCallback
            # DeviceCodeResult(userCode, deviceCode, verificationUrl, expiresOn, interval, message, clientId, scopes).
            $Constructor = [Microsoft.Identity.Client.DeviceCodeResult].GetConstructors([System.Reflection.BindingFlags] 'Instance,NonPublic,Public') | Sort-Object { $_.GetParameters().Count } -Descending | Select-Object -First 1
            $Result = $Constructor.Invoke([object[]] @('CODE', 'device', 'https://microsoft.com/devicelogin', [System.DateTimeOffset]::Now.AddMinutes(15), [long] 5, 'Sign in with CODE', 'client', [System.Collections.Generic.HashSet[string]]::new()))
            # The call is made from the thread pool through an expression tree, as MSAL does: no runspace there.
            $Invoke = [System.Linq.Expressions.Expression]::Invoke([System.Linq.Expressions.Expression]::Constant($DeviceCode.Callback), [System.Linq.Expressions.Expression]::Constant($Result))
            $OnThreadPool = [System.Linq.Expressions.Expression]::Lambda([System.Func[System.Threading.Tasks.Task]], $Invoke).Compile()
            [System.Threading.Tasks.Task]::Run($OnThreadPool).Wait()

            $Message = $null
            $DeviceCode.Queue.TryDequeue([ref] $Message) | Should -BeTrue
            $Message | Should -Be 'Sign in with CODE'
        }
    }
}

Describe 'Write-MsalDeviceCodeMessage' {
    It 'writes every queued message to the information stream and empties the queue' {
        InModuleScope Posh-MSAL {
            $Queue = New-Object 'System.Collections.Concurrent.ConcurrentQueue[string]'
            $Queue.Enqueue('first')
            $Queue.Enqueue('second')
            $Output = Write-MsalDeviceCodeMessage $Queue 6>&1
            @($Output | ForEach-Object { "$_" }) | Should -Be @('first', 'second')
            $Queue.IsEmpty | Should -BeTrue
        }
    }
}

Describe 'Register-MsalAssemblyResolver' {
    It 'answers a request for an older version with the DLL of lib/ (Windows PowerShell)' -Skip:($PSVersionTable.PSEdition -ne 'Desktop') {
        $Requested = 'System.Memory, Version=4.0.1.1, Culture=neutral, PublicKeyToken=cc7b13ffcd2ddd51'
        $Assembly = [System.Reflection.Assembly]::Load($Requested)
        $Assembly.Location | Should -BeLike (Join-Path (Join-Path $ModuleRoot 'lib') '*')
    }

    It 'registers its handler once per folder' -Skip:($PSVersionTable.PSEdition -ne 'Desktop') {
        InModuleScope Posh-MSAL -Parameters @{ LibPath = Join-Path (Join-Path $ModuleRoot 'lib') 'net472' } {
            param ($LibPath)
            [System.AppDomain]::CurrentDomain.GetData("Posh-MSAL.AssemblyResolver:$LibPath") | Should -BeTrue
            { Register-MsalAssemblyResolver -Path $LibPath } | Should -Not -Throw
        }
    }
}
