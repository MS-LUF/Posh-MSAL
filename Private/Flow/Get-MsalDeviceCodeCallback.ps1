<#
.SYNOPSIS
    Builds the device code callback and the queue it fills.
.DESCRIPTION
    MSAL invokes the callback on a thread-pool thread, where no runspace exists, so it is an
    expression tree, not a scriptblock. It only queues the message; Invoke-MsalRequest reads the
    queue on the PowerShell thread and writes the message with Write-MsalDeviceCodeMessage.

    The result has Callback, for Get-MsalDeviceCodeRequest, and Queue, for Invoke-MsalRequest.
.EXAMPLE
    $DeviceCode = Get-MsalDeviceCodeCallback
    Creates the callback and its queue.
.OUTPUTS
    System.Management.Automation.PSCustomObject
#>
function Get-MsalDeviceCodeCallback {
    [CmdletBinding()]
    [OutputType([psobject])]
    param ()

    ## MSAL invokes the device-code callback on a thread-pool thread, where no runspace exists, so it
    ## is built as an expression tree, not a scriptblock. It only queues the message; the caller
    ## reads the queue on its own thread and shows the message.
    $Queue = New-Object 'System.Collections.Concurrent.ConcurrentQueue[string]'
    $Expression = [System.Linq.Expressions.Expression]
    $ResultParameter = $Expression::Parameter([Microsoft.Identity.Client.DeviceCodeResult], 'result')
    $Enqueue = $Expression::Call($Expression::Constant($Queue), $Queue.GetType().GetMethod('Enqueue'), $Expression::Property($ResultParameter, 'Message'))
    $Completed = $Expression::Property($null, [System.Threading.Tasks.Task].GetProperty('CompletedTask'))
    $Body = $Expression::Block([System.Threading.Tasks.Task], [System.Linq.Expressions.Expression[]] @($Enqueue, $Completed))
    $Callback = $Expression::Lambda([System.Func[Microsoft.Identity.Client.DeviceCodeResult, System.Threading.Tasks.Task]], $Body, [System.Linq.Expressions.ParameterExpression[]] @($ResultParameter)).Compile()

    [PSCustomObject] @{
        Callback = $Callback
        Queue    = $Queue
    }
}
