---
external help file: Posh-MSAL-help.xml
Module Name: Posh-MSAL
online version:
schema: 2.0.0
---

# Set-MsalEnvironment

## SYNOPSIS
Changes a user-defined cloud (environment).

## SYNTAX

```
Set-MsalEnvironment [-Name] <String> [-AzureADEndpoint <Uri>] [-GraphEndpoint <Uri>]
 [-DisableInstanceDiscovery] [-WhatIf] [-Confirm] [<CommonParameters>]
```

## DESCRIPTION
Changes the endpoints or the instance discovery setting of an environment added with
Add-MsalEnvironment, and saves it.
Parameters not given keep their value.
Built-in environments
cannot be changed.
Client applications already created keep the authority they were built with.

## EXAMPLES

### EXAMPLE 1
```
Set-MsalEnvironment -Name 'Contoso' -GraphEndpoint 'https://graph2.contoso.com'
```

Changes the Graph endpoint, and so the default scope, of the Contoso environment.

### EXAMPLE 2
```
Set-MsalEnvironment -Name 'Contoso' -DisableInstanceDiscovery:$false
```

Turns instance discovery back on for the Contoso environment.

## PARAMETERS

### -Name
Name of the user-defined environment to change.

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
New authority host, e.g.
https://login.contoso.com.

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

### -GraphEndpoint
New Microsoft Graph endpoint, which gives the default scope.

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

### -DisableInstanceDiscovery
Turn off MSAL instance discovery (and authority validation) for this environment; -DisableInstanceDiscovery:$false turns it back on.

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

[Add-MsalEnvironment]()

