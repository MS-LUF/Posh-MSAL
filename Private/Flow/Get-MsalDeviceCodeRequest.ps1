<#
.SYNOPSIS
    Builds the device code request of a public client.
.EXAMPLE
    Get-MsalDeviceCodeRequest $Application -Scopes 'https://graph.microsoft.com/User.Read' -Callback $DeviceCode.Callback
    Builds the request with the callback of Get-MsalDeviceCodeCallback.
.OUTPUTS
    Microsoft.Identity.Client.AcquireTokenWithDeviceCodeParameterBuilder
#>
function Get-MsalDeviceCodeRequest {
    [CmdletBinding()]
    [OutputType([Microsoft.Identity.Client.AcquireTokenWithDeviceCodeParameterBuilder])]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [Microsoft.Identity.Client.IPublicClientApplication] $Application,
        [Parameter(Mandatory = $true)]
        [string[]] $Scopes,
        # Func<DeviceCodeResult, Task> from Get-MsalDeviceCodeCallback.
        [Parameter(Mandatory = $true)]
        [System.Func[Microsoft.Identity.Client.DeviceCodeResult, System.Threading.Tasks.Task]] $Callback
    )

    return $Application.AcquireTokenWithDeviceCode($Scopes, $Callback)
}
