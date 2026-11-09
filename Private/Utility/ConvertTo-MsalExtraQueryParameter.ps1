<#
.SYNOPSIS
    Converts a hashtable to the extra query parameters MSAL.NET takes.
.DESCRIPTION
    MSAL.NET's WithExtraQueryParameters takes a dictionary of name to (value, includeInCacheKey).
    Every value is kept out of the token cache key, as with the dictionary overload MSAL.NET
    deprecates.
.EXAMPLE
    ConvertTo-MsalExtraQueryParameter @{ domain_hint = 'contoso.com' }
    Returns the dictionary for WithExtraQueryParameters.
.OUTPUTS
    System.Collections.Generic.Dictionary`2[System.String,System.ValueTuple`2[System.String,System.Boolean]]
#>
function ConvertTo-MsalExtraQueryParameter {
    [CmdletBinding()]
    [OutputType([System.Collections.Generic.Dictionary[string, System.ValueTuple[string, bool]]])]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [hashtable] $InputObject
    )

    ## MSAL 4.92's WithExtraQueryParameters takes name -> (value, includeInCacheKey). The values stay
    ## out of the token cache key, as with the dictionary overload MSAL deprecates.
    $Dictionary = New-Object 'System.Collections.Generic.Dictionary[string, System.ValueTuple[string, bool]]'
    foreach ($Entry in $InputObject.GetEnumerator()) {
        $Dictionary.Add([string] $Entry.Key, (New-Object 'System.ValueTuple[string, bool]' ([string] $Entry.Value), $false))
    }
    # A dictionary is enumerable: emit it whole.
    Write-Output -InputObject $Dictionary -NoEnumerate
}
