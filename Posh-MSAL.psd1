@{
RootModule = 'Posh-MSAL.psm1'
ModuleVersion = '5.0.0'
CompatiblePSEditions = 'Core', 'Desktop'
GUID = '49ae6c7d-af32-4e74-bc17-66d57d5f41fb'
Author = 'MS-LUF'
CompanyName = 'lucas-cueff.com'
Copyright = '(c) 2026 Lucas Cueff. Based on MSAL.PS, (c) 2021 Jason Thompson, MIT License.'
Description = 'PowerShell cmdlets wrapping MSAL.NET (Microsoft.Identity.Client) to acquire tokens from Microsoft Entra ID in the public and sovereign clouds.'
PowerShellVersion = '5.1'
DotNetFrameworkVersion = '4.7.2'
FunctionsToExport = @(
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
CmdletsToExport = @()
VariablesToExport = @()
AliasesToExport = @()
PrivateData = @{
    PSData = @{
        Tags = 'MSAL', 'Microsoft.Identity.Client', 'EntraID', 'AzureAD', 'SovereignCloud', 'BleuCloud', 'PSEdition_Desktop', 'PSEdition_Core', 'Windows', 'Linux'
        LicenseUri = 'https://raw.githubusercontent.com/MS-LUF/Posh-MSAL/refs/heads/main/License.txt'
        ProjectUri = 'https://github.com/MS-LUF/Posh-MSAL'
        ReleaseNotes = '5.0.0: first Posh-MSAL release: MSAL.NET 4.92, Linux, public and sovereign clouds (-Environment, *-MsalEnvironment), encrypted token cache on disk on Windows and Linux.'
    }
}
}
