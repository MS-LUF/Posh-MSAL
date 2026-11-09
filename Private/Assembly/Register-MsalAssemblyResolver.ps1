<#
.SYNOPSIS
    Registers an AssemblyResolve handler that answers with the module's own DLLs on Windows PowerShell.
.DESCRIPTION
    The MSAL.NET closure asks for older versions of its dependencies than it ships, and Windows
    PowerShell has no binding redirects. The handler returns the module's DLL of the same simple
    name, whatever version is asked, and answers for the module's own DLLs only. It is built as an
    expression tree, not a scriptblock, because the event fires on threads with no runspace.
.EXAMPLE
    Register-MsalAssemblyResolver -Path (Join-Path $script:ModuleRoot 'lib/net472')
    Lets the net472 DLLs satisfy each other's version requests.
.OUTPUTS
    None.
#>
function Register-MsalAssemblyResolver {
    [CmdletBinding()]
    param (
        # Folder holding the module's DLLs for this edition.
        [Parameter(Mandatory = $true)]
        [string] $Path
    )

    ## Windows PowerShell has no binding redirects, and the MSAL.NET closure asks for older versions
    ## of its dependencies than it ships (MSAL asks for System.Memory 4.0.1.1, the package is
    ## 4.0.1.2). The handler returns the module's DLL for a simple name, whatever version is asked,
    ## and answers for the module's own DLLs only.
    $DataKey = 'Posh-MSAL.AssemblyResolver:{0}' -f $Path
    if ([System.AppDomain]::CurrentDomain.GetData($DataKey)) { return }

    $Map = New-Object 'System.Collections.Generic.Dictionary[string,string]' ([System.StringComparer]::OrdinalIgnoreCase)
    foreach ($Dll in Get-ChildItem -Path $Path -Filter '*.dll') { $Map[[System.IO.Path]::GetFileNameWithoutExtension($Dll.Name)] = $Dll.FullName }

    ## Built as an expression tree, not a scriptblock: the event fires on whatever thread loads the
    ## assembly, MSAL's thread-pool threads included, where no runspace exists.
    $Expression = [System.Linq.Expressions.Expression]
    $SenderParameter = $Expression::Parameter([object], 'sender')
    $ResolveArgsParameter = $Expression::Parameter([System.ResolveEventArgs], 'args')
    $PathVariable = $Expression::Variable([string], 'path')
    # [Expression]::New would be read as a constructor call by PowerShell: call the static method through reflection.
    $NewMethod = [System.Linq.Expressions.Expression].GetMethod('New', [type[]] @([System.Reflection.ConstructorInfo], [System.Linq.Expressions.Expression[]]))
    $NewAssemblyName = $NewMethod.Invoke($null, @([System.Reflection.AssemblyName].GetConstructor([type[]] @([string])), [System.Linq.Expressions.Expression[]] @($Expression::Property($ResolveArgsParameter, 'Name'))))
    $TryGetPath = $Expression::Call($Expression::Constant($Map), $Map.GetType().GetMethod('TryGetValue'), $Expression::Property($NewAssemblyName, 'Name'), $PathVariable)
    $LoadFrom = $Expression::Call([System.Reflection.Assembly].GetMethod('LoadFrom', [type[]] @([string])), $PathVariable)
    $Body = $Expression::Block([System.Reflection.Assembly], [System.Linq.Expressions.ParameterExpression[]] @($PathVariable), [System.Linq.Expressions.Expression[]] @($Expression::Condition($TryGetPath, $LoadFrom, $Expression::Constant($null, [System.Reflection.Assembly]))))
    $Handler = $Expression::Lambda([System.ResolveEventHandler], $Body, [System.Linq.Expressions.ParameterExpression[]] @($SenderParameter, $ResolveArgsParameter)).Compile()

    [System.AppDomain]::CurrentDomain.add_AssemblyResolve($Handler)
    [System.AppDomain]::CurrentDomain.SetData($DataKey, $true)
}
