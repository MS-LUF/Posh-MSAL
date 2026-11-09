<#
.SYNOPSIS
    Builds the interactive sign-in request of a public client.
.DESCRIPTION
    On Windows the sign-in window, and the broker, attach to the parent process's window, as a
    console host has none of its own; finding it is best effort. Prompt is the name of a
    Microsoft.Identity.Client.Prompt field. UseEmbeddedWebView is true or false when the caller
    chose, or null to leave MSAL's default.
.EXAMPLE
    Get-MsalInteractiveRequest $Application -Scopes 'https://graph.microsoft.com/User.Read' -LoginHint 'user@contoso.com' -Prompt 'SelectAccount'
    Builds the request, with the account picker and the user name filled in.
.OUTPUTS
    Microsoft.Identity.Client.AcquireTokenInteractiveParameterBuilder
#>
function Get-MsalInteractiveRequest {
    [CmdletBinding()]
    [OutputType([Microsoft.Identity.Client.AcquireTokenInteractiveParameterBuilder])]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [Microsoft.Identity.Client.IPublicClientApplication] $Application,
        [Parameter(Mandatory = $true)]
        [string[]] $Scopes,
        [Parameter(Mandatory = $false)]
        [string[]] $ExtraScopesToConsent,
        [Parameter(Mandatory = $false)]
        [string] $LoginHint,
        # Name of a Microsoft.Identity.Client.Prompt field, e.g. SelectAccount.
        [Parameter(Mandatory = $false)]
        [string] $Prompt,
        # $true or $false when the caller chose; $null leaves MSAL's default.
        [Parameter(Mandatory = $false)]
        [AllowNull()]
        [object] $UseEmbeddedWebView
    )

    $Request = $Application.AcquireTokenInteractive($Scopes)
    ## The sign-in window (and the broker) attaches to a window; a console host has none of its
    ## own, so on Windows the parent process's window is used.
    [IntPtr] $ParentWindow = [System.Diagnostics.Process]::GetCurrentProcess().MainWindowHandle
    if ($ParentWindow -eq [System.IntPtr]::Zero -and $script:ModuleState.OSPlatform -eq 'Windows') {
        # Best effort: without a parent window the sign-in window still opens, unattached.
        try {
            $Win32Process = Get-CimInstance Win32_Process -Filter ("ProcessId = '{0}'" -f [System.Diagnostics.Process]::GetCurrentProcess().Id) -Verbose:$false -ErrorAction Stop
            $ParentWindow = (Get-Process -Id $Win32Process.ParentProcessId -ErrorAction Stop).MainWindowHandle
        }
        catch {
            Write-Debug ('No parent window for the sign-in window: {0}' -f $_.Exception.Message)
        }
    }
    if ($ParentWindow -ne [System.IntPtr]::Zero) { [void] $Request.WithParentActivityOrWindow($ParentWindow) }
    if ($ExtraScopesToConsent) { [void] $Request.WithExtraScopesToConsent($ExtraScopesToConsent) }
    if ($LoginHint) { [void] $Request.WithLoginHint($LoginHint) }
    if ($Prompt) { [void] $Request.WithPrompt([Microsoft.Identity.Client.Prompt]::$Prompt) }
    if ($null -ne $UseEmbeddedWebView) { [void] $Request.WithUseEmbeddedWebView([bool] $UseEmbeddedWebView) }
    return $Request
}
