<#
.SYNOPSIS
    Decides what to do when a DLL of the module cannot be loaded because another version already is.
.DESCRIPTION
    Called from the catch block of Import-MsalAssembly, it reads the error record of its caller.
    When an assembly with the same name is loaded from outside the module (another module brought
    its own MSAL.NET, for instance), the dll.lenientLoading setting decides: keep the loaded one and
    record the conflict in the module state, or rethrow. With dll.lenientLoadingPrompt, the user is
    asked first, and the answer can be saved in the user config.
.EXAMPLE
    Resolve-MsalAssemblyLoadError $DllPath
    Rethrows the load error of this DLL, or records the conflict, depending on the settings.
.OUTPUTS
    None.
#>
function Resolve-MsalAssemblyLoadError {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingWriteHost', '', Justification = 'Shown only during an interactive prompt at import, to the user answering it.')]
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string] $AssemblyPath
    )

    ## Save ErrorRecord to throw later
    $ErrorRecord = $_

    ## Look for existing assembly
    [string] $AssemblyName = [System.IO.Path]::GetFileName($AssemblyPath)
    $Assembly = [System.AppDomain]::CurrentDomain.GetAssemblies().Where{ $AssemblyName -eq $_.ManifestModule } | Select-Object -First 1
    if (-not $Assembly) { throw $ErrorRecord }

    ## On older Windows OSes, the desktop DLL conflicts with itself so just ignore.
    if ($Assembly.Location.StartsWith($script:ModuleRoot)) { return }

    Write-Warning (@'
Assembly with same name "{0}" is already loaded:
{1}
'@ -f $AssemblyName, $Assembly.Location)

    ## Ask the user
    if ($script:ModuleConfig.'dll.lenientLoadingPrompt') {
        $DefaultChoice = if ($script:ModuleConfig.'dll.lenientLoading') { 1 } else { 2 }
        $DllLenientLoading = Write-MsalHostPrompt 'Ignore assembly conflict and continue importing module?' -Message 'Some module functionality will not work.' -Choices @('&Yes', '&No') -DefaultChoice $DefaultChoice -ErrorAction SilentlyContinue
        if ($DllLenientLoading -eq 1) {
            $script:ModuleConfig.'dll.lenientLoading' = $true

            $PersistModuleConfig = Write-MsalHostPrompt 'Remember settings?' -Message ('Module settings will be persisted in "{0}"' -f (Join-Path $script:ModuleState.ConfigDirectory 'config.json')) -DefaultChoice 2 -Choices @('&Yes', '&No') -ErrorAction SilentlyContinue
            if ($PersistModuleConfig -eq 1) {
                $script:ModuleConfig.'dll.lenientLoadingPrompt' = $false
                Export-MsalConfig
            }
            else {
                Write-Host @'

# You may also suppress this prompt by providing module settings on import:
Import-Module Posh-MSAL -ArgumentList @{ 'dll.lenientLoading' = $true; 'dll.lenientLoadingPrompt' = $false }

# Or defining the following environment variable:
${env:poshmsal.dll.lenientLoading} = $true # Continue Module Import

'@
            }
        }
        else { $script:ModuleConfig.'dll.lenientLoading' = $false }
    }

    ## Throw error if strict dll loading
    if (!$script:ModuleConfig.'dll.lenientLoading') { throw $ErrorRecord }
    $script:ModuleState.AssemblyConflicts.Add(('{0} {1} ({2})' -f $AssemblyName, $Assembly.GetName().Version, $Assembly.Location))

    return $Assembly.Location
}
