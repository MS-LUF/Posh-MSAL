---
external help file: Posh-MSAL-help.xml
Module Name: Posh-MSAL
online version:
schema: 2.0.0
---

# Get-MsalAccount

## SYNOPSIS
Gets the accounts in the token cache of a client application.

## SYNTAX

### ClientApplication
```
Get-MsalAccount [-ClientApplication] <IClientApplicationBase> [-Username <String>] [<CommonParameters>]
```

### Accounts
```
Get-MsalAccount [-Accounts] <IAccount[]> [-Username <String>] [<CommonParameters>]
```

## DESCRIPTION
Returns the accounts that signed in through the application and are still in its user token
cache, in memory, or on disk when Enable-MsalTokenCacheOnDisk was used.
Username keeps only the
account with that user principal name.

To get a token for one of them from the cache, give its Username to Get-MsalToken -Silent
-LoginHint.

## EXAMPLES

### EXAMPLE 1
```
Get-MsalClientApplication -ClientId '00000000-0000-0000-0000-000000000000' | Get-MsalAccount
```

Lists the accounts cached by the session's applications with this client id.

### EXAMPLE 2
```
Get-MsalAccount $ClientApplication -Username 'user@contoso.com'
```

Gets one account from the application's cache.

## PARAMETERS

### -ClientApplication
Client application whose user token cache is read.

```yaml
Type: IClientApplicationBase
Parameter Sets: ClientApplication
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### -Accounts
Accounts to filter, such as the output of an earlier Get-MsalAccount.

```yaml
Type: IAccount[]
Parameter Sets: Accounts
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### -Username
The username in UserPrincipalName (UPN) format.

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

### Microsoft.Identity.Client.IClientApplicationBase, Microsoft.Identity.Client.IAccount
## OUTPUTS

### Microsoft.Identity.Client.IAccount
## NOTES

## RELATED LINKS

[Get-MsalToken]()

