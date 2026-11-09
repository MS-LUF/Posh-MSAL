# Posh-MSAL

PowerShell cmdlets to get OAuth tokens from Microsoft Entra ID, in the public cloud and in the sovereign clouds (US Government, China, Bleu, Delos, GovSG, and clouds you add yourself). It wraps MSAL.NET 4.92 (`Microsoft.Identity.Client`) and runs on Windows PowerShell 5.1 and on PowerShell 7.4 or later, on Windows and Linux.

It continues [MSAL.PS](https://github.com/AzureAD/MSAL.PS), archived at 4.37, with the same cmdlet names.

## Cmdlets

| Cmdlet | What it does |
|---|---|
| `Get-MsalToken` | Gets a token: client secret, certificate or assertion, authorization code, on-behalf-of, interactive, device code, broker (Windows), silent |
| `New-MsalClientApplication` | Builds a public or confidential client application for one cloud and tenant |
| `Select-MsalClientApplication` | Returns the session's application for these settings, creating it if needed |
| `Get-MsalClientApplication` / `Add-` / `Remove-` | Lists, adds or removes the applications kept for the session |
| `Get-MsalAccount` | Lists the accounts in an application's token cache |
| `Enable-MsalTokenCacheOnDisk` | Keeps an application's tokens on disk, encrypted, across sessions |
| `Clear-MsalTokenCache` | Forgets the session's applications, or deletes the token cache on disk |
| `Get-MsalEnvironment` | Lists the clouds you can sign in to |
| `Add-MsalEnvironment` / `Set-` / `Remove-` | Manages clouds you define yourself |
| `Get-MsalFeatureSupport` | Shows what works on this machine and which MSAL.NET version is loaded |

## Install

Clone the repository and import the manifest; the MSAL.NET libraries are included.
Or Install the module from PowerShell Gallery

```powershell
Install-Module Posh-MSAL
```

```powershell
Import-Module .\Posh-MSAL.psd1
```

## Quick start

```powershell
# An application token, with a client secret, in the public cloud
$Secret = Read-Host -AsSecureString -Prompt 'Client secret'
Get-MsalToken -ClientId $ClientId -TenantId $TenantId -ClientSecret $Secret

# The same in Bleu: the authority and the default scope follow the cloud
Get-MsalToken -ClientId $ClientId -TenantId $TenantId -ClientSecret $Secret -Environment BleuCloud

# A user token: browser (or embedded window on Windows PowerShell), then from the cache
Get-MsalToken -ClientId $ClientId -TenantId $TenantId -Interactive -Scopes 'https://graph.microsoft.com/User.Read'
Get-MsalToken -ClientId $ClientId -TenantId $TenantId -Silent -Scopes 'https://graph.microsoft.com/User.Read'

# On a machine with no browser
Get-MsalToken -ClientId $ClientId -TenantId $TenantId -DeviceCode

# Keep the tokens between sessions
Select-MsalClientApplication -ClientId $ClientId -TenantId $TenantId | Enable-MsalTokenCacheOnDisk

# The clouds available
Get-MsalEnvironment
```

[HowTo.md](HowTo.md) walks through every feature with real output. `Get-Help <cmdlet> -Full`, or the pages in [Docs](Docs/Posh-MSAL.md), has the parameter reference.

## Good to know

- **You need your own app registration.** There is no default client id: the sovereign clouds have no Microsoft public application to borrow.
- **The cloud decides the defaults.** Without `-Scopes`, the scope is the Graph `.default` of the cloud (`https://graph.svc.sovcloud.fr/.default` in Bleu). `-Authority`, `-Environment` and `-AzureCloudInstance` that point at different clouds are an error, not a silent choice.
- **Interactive sign-in differs by edition.** Windows PowerShell 5.1 can use MSAL's embedded window (`-UseEmbeddedWebView`); PowerShell 7 opens the system browser. `-AuthenticationBroker` uses the Windows broker (WAM).
- **The token cache on disk is encrypted**: DPAPI on Windows, the keyring (libsecret) on Linux. A Linux session with no keyring, such as SSH, needs `-AllowUnencryptedStorage` to keep a plain file instead.
- **Coming from MSAL.PS**: the cmdlets keep their names, but the two modules cannot be loaded together. The MSAL.PS token cache is copied once into the new one; the old settings file and `msalps.*` variables are not read (use `poshmsal.*`). `-ProofOfPossession` is gone (MSAL.NET removed it). Piping several objects into a cmdlet now handles each one; MSAL.PS kept only the last.
- **Integrated Windows authentication and username/password still work, with a warning**: MSAL.NET deprecates both.
- **One MSAL.NET per PowerShell session.** If Az.Accounts or Microsoft.Graph loaded theirs first, `Get-MsalFeatureSupport` lists the conflict.
- **Tested on Windows** (Windows PowerShell 5.1, PowerShell 7.4 and 7.6) **and on Linux** (PowerShell 7, desktop session). macOS is not supported yet.

## Tests

```powershell
Invoke-Pester -Path .\Tests
```

## Change log

- **5.0.0** — First Posh-MSAL release: MSAL.NET 4.92, Linux, public and sovereign clouds (`-Environment`, `*-MsalEnvironment`), encrypted token cache on disk on Windows and Linux, every piped object processed, help pages in `Docs/`.

## License

MIT, as MSAL.PS: see [License.txt](License.txt).
