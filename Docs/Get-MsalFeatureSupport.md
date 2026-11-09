---
external help file: Posh-MSAL-help.xml
Module Name: Posh-MSAL
online version:
schema: 2.0.0
---

# Get-MsalFeatureSupport

## SYNOPSIS
Shows what works on this machine and which MSAL.NET version is loaded.

## SYNTAX

```
Get-MsalFeatureSupport [<CommonParameters>]
```

## DESCRIPTION
Returns what the module found when it was imported: whether the embedded browser window, device
code, the token cache on disk and the authentication broker are available on this platform and
PowerShell edition, the version of MSAL.NET loaded, and the assembly conflicts met while loading
it, such as another module having loaded its own MSAL.NET first.

## EXAMPLES

### EXAMPLE 1
```
Get-MsalFeatureSupport
```

Shows the features available in this session.

## PARAMETERS

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### None.
## OUTPUTS

### System.Management.Automation.PSCustomObject
## NOTES

## RELATED LINKS
