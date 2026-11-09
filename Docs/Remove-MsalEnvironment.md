---
external help file: Posh-MSAL-help.xml
Module Name: Posh-MSAL
online version:
schema: 2.0.0
---

# Remove-MsalEnvironment

## SYNOPSIS
Removes a user-defined cloud (environment).

## SYNTAX

```
Remove-MsalEnvironment [-Name] <String[]> [-WhatIf] [-Confirm] [<CommonParameters>]
```

## DESCRIPTION
Removes an environment added with Add-MsalEnvironment from the session and from the
environments.json file of the Posh-MSAL folder of ApplicationData.
Built-in environments cannot be
removed.
Client applications already created for that cloud keep working.

## EXAMPLES

### EXAMPLE 1
```
Remove-MsalEnvironment -Name 'Contoso'
```

Removes the Contoso environment.

## PARAMETERS

### -Name
Name of the user-defined environment to remove.

```yaml
Type: String[]
Parameter Sets: (All)
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: True (ByPropertyName, ByValue)
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

### System.String
## OUTPUTS

### None.
## NOTES

## RELATED LINKS

[Add-MsalEnvironment]()

