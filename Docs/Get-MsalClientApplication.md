---
external help file: Posh-MSAL-help.xml
Module Name: Posh-MSAL
online version:
schema: 2.0.0
---

# Get-MsalClientApplication

## SYNOPSIS
Gets the client applications kept for the session.

## SYNTAX

### PublicClient (Default)
```
Get-MsalClientApplication [-ClientId <String>] [-RedirectUri <Uri>] [-TenantId <String>] [-Authority <Uri>]
 [-Environment <String>] [<CommonParameters>]
```

### ConfidentialClientSecret
```
Get-MsalClientApplication [-ClientId <String>] [-ClientSecret <SecureString>] [-RedirectUri <Uri>]
 [-TenantId <String>] [-Authority <Uri>] [-Environment <String>] [<CommonParameters>]
```

### ConfidentialClientCertificate
```
Get-MsalClientApplication [-ClientId <String>] [-ClientCertificate <X509Certificate2>] [-RedirectUri <Uri>]
 [-TenantId <String>] [-Authority <Uri>] [-Environment <String>] [<CommonParameters>]
```

## DESCRIPTION
Returns the applications that Get-MsalToken, Select-MsalClientApplication and
Add-MsalClientApplication keep for the session, filtered by the parameters given.
Without
ClientSecret or ClientCertificate, both public and confidential applications are returned; with
one of them, only the confidential applications built with that secret or certificate.

TenantId and Authority match the tenant of the application's authority; Environment matches the
authority host of that cloud.

## EXAMPLES

### EXAMPLE 1
```
Get-MsalClientApplication
```

Lists every application kept for the session.

### EXAMPLE 2
```
Get-MsalClientApplication -ClientId '00000000-0000-0000-0000-000000000000' -Environment 'BleuCloud'
```

Lists the applications with this client id that sign in to Bleu.

## PARAMETERS

### -ClientId
Identifier of the client requesting the token.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: True (ByPropertyName, ByValue)
Accept wildcard characters: False
```

### -ClientSecret
Secure secret of the client requesting the token.

```yaml
Type: SecureString
Parameter Sets: ConfidentialClientSecret
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
Parameter Sets: ConfidentialClientCertificate
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

### -Environment
Only applications of this environment's cloud (Get-MsalEnvironment).

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

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### System.String
## OUTPUTS

### Microsoft.Identity.Client.PublicClientApplication, Microsoft.Identity.Client.ConfidentialClientApplication
## NOTES

## RELATED LINKS

[Select-MsalClientApplication]()

[Add-MsalClientApplication]()

