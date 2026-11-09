<#
.SYNOPSIS
    Runs an MSAL request builder and returns its result; the only call to MSAL's ExecuteAsync.
.DESCRIPTION
    Waits for the request, writing the device code messages of DeviceCodeQueue meanwhile. A Timeout
    of zero waits without limit; when it runs out the request is cancelled, MSAL is given 5
    seconds to stop, and a TimeoutException is thrown. Otherwise it throws the MSAL exception
    itself (MsalUiRequiredException, MsalServiceException and the like) or a
    TaskCanceledException. Unit tests mock this function.
.EXAMPLE
    Invoke-MsalRequest $Request -Timeout (New-TimeSpan -Minutes 2)
    Runs the request, giving up after 2 minutes.
.OUTPUTS
    Microsoft.Identity.Client.AuthenticationResult
#>
function Invoke-MsalRequest {
    [CmdletBinding()]
    [OutputType([Microsoft.Identity.Client.AuthenticationResult])]
    param (
        # An MSAL request builder (AcquireToken*ParameterBuilder), ready to run.
        [Parameter(Mandatory = $true, Position = 0)]
        [object] $Request,
        # Zero waits without limit.
        [Parameter(Mandatory = $false)]
        [timespan] $Timeout = [timespan]::Zero,
        # Messages queued by the device-code callback, written to the information stream while waiting.
        [Parameter(Mandatory = $false)]
        [AllowNull()]
        [System.Collections.Concurrent.ConcurrentQueue[string]] $DeviceCodeQueue
    )

    ## The only call to MSAL's ExecuteAsync: unit tests mock this function. Returns the result, or
    ## throws the MSAL exception itself (MsalUiRequiredException, MsalServiceException, ...), a
    ## TimeoutException or a TaskCanceledException.
    $TokenSource = New-Object System.Threading.CancellationTokenSource
    $Task = $null
    try {
        $Task = $Request.ExecuteAsync($TokenSource.Token)
        $EndTime = [datetime]::Now.Add($Timeout)
        while (-not $Task.IsCompleted) {
            if ($DeviceCodeQueue) { Write-MsalDeviceCodeMessage $DeviceCodeQueue }
            if ($Timeout -ne [timespan]::Zero -and [datetime]::Now -ge $EndTime) {
                $TokenSource.Cancel()
                # MSAL ends a cancelled request quickly; do not wait on one that does not.
                try { [void] $Task.Wait([timespan]::FromSeconds(5)) }
                catch {
                    # The cancelled task always faults; the timeout is what the caller gets.
                    Write-Debug $_.Exception.Message
                }
                throw (New-Object System.TimeoutException ('The request did not complete within {0}.' -f $Timeout))
            }
            Start-Sleep -Milliseconds 250
        }
    }
    finally {
        if ($DeviceCodeQueue) { Write-MsalDeviceCodeMessage $DeviceCodeQueue }
        if (-not $Task -or -not $Task.IsCompleted) { $TokenSource.Cancel() }
        $TokenSource.Dispose()
    }

    if ($Task.IsFaulted) {
        $Exception = $Task.Exception
        while ($Exception -is [System.AggregateException] -and $Exception.InnerException) { $Exception = $Exception.InnerException }
        throw $Exception
    }
    if ($Task.IsCanceled) { throw (New-Object System.Threading.Tasks.TaskCanceledException $Task) }
    return $Task.Result
}
