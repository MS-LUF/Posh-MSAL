---
external help file: Posh-MSAL-help.xml
Module Name: Posh-MSAL
online version:
schema: 2.0.0
---

# Add-MsalClientApplication

## SYNOPSIS
Adds a client application to the applications kept for the session.

## SYNTAX

### PublicClient (Default)
```
Add-MsalClientApplication [-PublicClientApplication] <IPublicClientApplication> [-PassThru]
 [<CommonParameters>]
```

### ConfidentialClient
```
Add-MsalClientApplication [-ConfidentialClientApplication] <IConfidentialClientApplication> [-PassThru]
 [<CommonParameters>]
```

## DESCRIPTION
Posh-MSAL keeps a list of client applications for the session so that Get-MsalToken and
Select-MsalClientApplication reuse them, and with them their token caches.
This cmdlet adds an
application built with New-MsalClientApplication to that list.

Adding an application already in the list is an error (AddMsalClientApplicationFailureAlreadyExists).

## EXAMPLES

### EXAMPLE 1
```
New-MsalClientApplication -ClientId '00000000-0000-0000-0000-000000000000' -TenantId 'contoso.onmicrosoft.com' | Add-MsalClientApplication
```

Builds a public client application and keeps it for the session.

### EXAMPLE 2
```
$ClientApplication | Add-MsalClientApplication -PassThru | Enable-MsalTokenCacheOnDisk
```

Keeps the application for the session, then makes it keep its tokens on disk.

## PARAMETERS

### -PublicClientApplication
Public client application to use, from New-MsalClientApplication or Select-MsalClientApplication.

```yaml
Type: IPublicClientApplication
Parameter Sets: PublicClient
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### -ConfidentialClientApplication
Confidential client application to use, from New-MsalClientApplication or Select-MsalClientApplication.

```yaml
Type: IConfidentialClientApplication
Parameter Sets: ConfidentialClient
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### -PassThru
Returns the client application.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### Microsoft.Identity.Client.IPublicClientApplication, Microsoft.Identity.Client.IConfidentialClientApplication
## OUTPUTS

### With -PassThru, the application added; otherwise nothing.
## NOTES

## RELATED LINKS

[Get-MsalClientApplication]()

[Remove-MsalClientApplication]()

