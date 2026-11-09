---
external help file: Posh-MSAL-help.xml
Module Name: Posh-MSAL
online version:
schema: 2.0.0
---

# Get-MsalEnvironment

## SYNOPSIS
Gets the clouds (environments) Posh-MSAL can sign in to.

## SYNTAX

```
Get-MsalEnvironment [[-Name] <String[]>] [<CommonParameters>]
```

## DESCRIPTION
Returns the built-in environments (Global, USGov, USGovDoD, China, BleuCloud, DelosCloud,
GovSGCloud) and the user-defined ones added with Add-MsalEnvironment.
An environment gives the
authority host, the default scope (the Graph endpoint followed by /.default) and, on Windows
PowerShell, the default redirect URI, for the Environment parameter of
New-MsalClientApplication, Select-MsalClientApplication and Get-MsalToken.

A name without wildcards that matches no environment is an error (MsalEnvironmentNotFound).

## EXAMPLES

### EXAMPLE 1
```
Get-MsalEnvironment
```

Lists every environment.

### EXAMPLE 2
```
Get-MsalEnvironment -Name 'BleuCloud'
```

Gets the Bleu environment.

### EXAMPLE 3
```
Get-MsalEnvironment -Name 'US*'
```

Gets the two US Government environments.

## PARAMETERS

### -Name
Name of the environment; wildcards are allowed.

```yaml
Type: String[]
Parameter Sets: (All)
Aliases:

Required: False
Position: 1
Default value: *
Accept pipeline input: True (ByPropertyName, ByValue)
Accept wildcard characters: True
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### System.String
## OUTPUTS

### System.Management.Automation.PSCustomObject
## NOTES

## RELATED LINKS

[Add-MsalEnvironment]()

