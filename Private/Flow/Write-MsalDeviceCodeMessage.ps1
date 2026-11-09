<#
.SYNOPSIS
    Writes the device code messages queued by the callback to the information stream.
.DESCRIPTION
    Runs on the PowerShell thread. Write-Host is used, as the instructions are for the person at the
    console; it goes to the information stream, so callers can still capture it.
.EXAMPLE
    Write-MsalDeviceCodeMessage $DeviceCode.Queue
    Writes the messages queued so far.
.OUTPUTS
    None.
#>
function Write-MsalDeviceCodeMessage {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingWriteHost', '', Justification = 'The sign-in instructions are for the person at the console, as with upstream MSAL.PS; Write-Host goes to the information stream, which callers can still capture.')]
    [CmdletBinding()]
    param (
        # Queue filled by the callback of Get-MsalDeviceCodeCallback.
        [Parameter(Mandatory = $true, Position = 0)]
        [System.Collections.Concurrent.ConcurrentQueue[string]] $Queue
    )

    $Message = $null
    while ($Queue.TryDequeue([ref] $Message)) {
        Write-Host $Message
    }
}
