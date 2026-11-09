# Built-in environments, from microsoftgraph/msgraph-sdk-powershell issue #3468 / PR #3523.
# AzureCloudInstance: the MSAL enum value that maps onto the environment (none for USGovDoD,
# which shares the USGov authority host). Order matters: when only an authority host is known,
# the first environment with that host applies (USGov before USGovDoD).
@{
    Environments = @(
        @{ Name = 'Global'; AzureADEndpoint = 'https://login.microsoftonline.com'; GraphEndpoint = 'https://graph.microsoft.com'; AzureCloudInstance = 'AzurePublic' }
        @{ Name = 'USGov'; AzureADEndpoint = 'https://login.microsoftonline.us'; GraphEndpoint = 'https://graph.microsoft.us'; AzureCloudInstance = 'AzureUsGovernment' }
        @{ Name = 'USGovDoD'; AzureADEndpoint = 'https://login.microsoftonline.us'; GraphEndpoint = 'https://dod-graph.microsoft.us'; AzureCloudInstance = '' }
        @{ Name = 'China'; AzureADEndpoint = 'https://login.chinacloudapi.cn'; GraphEndpoint = 'https://microsoftgraph.chinacloudapi.cn'; AzureCloudInstance = 'AzureChina' }
        @{ Name = 'BleuCloud'; AzureADEndpoint = 'https://login.sovcloud-identity.fr'; GraphEndpoint = 'https://graph.svc.sovcloud.fr'; AzureCloudInstance = 'GovFr' }
        @{ Name = 'DelosCloud'; AzureADEndpoint = 'https://login.sovcloud-identity.de'; GraphEndpoint = 'https://graph.svc.sovcloud.de'; AzureCloudInstance = 'GovDe' }
        @{ Name = 'GovSGCloud'; AzureADEndpoint = 'https://login.sovcloud-identity.sg'; GraphEndpoint = 'https://graph.svc.sovcloud.sg'; AzureCloudInstance = 'GovSg' }
    )
}
