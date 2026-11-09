---
Module Name: Posh-MSAL
Module Guid: 49ae6c7d-af32-4e74-bc17-66d57d5f41fb
Download Help Link:
Help Version: 5.0.0.0
Locale: en-US
---

# Posh-MSAL Module
## Description
PowerShell cmdlets wrapping MSAL.NET (Microsoft.Identity.Client) to acquire tokens from Microsoft Entra ID in the public and sovereign clouds.

## Posh-MSAL Cmdlets
### [Add-MsalClientApplication](Add-MsalClientApplication.md)
Adds a client application to the applications kept for the session.

### [Add-MsalEnvironment](Add-MsalEnvironment.md)
Adds a user-defined cloud (environment).

### [Clear-MsalTokenCache](Clear-MsalTokenCache.md)
Forgets the client applications kept for the session, or deletes the token cache on disk.

### [Enable-MsalTokenCacheOnDisk](Enable-MsalTokenCacheOnDisk.md)
Makes a client application keep its tokens on disk, encrypted, across sessions.

### [Get-MsalAccount](Get-MsalAccount.md)
Gets the accounts in the token cache of a client application.

### [Get-MsalClientApplication](Get-MsalClientApplication.md)
Gets the client applications kept for the session.

### [Get-MsalEnvironment](Get-MsalEnvironment.md)
Gets the clouds (environments) Posh-MSAL can sign in to.

### [Get-MsalFeatureSupport](Get-MsalFeatureSupport.md)
Shows what works on this machine and which MSAL.NET version is loaded.

### [Get-MsalToken](Get-MsalToken.md)
Gets an OAuth token from Microsoft Entra ID, in the public cloud or a sovereign cloud.

### [New-MsalClientApplication](New-MsalClientApplication.md)
Builds a public or confidential client application for one cloud and tenant.

### [Remove-MsalClientApplication](Remove-MsalClientApplication.md)
Removes a client application from the applications kept for the session.

### [Remove-MsalEnvironment](Remove-MsalEnvironment.md)
Removes a user-defined cloud (environment).

### [Select-MsalClientApplication](Select-MsalClientApplication.md)
Returns the session's client application for these settings, creating and keeping one if there is none.

### [Set-MsalEnvironment](Set-MsalEnvironment.md)
Changes a user-defined cloud (environment).
