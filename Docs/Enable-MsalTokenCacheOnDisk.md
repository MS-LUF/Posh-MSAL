---
external help file: Posh-MSAL-help.xml
Module Name: Posh-MSAL
online version:
schema: 2.0.0
---

# Enable-MsalTokenCacheOnDisk

## SYNOPSIS
Makes a client application keep its tokens on disk, encrypted, across sessions.

## SYNTAX

### PublicClient (Default)
```
Enable-MsalTokenCacheOnDisk [-PublicClientApplication] <IPublicClientApplication> [-AllowUnencryptedStorage]
 [-PassThru] [<CommonParameters>]
```

### ConfidentialClient
```
Enable-MsalTokenCacheOnDisk [-ConfidentialClientApplication] <IConfidentialClientApplication>
 [-AllowUnencryptedStorage] [-PassThru] [<CommonParameters>]
```

## DESCRIPTION
Registers the application's token caches with the Posh-MSAL cache on disk, shared by every
application and every PowerShell session of the user, through
Microsoft.Identity.Client.Extensions.Msal.
The cache is encrypted with DPAPI on Windows and kept
in the keyring (libsecret) on Linux, in the Posh-MSAL folder of LocalApplicationData.
Signed-in
accounts go to the user token cache; the tokens of confidential clients go to a separate app
token cache.

The first time on Windows, an MSAL.PS cache found in the MSAL.PS folder of LocalApplicationData
is copied into the user token cache; the old file is not changed.

When the cache cannot be encrypted, as on Linux without a keyring (SSH or headless sessions), the
cmdlet fails with MsalTokenCacheNotProtected unless AllowUnencryptedStorage is given; it then
keeps a plain file readable by the user's account, and says so with a warning.

On a platform with no cache on disk, it warns and the tokens stay in memory.

## EXAMPLES

### EXAMPLE 1
```
Select-MsalClientApplication -ClientId '00000000-0000-0000-0000-000000000000' -TenantId 'contoso.onmicrosoft.com' | Enable-MsalTokenCacheOnDisk
```

Keeps the tokens of the application Get-MsalToken uses for this client id and tenant.

### EXAMPLE 2
```
$ClientApplication | Enable-MsalTokenCacheOnDisk -AllowUnencryptedStorage -PassThru
```

On a host with no keyring, keeps the cache in a plain file and returns the application.

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

### -AllowUnencryptedStorage
Store the cache in a plain file when it cannot be encrypted on this system.

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

### With -PassThru, the application; otherwise nothing.
## NOTES

## RELATED LINKS

[Clear-MsalTokenCache]()

[Select-MsalClientApplication]()

