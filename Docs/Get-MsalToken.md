---
external help file: Posh-MSAL-help.xml
Module Name: Posh-MSAL
online version:
schema: 2.0.0
---

# Get-MsalToken

## SYNOPSIS
Gets an OAuth token from Microsoft Entra ID, in the public cloud or a sovereign cloud.

## SYNTAX

### PublicClient (Default)
```
Get-MsalToken [-ClientId] <String> [-RedirectUri <Uri>] [-AzureCloudInstance <AzureCloudInstance>]
 [-Environment <String>] [-TenantId <String>] [-Authority <Uri>] [-AuthenticationBroker] [-Scopes <String[]>]
 [-ExtraScopesToConsent <String[]>] [-LoginHint <String>] [-Prompt <String>] [-CorrelationId <Guid>]
 [-ExtraQueryParameters <Hashtable>] [-ForceRefresh] [-UseEmbeddedWebView] [-Timeout <TimeSpan>]
 [<CommonParameters>]
```

### ConfidentialClientCertificate-OnBehalfOf
```
Get-MsalToken [-ClientId] <String> -ClientCertificate <X509Certificate2> [-SendX5C] -UserAssertion <String>
 [-UserAssertionType <String>] [-RedirectUri <Uri>] [-AzureCloudInstance <AzureCloudInstance>]
 [-Environment <String>] [-TenantId <String>] [-Authority <Uri>] [-Scopes <String[]>] [-CorrelationId <Guid>]
 [-ExtraQueryParameters <Hashtable>] [-Timeout <TimeSpan>] [<CommonParameters>]
```

### ConfidentialClientCertificate-AuthorizationCode
```
Get-MsalToken [-ClientId] <String> -ClientCertificate <X509Certificate2> [-SendX5C] -AuthorizationCode <String>
 [-RedirectUri <Uri>] [-AzureCloudInstance <AzureCloudInstance>] [-Environment <String>] [-TenantId <String>]
 [-Authority <Uri>] [-Scopes <String[]>] [-CorrelationId <Guid>] [-ExtraQueryParameters <Hashtable>]
 [-Timeout <TimeSpan>] [<CommonParameters>]
```

### ConfidentialClientCertificate
```
Get-MsalToken [-ClientId] <String> -ClientCertificate <X509Certificate2> [-SendX5C] [-RedirectUri <Uri>]
 [-AzureCloudInstance <AzureCloudInstance>] [-Environment <String>] [-TenantId <String>] [-Authority <Uri>]
 [-Scopes <String[]>] [-CorrelationId <Guid>] [-ExtraQueryParameters <Hashtable>] [-ForceRefresh]
 [-Timeout <TimeSpan>] [<CommonParameters>]
```

### ConfidentialClientSecret-OnBehalfOf
```
Get-MsalToken [-ClientId] <String> -ClientSecret <SecureString> -UserAssertion <String>
 [-UserAssertionType <String>] [-RedirectUri <Uri>] [-AzureCloudInstance <AzureCloudInstance>]
 [-Environment <String>] [-TenantId <String>] [-Authority <Uri>] [-Scopes <String[]>] [-CorrelationId <Guid>]
 [-ExtraQueryParameters <Hashtable>] [-Timeout <TimeSpan>] [<CommonParameters>]
```

### ConfidentialClientSecret-AuthorizationCode
```
Get-MsalToken [-ClientId] <String> -ClientSecret <SecureString> -AuthorizationCode <String>
 [-RedirectUri <Uri>] [-AzureCloudInstance <AzureCloudInstance>] [-Environment <String>] [-TenantId <String>]
 [-Authority <Uri>] [-Scopes <String[]>] [-CorrelationId <Guid>] [-ExtraQueryParameters <Hashtable>]
 [-Timeout <TimeSpan>] [<CommonParameters>]
```

### ConfidentialClientSecret
```
Get-MsalToken [-ClientId] <String> -ClientSecret <SecureString> [-RedirectUri <Uri>]
 [-AzureCloudInstance <AzureCloudInstance>] [-Environment <String>] [-TenantId <String>] [-Authority <Uri>]
 [-Scopes <String[]>] [-CorrelationId <Guid>] [-ExtraQueryParameters <Hashtable>] [-ForceRefresh]
 [-Timeout <TimeSpan>] [<CommonParameters>]
```

### PublicClient-DeviceCode
```
Get-MsalToken [-ClientId] <String> [-RedirectUri <Uri>] [-AzureCloudInstance <AzureCloudInstance>]
 [-Environment <String>] [-TenantId <String>] [-Authority <Uri>] [-DeviceCode] [-Scopes <String[]>]
 [-CorrelationId <Guid>] [-ExtraQueryParameters <Hashtable>] [-Timeout <TimeSpan>] [<CommonParameters>]
```

### PublicClient-UsernamePassword
```
Get-MsalToken [-ClientId] <String> [-RedirectUri <Uri>] [-AzureCloudInstance <AzureCloudInstance>]
 [-Environment <String>] [-TenantId <String>] [-Authority <Uri>] [-Scopes <String[]>]
 -UserCredential <PSCredential> [-CorrelationId <Guid>] [-ExtraQueryParameters <Hashtable>]
 [-Timeout <TimeSpan>] [<CommonParameters>]
```

### PublicClient-Silent
```
Get-MsalToken [-ClientId] <String> [-RedirectUri <Uri>] [-AzureCloudInstance <AzureCloudInstance>]
 [-Environment <String>] [-TenantId <String>] [-Authority <Uri>] [-Silent] [-Scopes <String[]>]
 [-LoginHint <String>] [-CorrelationId <Guid>] [-ExtraQueryParameters <Hashtable>] [-ForceRefresh]
 [-Timeout <TimeSpan>] [<CommonParameters>]
```

### PublicClient-IntegratedWindowsAuth
```
Get-MsalToken [-ClientId] <String> [-RedirectUri <Uri>] [-AzureCloudInstance <AzureCloudInstance>]
 [-Environment <String>] [-TenantId <String>] [-Authority <Uri>] [-IntegratedWindowsAuth] [-Scopes <String[]>]
 [-LoginHint <String>] [-CorrelationId <Guid>] [-ExtraQueryParameters <Hashtable>] [-Timeout <TimeSpan>]
 [<CommonParameters>]
```

### PublicClient-Interactive
```
Get-MsalToken [-ClientId] <String> [-RedirectUri <Uri>] [-AzureCloudInstance <AzureCloudInstance>]
 [-Environment <String>] [-TenantId <String>] [-Authority <Uri>] [-AuthenticationBroker] [-Interactive]
 [-DeviceCode] [-Scopes <String[]>] [-ExtraScopesToConsent <String[]>] [-LoginHint <String>] [-Prompt <String>]
 [-CorrelationId <Guid>] [-ExtraQueryParameters <Hashtable>] [-UseEmbeddedWebView] [-Timeout <TimeSpan>]
 [<CommonParameters>]
```

### ConfidentialClient-InputObject
```
Get-MsalToken [-SendX5C] [-AuthorizationCode <String>] [-UserAssertion <String>] [-UserAssertionType <String>]
 [-AzureCloudInstance <AzureCloudInstance>] [-Environment <String>] [-TenantId <String>] [-Authority <Uri>]
 [-ConfidentialClientApplication] <IConfidentialClientApplication> [-Scopes <String[]>] [-CorrelationId <Guid>]
 [-ExtraQueryParameters <Hashtable>] [-ForceRefresh] [-Timeout <TimeSpan>] [<CommonParameters>]
```

### PublicClient-InputObject
```
Get-MsalToken [-AzureCloudInstance <AzureCloudInstance>] [-Environment <String>] [-TenantId <String>]
 [-Authority <Uri>] [-AuthenticationBroker] [-PublicClientApplication] <IPublicClientApplication>
 [-Interactive] [-IntegratedWindowsAuth] [-Silent] [-DeviceCode] [-Scopes <String[]>]
 [-ExtraScopesToConsent <String[]>] [-LoginHint <String>] [-Prompt <String>] [-UserCredential <PSCredential>]
 [-CorrelationId <Guid>] [-ExtraQueryParameters <Hashtable>] [-ForceRefresh] [-UseEmbeddedWebView]
 [-Timeout <TimeSpan>] [<CommonParameters>]
```

## DESCRIPTION
Gets a token through MSAL.NET for a public client (a user signs in) or a confidential client (the
application signs in with a secret, a certificate or an assertion).
Unless an application is
piped in, the cmdlet uses the session's application for these settings, as
Select-MsalClientApplication does, so the tokens it caches are reused by later calls.

The flow follows the parameters.
A confidential client uses the client credentials, or the
authorization code with AuthorizationCode, or on-behalf-of with UserAssertion.
A public client
signs in with UserCredential (username and password), DeviceCode, Interactive,
IntegratedWindowsAuth or Silent; with none of them, it tries the token cache, then integrated
Windows authentication, then an interactive sign-in.
Integrated Windows authentication and
username and password are deprecated by MSAL.NET and warn when asked for.

The cloud comes from Environment, AzureCloudInstance or Authority (the public cloud by default);
parameters that point at different clouds are an error.
Without Scopes, the scope is the Graph
endpoint of the cloud followed by /.default.
On an application piped in, only the tenant can
change per request.

Interactive sign-in uses MSAL's embedded window on Windows PowerShell 5.1 and the system browser
on PowerShell 7, which needs an http://localhost redirect URI on the app registration; without
one, PowerShell 7 falls back to device code.
With the system browser, the cmdlet gives up after
2 minutes unless Timeout says otherwise.
Device code messages go to the information stream.

A failure is a terminating error: GetMsalTokenFailureAuthenticationError (the MSAL.NET exception
is in the error record), GetMsalTokenFailureOperationTimeout or GetMsalTokenFailureOperationStopped.

## EXAMPLES

### EXAMPLE 1
```
Get-MsalToken -ClientId '00000000-0000-0000-0000-000000000000' -TenantId 'contoso.onmicrosoft.com' -ClientSecret (Read-Host -AsSecureString -Prompt 'Client secret')
```

Gets an application token for Microsoft Graph in the public cloud, with a client secret.

### EXAMPLE 2
```
Get-MsalToken -ClientId '00000000-0000-0000-0000-000000000000' -TenantId 'contoso.onmicrosoft.com' -ClientCertificate (Get-Item 'Cert:\CurrentUser\My\0000000000000000000000000000000000000000') -Environment 'BleuCloud'
```

Gets an application token in Bleu with a certificate; the scope is the Bleu Graph default.

### EXAMPLE 3
```
Get-MsalToken -ClientId '00000000-0000-0000-0000-000000000000' -TenantId 'contoso.onmicrosoft.com' -Interactive -Scopes 'https://graph.microsoft.com/User.Read' -LoginHint 'user@contoso.com'
```

Signs a user in interactively, with the user name filled in.

### EXAMPLE 4
```
Get-MsalToken -ClientId '00000000-0000-0000-0000-000000000000' -TenantId 'contoso.onmicrosoft.com' -Silent -Scopes 'https://graph.microsoft.com/User.Read'
```

Gets a user token from the token cache, refreshing it when needed, without any sign-in.

### EXAMPLE 5
```
Get-MsalToken -ClientId '00000000-0000-0000-0000-000000000000' -TenantId 'contoso.onmicrosoft.com' -DeviceCode
```

Signs a user in on another device, for a machine with no browser.

### EXAMPLE 6
```
Get-MsalClientApplication -ClientId '00000000-0000-0000-0000-000000000000' | Get-MsalToken -TenantId 'fabrikam.onmicrosoft.com'
```

Uses the session's application with this client id for another tenant of the same cloud.

## PARAMETERS

### -ClientId
Identifier of the client requesting the token.

```yaml
Type: String
Parameter Sets: PublicClient, ConfidentialClientCertificate-OnBehalfOf, ConfidentialClientCertificate-AuthorizationCode, ConfidentialClientCertificate, ConfidentialClientSecret-OnBehalfOf, ConfidentialClientSecret-AuthorizationCode, ConfidentialClientSecret, PublicClient-DeviceCode, PublicClient-UsernamePassword, PublicClient-Silent, PublicClient-IntegratedWindowsAuth, PublicClient-Interactive
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: True (ByPropertyName, ByValue)
Accept wildcard characters: False
```

### -ClientSecret
Secure secret of the client requesting the token.

```yaml
Type: SecureString
Parameter Sets: ConfidentialClientSecret-OnBehalfOf, ConfidentialClientSecret-AuthorizationCode, ConfidentialClientSecret
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -ClientCertificate
Client assertion certificate of the client requesting the token.

```yaml
Type: X509Certificate2
Parameter Sets: ConfidentialClientCertificate-OnBehalfOf, ConfidentialClientCertificate-AuthorizationCode, ConfidentialClientCertificate
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -SendX5C
Specifies if the x5c claim (public key of the certificate) should be sent to the STS.

```yaml
Type: SwitchParameter
Parameter Sets: ConfidentialClientCertificate-OnBehalfOf, ConfidentialClientCertificate-AuthorizationCode, ConfidentialClientCertificate, ConfidentialClient-InputObject
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -AuthorizationCode
The authorization code received from service authorization endpoint.

```yaml
Type: String
Parameter Sets: ConfidentialClientCertificate-AuthorizationCode, ConfidentialClientSecret-AuthorizationCode
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

```yaml
Type: String
Parameter Sets: ConfidentialClient-InputObject
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -UserAssertion
Assertion representing the user.

```yaml
Type: String
Parameter Sets: ConfidentialClientCertificate-OnBehalfOf, ConfidentialClientSecret-OnBehalfOf
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

```yaml
Type: String
Parameter Sets: ConfidentialClient-InputObject
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -UserAssertionType
Type of the assertion representing the user.

```yaml
Type: String
Parameter Sets: ConfidentialClientCertificate-OnBehalfOf, ConfidentialClientSecret-OnBehalfOf, ConfidentialClient-InputObject
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -RedirectUri
Address to return to upon receiving a response from the authority.

```yaml
Type: Uri
Parameter Sets: PublicClient, ConfidentialClientCertificate-OnBehalfOf, ConfidentialClientCertificate-AuthorizationCode, ConfidentialClientCertificate, ConfidentialClientSecret-OnBehalfOf, ConfidentialClientSecret-AuthorizationCode, ConfidentialClientSecret, PublicClient-DeviceCode, PublicClient-UsernamePassword, PublicClient-Silent, PublicClient-IntegratedWindowsAuth, PublicClient-Interactive
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -AzureCloudInstance
Cloud to sign in to, as an MSAL.NET AzureCloudInstance value; -Environment covers more clouds.
AzureGermany is refused (closed in 2021).

```yaml
Type: AzureCloudInstance
Parameter Sets: (All)
Aliases:
Accepted values: None, AzurePublic, AzureChina, AzureGermany, AzureUsGovernment, GovFr, GovDe, GovSg

Required: False
Position: Named
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -Environment
Cloud to sign in to: a built-in or user-defined environment (Get-MsalEnvironment).
Gives the authority and the default scope.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -TenantId
Tenant identifier of the authority to issue token.
It can also contain the value "consumers" or "organizations".

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -Authority
Address of the authority to issue token.

```yaml
Type: Uri
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -AuthenticationBroker
Sign in through the Windows authentication broker (WAM); Windows only.

```yaml
Type: SwitchParameter
Parameter Sets: PublicClient, PublicClient-Interactive, PublicClient-InputObject
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -PublicClientApplication
Public client application to use, from New-MsalClientApplication or Select-MsalClientApplication.

```yaml
Type: IPublicClientApplication
Parameter Sets: PublicClient-InputObject
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: True (ByPropertyName, ByValue)
Accept wildcard characters: False
```

### -ConfidentialClientApplication
Confidential client application to use, from New-MsalClientApplication or Select-MsalClientApplication.

```yaml
Type: IConfidentialClientApplication
Parameter Sets: ConfidentialClient-InputObject
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: True (ByPropertyName, ByValue)
Accept wildcard characters: False
```

### -Interactive
Interactive request to acquire a token for the specified scopes.

```yaml
Type: SwitchParameter
Parameter Sets: PublicClient-Interactive
Aliases:

Required: True
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

```yaml
Type: SwitchParameter
Parameter Sets: PublicClient-InputObject
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -IntegratedWindowsAuth
Non-interactive request to acquire a security token for the signed-in user in Windows, via Integrated Windows Authentication.

```yaml
Type: SwitchParameter
Parameter Sets: PublicClient-IntegratedWindowsAuth
Aliases:

Required: True
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

```yaml
Type: SwitchParameter
Parameter Sets: PublicClient-InputObject
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -Silent
Attempts to acquire an access token from the user token cache.

```yaml
Type: SwitchParameter
Parameter Sets: PublicClient-Silent
Aliases:

Required: True
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

```yaml
Type: SwitchParameter
Parameter Sets: PublicClient-InputObject
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -DeviceCode
Acquires a security token on a device without a Web browser, by letting the user authenticate on another device.

```yaml
Type: SwitchParameter
Parameter Sets: PublicClient-DeviceCode
Aliases:

Required: True
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

```yaml
Type: SwitchParameter
Parameter Sets: PublicClient-Interactive, PublicClient-InputObject
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -Scopes
Array of scopes requested for resource.
Default: https://\<GraphEndpoint\>/.default of the environment.

```yaml
Type: String[]
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -ExtraScopesToConsent
Array of scopes for which a developer can request consent upfront.

```yaml
Type: String[]
Parameter Sets: PublicClient, PublicClient-Interactive, PublicClient-InputObject
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -LoginHint
Identifier of the user.
Generally a UPN.

```yaml
Type: String
Parameter Sets: PublicClient, PublicClient-Silent, PublicClient-IntegratedWindowsAuth, PublicClient-Interactive, PublicClient-InputObject
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -Prompt
Specifies the what the interactive experience is for the user.
To force an interactive authentication, use the -Interactive switch.

```yaml
Type: String
Parameter Sets: PublicClient, PublicClient-Interactive, PublicClient-InputObject
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -UserCredential
Identifier of the user with associated password.

```yaml
Type: PSCredential
Parameter Sets: PublicClient-UsernamePassword
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

```yaml
Type: PSCredential
Parameter Sets: PublicClient-InputObject
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -CorrelationId
Correlation id to be used in the authentication request.

```yaml
Type: Guid
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ExtraQueryParameters
This parameter will be appended as is to the query string in the HTTP authentication request to the authority.

```yaml
Type: Hashtable
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -ForceRefresh
Ignore any access token in the user token cache and attempt to acquire new access token using the refresh token for the account if one is available.

```yaml
Type: SwitchParameter
Parameter Sets: PublicClient, ConfidentialClientCertificate, ConfidentialClientSecret, PublicClient-Silent, ConfidentialClient-InputObject, PublicClient-InputObject
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -UseEmbeddedWebView
Specifies if the public client application should used an embedded web browser or the system default browser

```yaml
Type: SwitchParameter
Parameter Sets: PublicClient, PublicClient-Interactive, PublicClient-InputObject
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -Timeout
Specifies the timeout threshold for MSAL.net operations.

```yaml
Type: TimeSpan
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### Microsoft.Identity.Client.IPublicClientApplication, Microsoft.Identity.Client.IConfidentialClientApplication, System.String
## OUTPUTS

### Microsoft.Identity.Client.AuthenticationResult
## NOTES

## RELATED LINKS

[Select-MsalClientApplication]()

[Get-MsalEnvironment]()

[Enable-MsalTokenCacheOnDisk]()

