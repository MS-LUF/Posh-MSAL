<#
.SYNOPSIS
    Creates the folders that do not exist yet, and returns the ones it created.
.DESCRIPTION
    Takes paths, DirectoryInfo objects, or FileInfo objects (for the file's folder). A relative path
    starts from BaseDirectory, by default the current PowerShell location, not the process folder.
.EXAMPLE
    Assert-MsalDirectory (Split-Path -Parent $ConfigPath)
    Creates the folder of the config file if it is missing.
.OUTPUTS
    System.IO.DirectoryInfo
#>
function Assert-MsalDirectory {
    [CmdletBinding()]
    [OutputType([System.IO.DirectoryInfo])]
    param (
        # Directories: paths, DirectoryInfo, or FileInfo (for the file's folder).
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, Position = 0)]
        [object[]] $InputObjects,
        # Folder that relative paths start from. Default: the current PowerShell location.
        [Parameter(Mandatory = $false, Position = 2)]
        [string] $BaseDirectory = (Get-Location).ProviderPath
    )

    ## Creates each folder that does not exist yet, and returns the ones it created.
    process {
        foreach ($InputObject in $InputObjects) {
            $DirectoryInfo = $null
            if ($InputObject -is [System.IO.DirectoryInfo]) { $DirectoryInfo = $InputObject }
            elseif ($InputObject -is [System.IO.FileInfo]) { $DirectoryInfo = $InputObject.Directory }
            elseif ($InputObject -is [string] -and $InputObject) {
                # .NET resolves a relative path against the process folder, not the PowerShell location.
                $Path = if ([System.IO.Path]::IsPathRooted($InputObject)) { $InputObject } else { Join-Path $BaseDirectory $InputObject }
                $DirectoryInfo = New-Object System.IO.DirectoryInfo $Path
            }
            if ($DirectoryInfo -and -not $DirectoryInfo.Exists) {
                Write-Output (New-Item $DirectoryInfo.FullName -ItemType Container)
            }
        }
    }
}
