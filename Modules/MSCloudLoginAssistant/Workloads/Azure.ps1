function Connect-MSCloudLoginAzure
{
    [CmdletBinding()]
    param()

    $WarningPreference = 'SilentlyContinue'
    $InformationPreference = 'SilentlyContinue'
    $ProgressPreference = 'SilentlyContinue'
    $source = 'Connect-MSCloudLoginAzure'

    if ($Script:MSCloudLoginConnectionProfile.Azure.AuthenticationType -eq 'ServicePrincipalWithThumbprint')
    {
        Add-MSCloudLoginAssistantEvent -Message "Attempting to connect to Azure using AAD App {$ApplicationID}" -Source $source
        try
        {
            Add-MSCloudLoginAssistantEvent -Message "Azure Connection Profile = $($Script:MSCloudLoginConnectionProfile.Azure | Out-String)" -Source $source
            try
            {
                Connect-AzAccount -ApplicationId $Script:MSCloudLoginConnectionProfile.Azure.ApplicationId `
                                -TenantId $Script:MSCloudLoginConnectionProfile.Azure.TenantId `
                                -CertificateThumbprint $Script:MSCloudLoginConnectionProfile.Azure.CertificateThumbprint `
                                -Environment $Script:MSCloudLoginConnectionProfile.Azure.EnvironmentName | Out-Null
            }
            catch
            {
                Add-MSCloudLoginAssistantEvent -Message $_ -Source $source -EntryType 'Error'
            }
            $Script:MSCloudLoginConnectionProfile.Azure.ConnectedDateTime = [System.DateTime]::Now.ToString()
            $Script:MSCloudLoginConnectionProfile.Azure.Connected = $true
            $Script:MSCloudLoginConnectionProfile.Azure.MultiFactorAuthentication = $false
            Add-MSCloudLoginAssistantEvent -Message "Successfully connected to Azure using AAD App {$ApplicationID}" -Source $source
        }
        catch
        {
            throw $_
        }
    }
    elseif ($Script:MSCloudLoginConnectionProfile.Azure.AuthenticationType -eq 'CredentialsWithApplicationId' -or
                $Script:MSCloudLoginConnectionProfile.Azure.AuthenticationType -eq 'Credentials' -or
                $Script:MSCloudLoginConnectionProfile.Azure.AuthenticationType -eq 'CredentialsWithTenantId')
    {
        try
        {
            if ([System.String]::IsNullOrEmpty($Script:MSCloudLoginConnectionProfile.Azure.TenantId))
            {
                $Script:MSCloudLoginConnectionProfile.Azure.TenantId = $Script:MSCloudLoginConnectionProfile.Azure.Credentials.UserName.Split('@')[1]
            }
            Add-MSCloudLoginAssistantEvent -Message "Attempting to connect to Azure using Credentials" -Source $source
            Connect-AzAccount -Credential $Script:MSCloudLoginConnectionProfile.Azure.Credentials `
                              -Environment $Script:MSCloudLoginConnectionProfile.Azure.EnvironmentName `
                              -ErrorAction Stop | Out-Null
            $Script:MSCloudLoginConnectionProfile.Azure.ConnectedDateTime = [System.DateTime]::Now.ToString()
            $Script:MSCloudLoginConnectionProfile.Azure.Connected = $true
            $Script:MSCloudLoginConnectionProfile.Azure.MultiFactorAuthentication = $false
            Add-MSCloudLoginAssistantEvent -Message "Successfully connected to Azure using Credentials" -Source $source
        }
        catch
        {
            try
            {
                Add-MSCloudLoginAssistantEvent -Message "Attempting to connect to Azure using Credentials (MFA)" -Source $source
                Connect-AzAccount
                $Script:MSCloudLoginConnectionProfile.Azure.ConnectedDateTime = [System.DateTime]::Now.ToString()
                $Script:MSCloudLoginConnectionProfile.Azure.Connected = $true
                $Script:MSCloudLoginConnectionProfile.Azure.MultiFactorAuthentication = $true
                Add-MSCloudLoginAssistantEvent -Message "Successfully connected to Azure using Credentials (MFA)" -Source $source
            }
            catch
            {
                throw $_
            }
        }
    }
    elseif ($Script:MSCloudLoginConnectionProfile.Azure.AuthenticationType -eq 'AccessTokens')
    {
        Add-MSCloudLoginAssistantEvent -Message "Attempting to connect to Azure using Access Token" -Source $source
        Connect-AzAccount -Tenant $Script:MSCloudLoginConnectionProfile.Azure.TenantId `
                          -Environment $Script:MSCloudLoginConnectionProfile.Azure.EnvironmentName `
                          -AccessToken $Script:MSCloudLoginConnectionProfile.Azure.AccessTokens | Out-Null
        $Script:MSCloudLoginConnectionProfile.Azure.ConnectedDateTime = [System.DateTime]::Now.ToString()
        $Script:MSCloudLoginConnectionProfile.Azure.Connected = $true
        $Script:MSCloudLoginConnectionProfile.Azure.MultiFactorAuthentication = $false
        Add-MSCloudLoginAssistantEvent -Message "Successfully connected to Azure using Access Token" -Source $source
    }
    elseif ($Script:MSCloudLoginConnectionProfile.Azure.AuthenticationType -eq 'Identity')
    {
        Add-MSCloudLoginAssistantEvent -Message 'Attempting to connect to Azure using Managed Identity' -Source $source
        try
        {
            if ($NULL -eq $Script:MSCloudLoginConnectionProfile.OrganizationName)
            {
                $Script:MSCloudLoginConnectionProfile.OrganizationName = Get-MSCloudLoginOrganizationName -Identity
            }

            Connect-AzAccount-TenantId $Script:MSCloudLoginConnectionProfile.OrganizationName `
                -Identity `
                -EnvironmentName $Script:MSCloudLoginConnectionProfile.Azure.EnvironmentName | Out-Null

            $Script:MSCloudLoginConnectionProfile.ExchangeOnline.ConnectedDateTime = [System.DateTime]::Now.ToString()
            $Script:MSCloudLoginConnectionProfile.ExchangeOnline.Connected = $false
            $Script:MSCloudLoginConnectionProfile.ExchangeOnline.MultiFactorAuthentication = $false
            Add-MSCloudLoginAssistantEvent -Message 'Successfully connected to Azure using Managed Identity' -Source $source
        }
        catch
        {
            throw $_
        }
    }
    else
    {
        throw "Specified authentication method is not supported."
    }
}
