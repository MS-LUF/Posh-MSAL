---
external help file: Posh-MSAL-help.xml
Module Name: Posh-MSAL
online version:
schema: 2.0.0
---

# New-MsalClientApplication

## SYNOPSIS
Builds a public or confidential client application for one cloud and tenant.

## SYNTAX

### PublicClient (Default)
```
New-MsalClientApplication [-ClientId] <String> [-RedirectUri <Uri>] [-AzureCloudInstance <AzureCloudInstance>]
 [-Environment <String>] [-TenantId <String>] [-Authority <Uri>] [-AuthenticationBroker]
 [-ExtraQueryParameters <Hashtable>] [-EnableExperimentalFeatures] [<CommonParameters>]
```

### ConfidentialClient-InputObject
```
New-MsalClientApplication [[-ClientId] <String>] [-ClientSecret <SecureString>]
 [-ClientCertificate <X509Certificate2>] [-ClientClaims <Hashtable>] [-ClientAssertion <String>]
 [-RedirectUri <Uri>] [-AzureCloudInstance <AzureCloudInstance>] [-Environment <String>] [-TenantId <String>]
 [-Authority <Uri>] [-ExtraQueryParameters <Hashtable>] [-EnableExperimentalFeatures]
 [-ConfidentialClientOptions] <ConfidentialClientApplicationOptions> [<CommonParameters>]
```

### ConfidentialClientAssertion
```
New-MsalClientApplication [-ClientId] <String> -ClientAssertion <String> [-RedirectUri <Uri>]
 [-AzureCloudInstance <AzureCloudInstance>] [-Environment <String>] [-TenantId <String>] [-Authority <Uri>]
 [-ExtraQueryParameters <Hashtable>] [-EnableExperimentalFeatures] [<CommonParameters>]
```

### ConfidentialClientClaims
```
New-MsalClientApplication [-ClientId] <String> -ClientCertificate <X509Certificate2> -ClientClaims <Hashtable>
 [-RedirectUri <Uri>] [-AzureCloudInstance <AzureCloudInstance>] [-Environment <String>] [-TenantId <String>]
 [-Authority <Uri>] [-ExtraQueryParameters <Hashtable>] [-EnableExperimentalFeatures] [<CommonParameters>]
```

### ConfidentialClientCertificate
```
New-MsalClientApplication [-ClientId] <String> -ClientCertificate <X509Certificate2> [-RedirectUri <Uri>]
 [-AzureCloudInstance <AzureCloudInstance>] [-Environment <String>] [-TenantId <String>] [-Authority <Uri>]
 [-ExtraQueryParameters <Hashtable>] [-EnableExperimentalFeatures] [<CommonParameters>]
```

### ConfidentialClientSecret
```
New-MsalClientApplication [-ClientId] <String> [-ClientSecret <SecureString>] [-RedirectUri <Uri>]
 [-AzureCloudInstance <AzureCloudInstance>] [-Environment <String>] [-TenantId <String>] [-Authority <Uri>]
 [-ExtraQueryParameters <Hashtable>] [-EnableExperimentalFeatures] [<CommonParameters>]
```

### PublicClient-InputObject
```
New-MsalClientApplication [[-ClientId] <String>] [-RedirectUri <Uri>]
 [-AzureCloudInstance <AzureCloudInstance>] [-Environment <String>] [-TenantId <String>] [-Authority <Uri>]
 [-AuthenticationBroker] [-ExtraQueryParameters <Hashtable>] [-EnableExperimentalFeatures]
 [-PublicClientOptions] <PublicClientApplicationOptions> [<CommonParameters>]
```

## DESCRIPTION
Returns a new MSAL.NET client application, to pass to Get-MsalToken or to keep for the session
with Add-MsalClientApplication.
Without a credential it is a public client, for users signing
in; with ClientSecret, ClientCertificate (with ClientClaims or not) or ClientAssertion it is a
confidential client.
MSAL.NET application options can be piped in instead of ClientId.

The authority comes from Environment, AzureCloudInstance or Authority, with TenantId (the public
cloud and the common tenant by default); parameters that point at different clouds are an
error.
An application signs in to one cloud only: Get-MsalToken refuses a request for another.

Without RedirectUri, a public client gets MSAL's default redirect URI; on Windows PowerShell 5.1
it is the nativeclient page of the chosen cloud's authority host.
AuthenticationBroker makes it
sign in through the Windows broker (WAM).

This cmdlet does not keep the application: Get-MsalToken and Select-MsalClientApplication build
and keep their own.

## EXAMPLES

### EXAMPLE 1
```
New-MsalClientApplication -ClientId '00000000-0000-0000-0000-000000000000' -TenantId 'contoso.onmicrosoft.com'
```

Builds a public client application for a tenant of the public cloud.

### EXAMPLE 2
```
New-MsalClientApplication -ClientId '00000000-0000-0000-0000-000000000000' -TenantId 'contoso.onmicrosoft.com' -ClientCertificate (Get-Item 'Cert:\CurrentUser\My\0000000000000000000000000000000000000000') -Environment 'DelosCloud'
```

Builds a confidential client application for Delos that signs in with a certificate.

### EXAMPLE 3
```
[Microsoft.Identity.Client.PublicClientApplicationOptions] @{ ClientId = '00000000-0000-0000-0000-000000000000' } | New-MsalClientApplication -TenantId 'contoso.onmicrosoft.com'
```

Builds a public client application from MSAL.NET options.

## PARAMETERS

### -ClientId
Identifier of the client requesting the token.

```yaml
Type: String
Parameter Sets: PublicClient, ConfidentialClientAssertion, ConfidentialClientClaims, ConfidentialClientCertificate, ConfidentialClientSecret
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: True (ByPropertyName, ByValue)
Accept wildcard characters: False
```

```yaml
Type: String
Parameter Sets: ConfidentialClient-InputObject, PublicClient-InputObject
Aliases:

Required: False
Position: 1
Default value: None
Accept pipeline input: True (ByPropertyName, ByValue)
Accept wildcard characters: False
```

### -ClientSecret
Secure secret of the client requesting the token.

```yaml
Type: SecureString
Parameter Sets: ConfidentialClient-InputObject, ConfidentialClientSecret
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -ClientCertificate
Client assertion certificate of the client requesting the token.

```yaml
Type: X509Certificate2
Parameter Sets: ConfidentialClient-InputObject
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

```yaml
Type: X509Certificate2
Parameter Sets: ConfidentialClientClaims, ConfidentialClientCertificate
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -ClientClaims
Set the specific client claims to sign.
ClientCertificate must also be specified.

```yaml
Type: Hashtable
Parameter Sets: ConfidentialClient-InputObject
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

```yaml
Type: Hashtable
Parameter Sets: ConfidentialClientClaims
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -ClientAssertion
Set client assertion used to prove the identity of the application to Azure AD.
This is a Base-64 encoded JWT.

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

```yaml
Type: String
Parameter Sets: ConfidentialClientAssertion
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -RedirectUri
Address to return to upon receiving a response from the authority.

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
Gives the authority host and, on Windows PowerShell, the default redirect URI.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -TenantId
Tenant identifier of the authority to issue token.

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
Parameter Sets: PublicClient, PublicClient-InputObject
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -ExtraQueryParameters
Sets Extra Query Parameters for the query string in the HTTP authentication request.

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

### -EnableExperimentalFeatures
Allows usage of experimental features and APIs.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -PublicClientOptions
MSAL.NET options of a public client application, used instead of -ClientId; its authority is kept unless a cloud or tenant parameter is given.

```yaml
Type: PublicClientApplicationOptions
Parameter Sets: PublicClient-InputObject
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: True (ByPropertyName, ByValue)
Accept wildcard characters: False
```

### -ConfidentialClientOptions
MSAL.NET options of a confidential client application, used instead of -ClientId; its authority is kept unless a cloud or tenant parameter is given.

```yaml
Type: ConfidentialClientApplicationOptions
Parameter Sets: ConfidentialClient-InputObject
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: True (ByPropertyName, ByValue)
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### System.String, Microsoft.Identity.Client.PublicClientApplicationOptions, Microsoft.Identity.Client.ConfidentialClientApplicationOptions
## OUTPUTS

### Microsoft.Identity.Client.PublicClientApplication, Microsoft.Identity.Client.ConfidentialClientApplication
## NOTES

## RELATED LINKS

[Select-MsalClientApplication]()

[Add-MsalClientApplication]()

[Get-MsalToken]()

