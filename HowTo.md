# HowTo — Posh-MSAL

A task-oriented walkthrough. Unless a section says otherwise, every command below was run against
the module under PowerShell 7.6 on Windows, and the output shown is what came back (errors are
shown as PowerShell prints them at the prompt, trimmed where long).

The examples use made-up identifiers, so the commands that reach the sign-in service end with
`AADSTS90002: Tenant ... not found`: the request was built, sent to the right cloud and answered,
but no tenant has that id. With your own tenant and app registration, the same commands return a
token. Commands that need a real tenant, a browser or a person at the keyboard are marked
**Not run for this guide**.

```powershell
$ClientId = '11111111-2222-3333-4444-555555555555'   # your app registration (client id)
$TenantId = '66666666-7777-8888-9999-000000000000'   # your tenant id or domain
```

1. [Installing and checking what this machine supports](#1-installing-and-checking-what-this-machine-supports)
2. [Getting a token for an application](#2-getting-a-token-for-an-application)
3. [Signing in as a user](#3-signing-in-as-a-user)
4. [Deprecated flows: integrated Windows authentication and username/password](#4-deprecated-flows-integrated-windows-authentication-and-usernamepassword)
5. [Choosing a cloud](#5-choosing-a-cloud)
6. [Default scope](#6-default-scope)
7. [Adding your own cloud](#7-adding-your-own-cloud)
8. [Reusing client applications](#8-reusing-client-applications)
9. [Keeping tokens between sessions](#9-keeping-tokens-between-sessions)
10. [Module settings and assembly conflicts](#10-module-settings-and-assembly-conflicts)
11. [Running the tests](#11-running-the-tests)

---

## 1. Installing and checking what this machine supports

Requirements: Windows PowerShell 5.1, or PowerShell 7.4 or later, on Windows or Linux. The
MSAL.NET libraries ship with the module (`lib/net472` for Windows PowerShell, `lib/net8.0` for
PowerShell 7); there is nothing else to install.

```powershell
Import-Module .\Posh-MSAL.psd1
Get-Module Posh-MSAL | Format-Table Name, Version
```

```
Name      Version
----      -------
Posh-MSAL 5.0.0
```

`Get-MsalFeatureSupport` says what works here:

```powershell
Get-MsalFeatureSupport
```

```
EmbeddedWebViewSupport : False
DeviceCodeSupport      : True
TokenCacheSupport      : True
AuthBrokerSupport      : True
MsalVersion            : 4.92.0.0
AssemblyConflicts      : {}
```

The same command under Windows PowerShell 5.1 differs on one line:

```
EmbeddedWebViewSupport : True
```

- `EmbeddedWebViewSupport`: MSAL's embedded sign-in window, which only the Windows PowerShell
  build of MSAL.NET has.
- `TokenCacheSupport`: the token cache on disk (section 9), on Windows and Linux.
- `AuthBrokerSupport`: the Windows broker (WAM), on Windows only.
- `MsalVersion` and `AssemblyConflicts`: section 10.

---

## 2. Getting a token for an application

A confidential client (a script, a service, a pipeline) signs in as itself with a secret, a
certificate or a signed assertion. Give the secret as a `SecureString`:

```powershell
$Secret = Read-Host -AsSecureString -Prompt 'Client secret'
Get-MsalToken -ClientId $ClientId -ClientSecret $Secret -TenantId $TenantId -Environment BleuCloud
```

```
Get-MsalToken: AADSTS90002: Tenant '66666666-7777-8888-9999-000000000000' not found. Check to make
sure you have the correct tenant ID and are signing into the correct cloud. [...]
```

With a real tenant, the result is an `AuthenticationResult`; the token is in `AccessToken`, its
expiry in `ExpiresOn`, the granted scopes in `Scopes`. Without `-Scopes` the request asks for
the cloud's Graph `.default` scope (section 6).

With a certificate, from the certificate store or a file:

```powershell
$Certificate = Get-Item Cert:\CurrentUser\My\<thumbprint>
Get-MsalToken -ClientId $ClientId -ClientCertificate $Certificate -TenantId $TenantId -SendX5C
```

`-SendX5C` sends the certificate's public key, which subject-name / issuer authentication needs.
The same call with a self-signed certificate and the made-up tenant ends with `AADSTS90002`, as
above; so does a call with `-Scopes` (section 6).

**Not run for this guide** (each needs a real tenant and the matching token or code):

```powershell
# On behalf of a user: exchange the token your API received for one to call another API
Get-MsalToken -ClientId $ClientId -ClientSecret $Secret -TenantId $TenantId -UserAssertion $IncomingToken -Scopes 'https://graph.microsoft.com/.default'

# Authorization code received by your web application
Get-MsalToken -ClientId $ClientId -ClientSecret $Secret -TenantId $TenantId -AuthorizationCode $Code -RedirectUri 'https://app.contoso.com/signin' -Scopes 'https://graph.microsoft.com/User.Read'

# A signed client assertion (a JWT you produced) instead of a secret
$App = New-MsalClientApplication -ClientId $ClientId -TenantId $TenantId -ClientAssertion $Jwt
Get-MsalToken -ConfidentialClientApplication $App
```

`-ForceRefresh` skips the token cache and asks for a new token; `-CorrelationId` tags the
request in the sign-in logs; `-Timeout` limits how long the call waits.

---

## 3. Signing in as a user

A public client (no secret) signs in a person. **Not run for this guide**: each flow needs a
real tenant and someone to sign in.

```powershell
$Scopes = 'https://graph.microsoft.com/User.Read'

# Default: the token cache first, then integrated Windows authentication, then interactive
Get-MsalToken -ClientId $ClientId -TenantId $TenantId -Scopes $Scopes

# Always interactive, with a pre-filled user name and the account picker
Get-MsalToken -ClientId $ClientId -TenantId $TenantId -Scopes $Scopes -Interactive -LoginHint 'user@contoso.com' -Prompt SelectAccount

# From the token cache only (fails with MsalUiRequiredException when a sign-in is needed)
Get-MsalToken -ClientId $ClientId -TenantId $TenantId -Scopes $Scopes -Silent

# Through the Windows broker (WAM): single sign-on with the Windows account
Get-MsalToken -ClientId $ClientId -TenantId $TenantId -Scopes $Scopes -Interactive -AuthenticationBroker
```

Where the sign-in page opens depends on the edition:

- **PowerShell 7** opens the system browser, which comes back to `http://localhost`: register
  `http://localhost` as a redirect URI of the app (platform "Mobile and desktop applications").
  A `-RedirectUri` on `http://localhost` with a port or path works too; with any other redirect
  URI, `-Interactive` uses the device code flow instead. The call waits two minutes by default;
  change it with `-Timeout`.
- **Windows PowerShell 5.1** can open MSAL's embedded window (`-UseEmbeddedWebView`); its
  default redirect URI is the cloud's `nativeclient` page, for example
  `https://login.microsoftonline.com/common/oauth2/nativeclient` (section 5).
- `-AuthenticationBroker` works on Windows only; elsewhere it is an error. Register the broker
  redirect URI `ms-appx-web://microsoft.aad.brokerplugin/<client id>` on the app.

On a machine with no browser, the device code flow prints a code to type on another device:

```powershell
Get-MsalToken -ClientId $ClientId -TenantId $TenantId -DeviceCode
```

With the made-up tenant, the service refuses before any code is given:

```
Get-MsalToken: AADSTS90002: Tenant '66666666-7777-8888-9999-000000000000' not found. [...]
```

With a real tenant the instructions ("To sign in, use a web browser to open the page
https://microsoft.com/devicelogin and enter the code ...") are written to the information stream,
so they appear in the console and can be captured with `6>&1` or `-InformationVariable`.

---

## 4. Deprecated flows: integrated Windows authentication and username/password

MSAL.NET deprecates both; they still work, with a warning when you ask for them:

```powershell
$Credential = Get-Credential user@contoso.com
Get-MsalToken -ClientId $ClientId -TenantId $TenantId -UserCredential $Credential
```

```
WARNING: The username/password flow (ROPC) is deprecated by MSAL.NET and blocked by multi-factor authentication; prefer the interactive, device code or broker flows.
Get-MsalToken: AADSTS90002: Tenant '66666666-7777-8888-9999-000000000000' not found. [...]
```

```powershell
Get-MsalToken -ClientId $ClientId -TenantId $TenantId -IntegratedWindowsAuth
```

```
WARNING: Integrated Windows Authentication is deprecated by MSAL.NET; prefer the authentication broker (-AuthenticationBroker) for single sign-on with the Windows account.
Get-MsalToken: Failed to get user name.
```

(That machine is not joined to a domain, hence the second line.) The default flow of section 3
tries integrated Windows authentication on its own, without the warning.

---

## 5. Choosing a cloud

The built-in clouds:

```powershell
Get-MsalEnvironment | Format-Table Name, Type, AzureADEndpoint, GraphEndpoint
```

```
Name       Type    AzureADEndpoint                    GraphEndpoint
----       ----    ---------------                    -------------
Global     BuiltIn https://login.microsoftonline.com  https://graph.microsoft.com
USGov      BuiltIn https://login.microsoftonline.us   https://graph.microsoft.us
USGovDoD   BuiltIn https://login.microsoftonline.us   https://dod-graph.microsoft.us
China      BuiltIn https://login.chinacloudapi.cn     https://microsoftgraph.chinacloudapi.cn
BleuCloud  BuiltIn https://login.sovcloud-identity.fr https://graph.svc.sovcloud.fr
DelosCloud BuiltIn https://login.sovcloud-identity.de https://graph.svc.sovcloud.de
GovSGCloud BuiltIn https://login.sovcloud-identity.sg https://graph.svc.sovcloud.sg
```

```powershell
Get-MsalEnvironment BleuCloud
```

```
Name                     : BleuCloud
Type                     : BuiltIn
AzureADEndpoint          : https://login.sovcloud-identity.fr
GraphEndpoint            : https://graph.svc.sovcloud.fr
DisableInstanceDiscovery : False
AzureCloudInstance       : GovFr
```

Pick the cloud with `-Environment` on `New-MsalClientApplication`, `Select-MsalClientApplication`,
`Get-MsalClientApplication` and `Get-MsalToken` (Tab completes the names):

```powershell
$App = New-MsalClientApplication -ClientId $ClientId -TenantId $TenantId -Environment BleuCloud
$App.Authority
$App.AppConfig.RedirectUri
```

```
https://login.sovcloud-identity.fr/66666666-7777-8888-9999-000000000000/
http://localhost
```

Under Windows PowerShell 5.1, the default redirect URI follows the cloud too:

```
https://login.sovcloud-identity.fr/common/oauth2/nativeclient
```

Three other ways to name a cloud, from the strongest to the weakest: `-Authority` (a full URL),
then `-Environment`, then `-AzureCloudInstance` (MSAL's enum); with none of them, `Global`.
Without a tenant, the authority uses `common`.

```powershell
(New-MsalClientApplication -ClientId $ClientId -AzureCloudInstance GovFr).Authority
(New-MsalClientApplication -ClientId $ClientId -Authority "https://login.microsoftonline.us/$TenantId").Authority
(New-MsalClientApplication -ClientId $ClientId).Authority
```

```
https://login.sovcloud-identity.fr/common/
https://login.microsoftonline.us/66666666-7777-8888-9999-000000000000/
https://login.microsoftonline.com/common/
```

`-AzureCloudInstance` maps onto the environments: `AzurePublic` is Global, `AzureUsGovernment`
USGov, `AzureChina` China, `GovFr` BleuCloud, `GovDe` DelosCloud, `GovSg` GovSGCloud. USGov and
USGovDoD share their sign-in host, so an authority on `login.microsoftonline.us` means USGov
unless you give `-Environment USGovDoD`.

Two parameters that point at different clouds are an error, before anything is sent:

```powershell
New-MsalClientApplication -ClientId $ClientId -Environment BleuCloud -AzureCloudInstance AzurePublic
New-MsalClientApplication -ClientId $ClientId -Environment Global -Authority "https://login.sovcloud-identity.fr/$TenantId"
New-MsalClientApplication -ClientId $ClientId -AzureCloudInstance AzureGermany
```

```
New-MsalClientApplication: -Environment BleuCloud and -AzureCloudInstance AzurePublic name different clouds; give only one.
New-MsalClientApplication: -Authority https://login.sovcloud-identity.fr/66666666-7777-8888-9999-000000000000 is not in the Global environment (https://login.microsoftonline.com); give only one of them.
New-MsalClientApplication: Azure Germany (-AzureCloudInstance AzureGermany) was closed in 2021 and cannot be used. Use -Environment to choose another cloud.
```

A `-TenantId` that differs from the tenant written in `-Authority` is an error too. An authority
no environment knows (ADFS, Azure AD B2C) is used exactly as given, and then the tenant must be
in the URL.

---

## 6. Default scope

Without `-Scopes`, `Get-MsalToken` asks for `<GraphEndpoint>/.default` of the application's
cloud: `https://graph.microsoft.com/.default` in Global, `https://graph.svc.sovcloud.fr/.default`
in Bleu, `https://dod-graph.microsoft.us/.default` with `-Environment USGovDoD`. For any other
API, give its scopes:

```powershell
Get-MsalToken -ClientId $ClientId -ClientSecret $Secret -TenantId $TenantId -Scopes 'https://management.azure.com/.default'
```

For an authority no environment knows, there is no default; the error says what to do:

```powershell
$Adfs = New-MsalClientApplication -ClientId $ClientId -ClientSecret $Secret -Authority 'https://adfs.contoso.com/adfs'
Get-MsalToken -ConfidentialClientApplication $Adfs
```

```
Get-MsalToken: No environment has the authority host adfs.contoso.com, so there is no default scope: give -Scopes, or add the cloud with Add-MsalEnvironment.
```

---

## 7. Adding your own cloud

For a cloud the built-ins do not cover, add an environment. It is saved in
`<ApplicationData>/Posh-MSAL/environments.json` (`%APPDATA%` on Windows, `~/.config` on Linux),
so later sessions have it.

```powershell
Add-MsalEnvironment -Name Contoso -AzureADEndpoint 'https://login.contoso.com' -GraphEndpoint 'https://graph.contoso.com'
```

```
Name                     : Contoso
Type                     : UserDefined
AzureADEndpoint          : https://login.contoso.com
GraphEndpoint            : https://graph.contoso.com
DisableInstanceDiscovery : False
AzureCloudInstance       :
```

The file it wrote:

```
[
  {
    "Name": "Contoso",
    "AzureADEndpoint": "https://login.contoso.com",
    "GraphEndpoint": "https://graph.contoso.com",
    "DisableInstanceDiscovery": false
  }
]
```

```powershell
(New-MsalClientApplication -ClientId $ClientId -Environment Contoso).Authority
```

```
https://login.contoso.com/common/
```

MSAL.NET checks an authority against the clouds it knows (instance discovery). For a sign-in host
it does not know, turn that off on the environment; it also turns off MSAL's authority
validation, so only do it for a host you trust. Every application built for it says so:

```powershell
Set-MsalEnvironment -Name Contoso -DisableInstanceDiscovery
(New-MsalClientApplication -ClientId $ClientId -Environment Contoso).Authority
```

```
WARNING: Instance discovery and authority validation are off for the Contoso environment (https://login.contoso.com/common).
https://login.contoso.com/common/
```

`-DisableInstanceDiscovery:$false` turns it back on. `Set-MsalEnvironment` also changes
`-AzureADEndpoint` and `-GraphEndpoint`; applications already built keep their authority.

```powershell
Remove-MsalEnvironment -Name Contoso -WhatIf
Remove-MsalEnvironment -Name Contoso -Confirm:$false
Get-MsalEnvironment Contoso
```

```
What if: Performing the operation "Remove environment" on target "Contoso".
Get-MsalEnvironment: Unknown environment "Contoso".
```

The built-ins cannot be changed or removed:

```powershell
Set-MsalEnvironment -Name Global -GraphEndpoint 'https://graph.contoso.com'
```

```
Set-MsalEnvironment: "Global" is a built-in environment and cannot be changed; add a user-defined one with Add-MsalEnvironment.
```

Names are letters, digits, `-` and `_`; endpoints are `https://` URLs with a host only.

---

## 8. Reusing client applications

`Get-MsalToken -ClientId ...` keeps the application it builds for the session and reuses it on
the next call with the same settings, so its in-memory token cache is reused too. An application
is kept per client id, credential, redirect URI, broker setting, cloud and tenant.

`Select-MsalClientApplication` does the same and returns the application:

```powershell
Clear-MsalTokenCache
$A = Select-MsalClientApplication -ClientId $ClientId -TenantId $TenantId
$B = Select-MsalClientApplication -ClientId $ClientId -TenantId $TenantId
[object]::ReferenceEquals($A, $B)
@(Get-MsalClientApplication -ClientId $ClientId).Count
```

```
True
1
```

`Get-MsalClientApplication` filters the kept applications (`-ClientId`, `-TenantId`,
`-Authority`, `-RedirectUri`, `-Environment`; confidential ones with `-ClientSecret` or
`-ClientCertificate`). After the client secret call of section 2:

```powershell
Get-MsalClientApplication -ClientSecret $Secret | Format-Table @{ n = 'ClientId'; e = { $_.AppConfig.ClientId } }, Authority
```

```
ClientId                             Authority
--------                             ---------
11111111-2222-3333-4444-555555555555 https://login.sovcloud-identity.fr/66666666-7777-8888-9999-000000000000/
```

An application you build yourself joins the list with `Add-MsalClientApplication` and leaves it
with `Remove-MsalClientApplication`; `Clear-MsalTokenCache` empties the list.

```powershell
$C = New-MsalClientApplication -ClientId $ClientId -Environment USGov
Add-MsalClientApplication $C
Get-MsalClientApplication -Environment USGov | ForEach-Object Authority
Remove-MsalClientApplication $C
@(Get-MsalClientApplication -Environment USGov).Count
```

```
https://login.microsoftonline.us/common/
0
```

Every cmdlet that takes pipeline input handles each object piped in, so several applications can
be built, added or removed at once. `Remove-MsalClientApplication` also takes `-WhatIf` and
`-Confirm`:

```powershell
Clear-MsalTokenCache
$Apps = '11111111-2222-3333-4444-555555555555', '77777777-2222-3333-4444-555555555555' | New-MsalClientApplication
$Apps | Add-MsalClientApplication
@(Get-MsalClientApplication).Count
$Apps | Remove-MsalClientApplication -WhatIf
$Apps | Remove-MsalClientApplication
@(Get-MsalClientApplication).Count
```

```
2
What if: Performing the operation "Remove client application from the session" on target "11111111-2222-3333-4444-555555555555 (https://login.microsoftonline.com/common/)".
What if: Performing the operation "Remove client application from the session" on target "77777777-2222-3333-4444-555555555555 (https://login.microsoftonline.com/common/)".
0
```

An application can be passed to `Get-MsalToken` (`-PublicClientApplication`,
`-ConfidentialClientApplication`, or through the pipeline). Its cloud is fixed: `-TenantId` (or
the tenant of `-Authority`) can target another tenant of the same cloud, but another cloud is an
error:

```powershell
$Bleu = Get-MsalClientApplication -ClientSecret $Secret | Select-Object -First 1
$Bleu | Get-MsalToken -Environment Global
```

```
Get-MsalToken: The client application was built for login.sovcloud-identity.fr, not login.microsoftonline.com; create one for that cloud with New-MsalClientApplication -Environment or -Authority.
```

`New-MsalClientApplication` also takes MSAL's own option objects
(`-PublicClientOptions`, `-ConfidentialClientOptions`), `-ExtraQueryParameters` and
`-EnableExperimentalFeatures`.

---

## 9. Keeping tokens between sessions

By default tokens live in memory and are gone when PowerShell exits. `Enable-MsalTokenCacheOnDisk`
keeps an application's tokens in a cache shared by all your sessions and applications:

```powershell
$App = Select-MsalClientApplication -ClientId $ClientId -TenantId $TenantId
Enable-MsalTokenCacheOnDisk $App -PassThru | ForEach-Object Authority
@(Get-MsalAccount $App).Count
```

```
https://login.microsoftonline.com/66666666-7777-8888-9999-000000000000/
0
```

`Get-MsalAccount` lists the signed-in accounts the cache holds (none yet here). The files are
created at the first token, in `<LocalApplicationData>/Posh-MSAL/` (`%LOCALAPPDATA%` on Windows,
`~/.local/share` on Linux):

- `Posh-MSAL.usercache.bin`: users' tokens;
- `Posh-MSAL.appcache.bin`: tokens of confidential clients (section 2), kept apart so the two never
  overwrite each other.

They are encrypted with DPAPI for your Windows account. On Linux the tokens are kept in the
keyring through libsecret (a Secret Service keyring such as GNOME Keyring); a session with no keyring, such as SSH or a
container, cannot encrypt them and the command stops with:

```
Enable-MsalTokenCacheOnDisk: The token cache cannot be stored encrypted on this system: <reason>. On Linux this needs libsecret and an unlocked keyring (e.g. GNOME Keyring) in the session; SSH and headless sessions usually have none. Use -AllowUnencryptedStorage to keep it in a plain file readable by your account instead.
```

(That message is produced by the module's tests with the keyring made to fail; it was not
captured on a headless Linux host.) With `-AllowUnencryptedStorage`, the cache falls back to
`Posh-MSAL.usercache.unprotected.bin`, with a warning at every call. It is used only when the
encrypted store fails.

Coming from MSAL.PS on Windows: the first time, the MSAL.PS cache
(`%LOCALAPPDATA%\MSAL.PS\MSAL.PS.msalcache.bin3`) is copied into the new user cache, so you stay
signed in; the old file is not changed.

To delete everything on disk (both caches, the unencrypted files, the keyring entries and the old
MSAL.PS file):

```powershell
Clear-MsalTokenCache -FromDisk
```

Applications already enabled then see an empty cache. Without `-FromDisk`, `Clear-MsalTokenCache`
only forgets the session's applications (section 8).

(The outputs of this section came from a session whose cache and settings folders pointed at a
temporary folder, so that the walkthrough left nothing in the profile.)

---

## 10. Module settings and assembly conflicts

PowerShell loads one copy of an assembly per session. Az.Accounts and Microsoft.Graph ship their
own MSAL.NET: whichever module is imported first decides the version for all of them. Posh-MSAL
reports what it found:

```powershell
(Get-MsalFeatureSupport).MsalVersion
(Get-MsalFeatureSupport).AssemblyConflicts
```

When one of its libraries is already loaded in another version, the import asks whether to go
on. Answer in advance, for one import or for every session:

```powershell
# This import only
Import-Module .\Posh-MSAL.psd1 -ArgumentList @{ 'dll.lenientLoading' = $true; 'dll.lenientLoadingPrompt' = $false }

# Every session, through an environment variable
${env:poshmsal.dll.lenientLoading} = $true
```

Answering "remember" at the prompt saves the choice in `<ApplicationData>/Posh-MSAL/config.json`.
The settings are read in this order, the last one winning: the module's defaults, that file, the
`poshmsal.*` environment variables, then `-ArgumentList`. **Not run for this guide**: there was no
conflicting module on the test machine (`AssemblyConflicts` is empty in section 1). To avoid the
conflict altogether, import Posh-MSAL in a session of its own.

---

## 11. Running the tests

```powershell
Invoke-Pester -Path .\Tests
```

The tests need no tenant and no network; they redirect the
module's settings and cache folders to temporary ones. Some only run on Windows (the DPAPI cache,
the migration from MSAL.PS) or on Windows PowerShell 5.1 (the assembly loading), and are reported
as skipped elsewhere.
