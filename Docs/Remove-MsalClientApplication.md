---
external help file: Posh-MSAL-help.xml
Module Name: Posh-MSAL
online version:
schema: 2.0.0
---

# Remove-MsalClientApplication

## SYNOPSIS
Removes a client application from the applications kept for the session.

## SYNTAX

### PublicClient (Default)
```
Remove-MsalClientApplication [-PublicClientApplication] <IPublicClientApplication> [-WhatIf] [-Confirm]
 [<CommonParameters>]
```

### ConfidentialClient
```
Remove-MsalClientApplication [-ConfidentialClientApplication] <IConfidentialClientApplication> [-WhatIf]
 [-Confirm] [<CommonParameters>]
```

## DESCRIPTION
Removes an application from the session list used by Get-MsalToken and
Select-MsalClientApplication; the next call with the same settings builds a new application,
with an empty token cache unless the cache on disk is enabled.

An application that is not in the list is a terminating error
(RemoveMsalClientApplicationFailureNotFound).
The cmdlet supports WhatIf and Confirm.

## EXAMPLES

### EXAMPLE 1
```
Get-MsalClientApplication -ClientId '00000000-0000-0000-0000-000000000000' | Remove-MsalClientApplication
```

Removes every session application with this client id.

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

### -WhatIf
Shows what would happen if the cmdlet runs.
The cmdlet is not run.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases: wi

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Confirm
Prompts you for confirmation before running the cmdlet.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases: cf

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### Microsoft.Identity.Client.IPublicClientApplication, Microsoft.Identity.Client.IConfidentialClientApplication
## OUTPUTS

### None.
## NOTES

## RELATED LINKS

[Get-MsalClientApplication]()

[Clear-MsalTokenCache]()

