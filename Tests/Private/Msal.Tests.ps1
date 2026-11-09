[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '', Justification = 'Variables set in BeforeAll are read by the It blocks.')]
param ()

BeforeAll {
    $ModuleRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
    Import-Module (Join-Path $ModuleRoot 'Posh-MSAL.psd1') -Force -ErrorAction Stop

    # A stand-in for an MSAL request builder: ExecuteAsync returns the task given, and keeps the
    # cancellation token it received.
    function Get-TestRequest ([System.Threading.Tasks.Task] $Task) {
        $State = @{ Task = $Task; Token = $null }
        $Request = [PSCustomObject] @{ State = $State }
        $Request | Add-Member -MemberType ScriptMethod -Name ExecuteAsync -Value ({ param ($Token) $State.Token = $Token; $State.Task }.GetNewClosure())
        $Request
    }
}

AfterAll {
    Remove-Module Posh-MSAL -ErrorAction SilentlyContinue
}

Describe 'Invoke-MsalRequest' {
    It 'returns the result of a completed request' {
        $Request = Get-TestRequest ([System.Threading.Tasks.Task]::FromResult([object] 'the-result'))
        InModuleScope Posh-MSAL -Parameters @{ Request = $Request } { param ($Request) Invoke-MsalRequest $Request } | Should -Be 'the-result'
    }

    It 'throws the MSAL exception itself, not an AggregateException' {
        $Source = New-Object 'System.Threading.Tasks.TaskCompletionSource[object]'
        $Source.SetException((New-Object Microsoft.Identity.Client.MsalUiRequiredException ('code', 'sign-in needed')))
        $Request = Get-TestRequest $Source.Task
        { InModuleScope Posh-MSAL -Parameters @{ Request = $Request } { param ($Request) Invoke-MsalRequest $Request } } | Should -Throw -ExceptionType ([Microsoft.Identity.Client.MsalUiRequiredException]) -ExpectedMessage 'sign-in needed'
    }

    It 'throws TaskCanceledException for a cancelled request' {
        $Source = New-Object 'System.Threading.Tasks.TaskCompletionSource[object]'
        $Source.SetCanceled()
        $Request = Get-TestRequest $Source.Task
        { InModuleScope Posh-MSAL -Parameters @{ Request = $Request } { param ($Request) Invoke-MsalRequest $Request } } | Should -Throw -ExceptionType ([System.Threading.Tasks.TaskCanceledException])
    }

    It 'gives up after -Timeout, cancels the request and throws TimeoutException' {
        $Source = New-Object 'System.Threading.Tasks.TaskCompletionSource[object]'
        # A task that never completes, even when cancelled: the wait must still end.
        $Request = Get-TestRequest $Source.Task
        $Watch = [System.Diagnostics.Stopwatch]::StartNew()
        $Thrown = $null
        try {
            InModuleScope Posh-MSAL -Parameters @{ Request = $Request } { param ($Request) Invoke-MsalRequest $Request -Timeout ([timespan]::FromMilliseconds(300)) }
        }
        catch { $Thrown = $_.Exception }
        $Watch.Stop()
        $Thrown | Should -BeOfType ([System.TimeoutException])
        $Request.State.Token.IsCancellationRequested | Should -BeTrue
        $Watch.Elapsed.TotalSeconds | Should -BeLessThan 10
    }

    It 'writes the queued device-code messages to the information stream' {
        $Queue = New-Object 'System.Collections.Concurrent.ConcurrentQueue[string]'
        $Queue.Enqueue('To sign in, enter CODE')
        $Request = Get-TestRequest ([System.Threading.Tasks.Task]::FromResult([object] 'done'))
        $Output = InModuleScope Posh-MSAL -Parameters @{ Request = $Request; Queue = $Queue } { param ($Request, $Queue) Invoke-MsalRequest $Request -DeviceCodeQueue $Queue 6>&1 }
        @($Output | ForEach-Object { "$_" }) | Should -Be @('To sign in, enter CODE', 'done')
    }
}
