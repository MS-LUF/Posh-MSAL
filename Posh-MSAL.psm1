param (
    # Provide module configuration
    [Parameter(Mandatory = $false)]
    [psobject] $ModuleConfiguration
)

## Set Strict Mode for Module. https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/set-strictmode
Set-StrictMode -Version 3.0

$script:ModuleRoot = $PSScriptRoot

## Load functions: private helpers first, then the exported cmdlets.
foreach ($FunctionFile in @(Get-ChildItem -Path (Join-Path $PSScriptRoot 'Private') -Filter '*.ps1' -Recurse) + @(Get-ChildItem -Path (Join-Path $PSScriptRoot 'Public') -Filter '*.ps1')) {
    . $FunctionFile.FullName
}

## Platform facts and per-user folders. Tests point the folders elsewhere through $script:ModuleState.
$OSPlatform = 'Other'
if ([System.Runtime.InteropServices.RuntimeInformation]::IsOSPlatform([System.Runtime.InteropServices.OSPlatform]::Windows)) { $OSPlatform = 'Windows' }
elseif ([System.Runtime.InteropServices.RuntimeInformation]::IsOSPlatform([System.Runtime.InteropServices.OSPlatform]::Linux)) { $OSPlatform = 'Linux' }
$LocalAppData = [System.Environment]::GetFolderPath([System.Environment+SpecialFolder]::LocalApplicationData)
$script:ModuleState = @{
    OSPlatform           = $OSPlatform
    AssemblyConflicts    = New-Object System.Collections.Generic.List[string]
    ConfigDirectory      = Join-Path ([System.Environment]::GetFolderPath([System.Environment+SpecialFolder]::ApplicationData)) 'Posh-MSAL'
    TokenCacheDirectory  = Join-Path $LocalAppData 'Posh-MSAL'
    # Upstream MSAL.PS cache (Windows, DPAPI), migrated once into the new user token cache.
    LegacyTokenCachePath = Join-Path (Join-Path $LocalAppData 'MSAL.PS') 'MSAL.PS.msalcache.bin3'
    # One MsalCacheHelper per store for the session, created by Get-MsalCacheHelper.
    TokenCacheHelpers    = @{}
    # Built-in and user-defined environments, loaded once MSAL is.
    Environments         = $null
}
Remove-Variable OSPlatform, LocalAppData

$script:ModuleConfigDefault = Import-MsalConfig -Path (Join-Path $PSScriptRoot 'config.json')
$script:ModuleConfig = $script:ModuleConfigDefault.psobject.Copy()
Import-MsalConfig | Set-MsalConfig
Set-MsalConfig -ResolveFromEnvironmentVariables
if ($PSBoundParameters.ContainsKey('ModuleConfiguration')) { Set-MsalConfig $ModuleConfiguration }

Import-MsalAssembly
$script:ModuleState.EnvironmentFile = Join-Path $script:ModuleState.ConfigDirectory 'environments.json'
$script:ModuleState.Environments = [System.Collections.Generic.List[psobject]] @(Import-MsalEnvironment)

$script:ModuleFeatureSupport = [ordered]@{
    # MSAL's legacy embedded browser only exists in its .NET Framework build.
    EmbeddedWebViewSupport = $PSVersionTable.PSEdition -eq 'Desktop'
    DeviceCodeSupport      = $true
    # Extensions.Msal: DPAPI on Windows, libsecret on Linux (the keyring itself is checked when the cache is enabled).
    TokenCacheSupport      = $script:ModuleState.OSPlatform -in 'Windows', 'Linux' -and $null -ne ('Microsoft.Identity.Client.Extensions.Msal.MsalCacheHelper' -as [type])
    AuthBrokerSupport      = $script:ModuleState.OSPlatform -eq 'Windows'
    MsalVersion            = [Microsoft.Identity.Client.PublicClientApplication].Assembly.GetName().Version.ToString()
    AssemblyConflicts      = @($script:ModuleState.AssemblyConflicts)
}

## Session state
[System.Collections.Generic.List[Microsoft.Identity.Client.IPublicClientApplication]] $script:PublicClientApplications = New-Object 'System.Collections.Generic.List[Microsoft.Identity.Client.IPublicClientApplication]'
[System.Collections.Generic.List[Microsoft.Identity.Client.IConfidentialClientApplication]] $script:ConfidentialClientApplications = New-Object 'System.Collections.Generic.List[Microsoft.Identity.Client.IConfidentialClientApplication]'

Export-ModuleMember -Function @(
    'Add-MsalClientApplication'
    'Add-MsalEnvironment'
    'Clear-MsalTokenCache'
    'Enable-MsalTokenCacheOnDisk'
    'Get-MsalAccount'
    'Get-MsalClientApplication'
    'Get-MsalEnvironment'
    'Get-MsalFeatureSupport'
    'Get-MsalToken'
    'New-MsalClientApplication'
    'Remove-MsalClientApplication'
    'Remove-MsalEnvironment'
    'Select-MsalClientApplication'
    'Set-MsalEnvironment'
)
