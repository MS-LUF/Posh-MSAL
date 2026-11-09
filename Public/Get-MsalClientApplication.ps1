<#
.SYNOPSIS
    Gets the client applications kept for the session.
.DESCRIPTION
    Returns the applications that Get-MsalToken, Select-MsalClientApplication and
    Add-MsalClientApplication keep for the session, filtered by the parameters given. Without
    ClientSecret or ClientCertificate, both public and confidential applications are returned; with
    one of them, only the confidential applications built with that secret or certificate.

    TenantId and Authority match the tenant of the application's authority; Environment matches the
    authority host of that cloud.
.EXAMPLE
    Get-MsalClientApplication
    Lists every application kept for the session.
.EXAMPLE
    Get-MsalClientApplication -ClientId '00000000-0000-0000-0000-000000000000' -Environment 'BleuCloud'
    Lists the applications with this client id that sign in to Bleu.
.INPUTS
    System.String
.OUTPUTS
    Microsoft.Identity.Client.PublicClientApplication, Microsoft.Identity.Client.ConfidentialClientApplication
.LINK
    Select-MsalClientApplication
.LINK
    Add-MsalClientApplication
#>
function Get-MsalClientApplication {
    [CmdletBinding(DefaultParameterSetName = 'PublicClient')]
    [OutputType([Microsoft.Identity.Client.PublicClientApplication], [Microsoft.Identity.Client.ConfidentialClientApplication])]
    param
    (
        # Identifier of the client requesting the token.
        [Parameter(Mandatory = $false, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [string] $ClientId,
        # Secure secret of the client requesting the token.
        [Parameter(Mandatory = $false, ParameterSetName = 'ConfidentialClientSecret', ValueFromPipelineByPropertyName = $true)]
        [securestring] $ClientSecret,
        # Client assertion certificate of the client requesting the token.
        [Parameter(Mandatory = $false, ParameterSetName = 'ConfidentialClientCertificate', ValueFromPipelineByPropertyName = $true)]
        [System.Security.Cryptography.X509Certificates.X509Certificate2] $ClientCertificate,
        # Address to return to upon receiving a response from the authority.
        [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)]
        [uri] $RedirectUri,
        # Tenant identifier of the authority to issue token.
        [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)]
        [string] $TenantId,
        # Address of the authority to issue token.
        [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)]
        [uri] $Authority,
        # Only applications of this environment's cloud (Get-MsalEnvironment).
        [Parameter(Mandatory = $false)]
        [ArgumentCompleter( { $Word = $args[2]; (Get-MsalEnvironment).Name | Where-Object { $_ -like "$Word*" } })]
        [string] $Environment
    )

    process {
        $Filter = @{}
        foreach ($Key in 'ClientId', 'RedirectUri', 'TenantId', 'Authority') { if ($PSBoundParameters.ContainsKey($Key)) { $Filter[$Key] = $PSBoundParameters[$Key] } }
        if ($Environment) {
            try { $Filter['AuthorityHost'] = ([uri] (Get-MsalEnvironmentByName $Environment).AzureADEndpoint).Authority }
            catch { $PSCmdlet.ThrowTerminatingError((New-Object System.Management.Automation.ErrorRecord ($_.Exception, 'MsalEnvironmentNotFound', [System.Management.Automation.ErrorCategory]::ObjectNotFound, $Environment))) }
        }

        [System.Collections.Generic.List[Microsoft.Identity.Client.IClientApplicationBase]] $listClientApplications = New-Object System.Collections.Generic.List[Microsoft.Identity.Client.IClientApplicationBase]

        switch -Wildcard ($PSCmdlet.ParameterSetName) {
            "PublicClient*" {
                foreach ($PublicClientApplication in $PublicClientApplications) {
                    if (Test-MsalApplicationMatch $PublicClientApplication @Filter) {
                        $listClientApplications.Add($PublicClientApplication)
                    }
                }

            }
            "*" {
                foreach ($ConfidentialClientApplication in $ConfidentialClientApplications) {
                    if (Test-MsalApplicationMatch $ConfidentialClientApplication @Filter) {
                        switch ($PSCmdlet.ParameterSetName) {
                            "ConfidentialClientSecret" {
                                if ($ConfidentialClientApplication.AppConfig.ClientSecret -ceq (ConvertFrom-MsalSecureString $ClientSecret -Force)) {
                                    $listClientApplications.Add($ConfidentialClientApplication)
                                }
                                break
                            }
                            "ConfidentialClientCertificate" {
                                if ($ConfidentialClientApplication.AppConfig.ClientCredentialCertificate -eq $ClientCertificate) {
                                    $listClientApplications.Add($ConfidentialClientApplication)
                                }
                                break
                            }
                            Default {
                                $listClientApplications.Add($ConfidentialClientApplication)
                            }
                        }
                    }
                }
            }
        }

        return $listClientApplications
    }
}

