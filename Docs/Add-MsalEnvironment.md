---
external help file: Posh-MSAL-help.xml
Module Name: Posh-MSAL
online version:
schema: 2.0.0
---

# Add-MsalEnvironment

## SYNOPSIS
Adds a user-defined cloud (environment).

## SYNTAX

```
Add-MsalEnvironment [-Name] <String> -AzureADEndpoint <Uri> -GraphEndpoint <Uri> [-DisableInstanceDiscovery]
 [-WhatIf] [-Confirm] [<CommonParameters>]
```

## DESCRIPTION
Adds an environment for a cloud the built-in ones do not cover, and saves it in the
environments.json file of the Posh-MSAL folder of ApplicationData, so that later sessions have
it.
The endpoints must be https URLs with a host only, and the name must not be taken.

DisableInstanceDiscovery is only needed for an authority host MSAL.NET does not know.
It also
turns off MSAL's authority validation, so only use it for an authority you trust.

## EXAMPLES

### EXAMPLE 1
```
Add-MsalEnvironment -Name 'Contoso' -AzureADEndpoint 'https://login.contoso.com' -GraphEndpoint 'https://graph.contoso.com'
```

Adds an environment, then usable with Get-MsalToken -Environment Contoso.

## PARAMETERS

### -Name
Name of the environment (letters, digits, "-" and "_").

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -AzureADEndpoint
Authority host, e.g.
https://login.microsoftonline.com.

```yaml
Type: Uri
Parameter Sets: (All)
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -GraphEndpoint
Microsoft Graph endpoint, which gives the default scope, e.g.
https://graph.microsoft.com.

```yaml
Type: Uri
Parameter Sets: (All)
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -DisableInstanceDiscovery
Turn off MSAL instance discovery (and authority validation) for this environment.

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

### System.Management.Automation.PSObject
## OUTPUTS

### System.Management.Automation.PSCustomObject
## NOTES

## RELATED LINKS

[Get-MsalEnvironment]()

[Set-MsalEnvironment]()

[Remove-MsalEnvironment]()

