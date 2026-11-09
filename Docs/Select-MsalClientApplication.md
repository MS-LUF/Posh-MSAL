---
external help file: Posh-MSAL-help.xml
Module Name: Posh-MSAL
online version:
schema: 2.0.0
---

# Select-MsalClientApplication

## SYNOPSIS
Returns the session's client application for these settings, creating and keeping one if there is none.

## SYNTAX

### PublicClient (Default)
```
Select-MsalClientApplication [-ClientId] <String> [-RedirectUri <Uri>]
 [-AzureCloudInstance <AzureCloudInstance>] [-Environment <String>] [-TenantId <String>] [-Authority <Uri>]
 [-AuthenticationBroker] [<CommonParameters>]
```

### ConfidentialClient-InputObject
```
Select-MsalClientApplication [[-ClientId] <String>] [-ClientSecret <SecureString>]
 [-ClientCertificate <X509Certificate2>] [-RedirectUri <Uri>] [-AzureCloudInstance <AzureCloudInstance>]
 [-Environment <String>] [-TenantId <String>] [-Authority <Uri>]
 [-ConfidentialClientOptions] <ConfidentialClientApplicationOptions> [<CommonParameters>]
```

### ConfidentialClientCertificate
```
Select-MsalClientApplication [-ClientId] <String> -ClientCertificate <X509Certificate2> [-RedirectUri <Uri>]
 [-AzureCloudInstance <AzureCloudInstance>] [-Environment <String>] [-TenantId <String>] [-Authority <Uri>]
 [<CommonParameters>]
```

### ConfidentialClientSecret
```
Select-MsalClientApplication [-ClientId] <String> -ClientSecret <SecureString> [-RedirectUri <Uri>]
 [-AzureCloudInstance <AzureCloudInstance>] [-Environment <String>] [-TenantId <String>] [-Authority <Uri>]
 [<CommonParameters>]
```

### PublicClient-InputObject
```
Select-MsalClientApplication [[-ClientId] <String>] [-RedirectUri <Uri>]
 [-AzureCloudInstance <AzureCloudInstance>] [-Environment <String>] [-TenantId <String>] [-Authority <Uri>]
 [-AuthenticationBroker] [-PublicClientOptions] <PublicClientApplicationOptions> [<CommonParameters>]
```

## DESCRIPTION
Builds an application with the same parameters as New-MsalClientApplication, then returns the
application kept for the session that matches it (client id, credentials, redirect URI and
authority, host and tenant).
When none matches, the new application is added to the session list
and returned.
Get-MsalToken does the same, so the tokens an application caches are reused by
later calls.

Use it to get the application Get-MsalToken works with, for instance to pass it to
Enable-MsalTokenCacheOnDisk or Get-MsalAccount.

## EXAMPLES

### EXAMPLE 1
```
Select-MsalClientApplication -ClientId '00000000-0000-0000-0000-000000000000' -TenantId 'contoso.onmicrosoft.com' | Enable-MsalTokenCacheOnDisk
```

Makes the application Get-MsalToken uses for this client id and tenant keep its tokens on disk.

### EXAMPLE 2
```
Select-MsalClientApplication -ClientId '00000000-0000-0000-0000-000000000000' -Environment 'USGov'
```

Returns the session's public client application for the US Government cloud.

## PARAMETERS

### -ClientId
Identifier of the client requesting the token.

```yaml
Type: String
Parameter Sets: PublicClient, ConfidentialClientCertificate, ConfidentialClientSecret
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
Parameter Sets: ConfidentialClient-InputObject
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

```yaml
Type: SecureString
Parameter Sets: ConfidentialClientSecret
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
Parameter Sets: ConfidentialClientCertificate
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

[New-MsalClientApplication]()

[Get-MsalToken]()

