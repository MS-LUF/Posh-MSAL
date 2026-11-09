---
external help file: Posh-MSAL-help.xml
Module Name: Posh-MSAL
online version:
schema: 2.0.0
---

# Clear-MsalTokenCache

## SYNOPSIS
Forgets the client applications kept for the session, or deletes the token cache on disk.

## SYNTAX

```
Clear-MsalTokenCache [-FromDisk] [<CommonParameters>]
```

## DESCRIPTION
Without FromDisk, empties the session's list of client applications: their tokens held in memory
are lost, and the next Get-MsalToken builds new applications.

With FromDisk, deletes the token caches on disk instead and leaves the session's list alone: the
user and app caches, encrypted and unencrypted, their keyring entries on Linux, and the old
MSAL.PS cache file, so that it is not copied again.
Applications enabled with
Enable-MsalTokenCacheOnDisk then read an empty cache.

## EXAMPLES

### EXAMPLE 1
```
Clear-MsalTokenCache
```

Forgets every client application of the session.

### EXAMPLE 2
```
Clear-MsalTokenCache -FromDisk
```

Deletes the token cache on disk.

## PARAMETERS

### -FromDisk
Clear the token cache from disk.

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

### None.
## OUTPUTS

### None.
## NOTES

## RELATED LINKS

[Enable-MsalTokenCacheOnDisk]()

