param(
    [Parameter(Mandatory=$true, HelpMessage='The full path including the file name of the parameter file located in Azure Storage to deploy')]
    [string]$parameterFile,

    [Parameter(Mandatory=$true, HelpMessage='The full path including the file name of the template used for the deployment')]
    [string]$deploymentTemplate,

    [Parameter(Mandatory=$true, HelpMessage='The name of the Subscription to deploy the AVD pool to')]
    [string]$SubscriptionName,

    [Parameter(Mandatory=$true, HelpMessage='The name of the Resource Group to deploy the AVD pool into')]
    [string]$ResourceGroupName
)

function Convert-ObjectToHashTable
{
    [CmdletBinding()]
    param
    (
        [parameter(Mandatory=$true,ValueFromPipeline=$true)]
        [pscustomobject] $Object
    )
    $HashTable = @{}
    $ObjectMembers = Get-Member -InputObject $Object -MemberType *Property
    foreach ($Member in $ObjectMembers) 
    {
        $HashTable.$($Member.Name) = $Object.$($Member.Name)
    }
    return $HashTable
}#EndFunction:Convert-ObjectToHashTable

function GetConfigFromVault
{
    param(
        [string]$subscriptionName,
        [string]$vaultName,
        [string]$secretName
    )
    $Context = (Get-AzContext)
    if(($Context).Subscription.Name -inotmatch $subscriptionName)
    {
        try
        {
            ## Write-Output "INFO: Switching to target Subscription: $subscriptionName"
            $TargetSubscription = Get-AzSubscription -SubscriptionName $subscriptionName -ErrorAction SilentlyContinue
            $SetContext = Set-AzContext -SubscriptionId ($TargetSubscription).SubscriptionId
            $SetContext | Out-Null
            ## Write-Output "SUCCESS: Switched to target Subscription: $subscriptionName"
        }
        catch {
            $message = $_
            Write-Output "Error: Unable to switch Subscription context to target Subscription: $SubscriptionName"
            Write-Output "$message"
        }
    }

    try
    {
        ## Write-Output "INFO: Obtaining rotation config from Vault: $vaultName"
        $secretVal = Get-AzKeyVaultSecret -VaultName $vaultName -Name $secretName -AsPlainText
        $secretVal
    }
    catch {
        $message = $_
        Write-Output "Error: Unable to obtain rotation config from Vault: $vaultName / Entry: $secretName"
        Write-Output "$message" 
    }
}#EndFunction:GetConfigFromVault

function Add-VaultFirewallRule
{
    param(
        $KeyVaultName,
        $callerIpaddress
    )
    ## Variable generate password based on firewall:
    $NetworkCheck = $null
    $script:removeVaultFWIPAddress = $null
 
    Write-Output "INFO: Checking the Firewall Configuration for Keyvault: $KeyVaultName to ADD IP: $callerIpaddress" 

    $check_keyvault = Get-AzKeyVault -VaultName $KeyVaultName | Select-Object NetworkAcls,ResourceGroupName
    [String]$check_keyvault_network = ($check_keyvault.NetworkAcls).DefaultAction.ToString()

    if($check_keyvault_network.ToLower().Trim() -eq "deny")
    {
       $checkIP = (Get-AzKeyVault -VaultName $KeyVaultName).NetworkAcls.IpAddressRanges -match $callerIpaddress
       ## $checkIP  = $check_IP | Where-Object { $_ -match $callerIpaddress}
       if($checkIP) 
       {
            Write-Output "INFO: IP $callerIpaddress already exists in the Keyvault: $KeyVaultName"
            $NetworkCheck = "Yes"
            $script:removeVaultFWIPAddress = $true
       }
       else {
            Write-Output "INFO: Adding the IP for the Keyvault $KeyVaultName firewall"
            Add-AzKeyVaultNetworkRule `
                -VaultName $KeyVaultName `
                -ResourceGroupName $check_keyvault.ResourceGroupName `
                -IpAddressRange $callerIpaddress
            Start-Sleep -Seconds 10

           $checkAddIp = (Get-AzKeyVault -VaultName $KeyVaultName).NetworkAcls.IpAddressRanges -match $callerIpaddress
           if($checkAddIp)
           {
                Write-Output "SUCCESSS: Sucessfully Added the IP $callerIpaddress into the Keyvault: $KeyVaultName"
                #Setting Variable to generate secret
                $NetworkCheck = "Yes"
                $script:removeVaultFWIPAddress = $true
           }
       }
    }
    if($check_keyvault_network.ToLower().Trim() -eq "allow")
    {
        $NetworkCheck = "Yes"
        $script:removeVaultFWIPAddress = $null
        Write-Output "INFO: Network ACLs for Vault: $KeyVaultName is DISABLED - SKIPPING..."
    }
    Return $NetworkCheck  
}#EndFunction:Add-VaultFirewallRule
 
function Remove-VaultFirewallRule
{
    param(
        $KeyVaultName,
        $callerIpaddress
    )
    Write-Output "INFO: Checking the Firewall Configuration for Keyvault: $KeyVaultName to REMOVE IP: $callerIpaddress"
 
    $check_keyvault = Get-AzKeyVault -VaultName $KeyVaultName | Select-Object NetworkAcls,ResourceGroupName
    [String]$check_keyvault_network = ($check_keyvault.NetworkAcls).DefaultAction.ToString()

    if($check_keyvault_network.ToLower().Trim() -eq "deny")
    {
       $checkIP = (Get-AzKeyVault -VaultName $KeyVaultName).NetworkAcls.IpAddressRanges -match $callerIpaddress
       if($checkIP) 
       {
           try {
                Remove-AzKeyVaultNetworkRule -VaultName $KeyVaultName  -ResourceGroupName $check_keyvault.ResourceGroupName -IpAddressRange $callerIpaddress 
                Write-Output "SUCCESS: Removed the IP $callerIpaddress  from friewall of Keyvault: $KeyVaultName"
           }
           catch {
               Write-Output "ERROR: Unable to remove IP Address: $callerIpaddress from Vault: $KeyVaultName"
           }
       }
    }
}#EndFunction:Remove-VaultFirewallRule

function verifyResourceGroup
{
<#
    .SYNOPSIS
        Create a new Azure Resource Group
               
    .DESCRIPTION
        Create a new resource group in Azure
               
    .EXAMPLE
        verifyResourceGroup -Name NameofResourceGroup -location eastus
               
    .Notes
        Validates if existing RG exists and will create a new Resource Group if one does not exists
 #>
 param(
    [Parameter( Mandatory=$true, HelpMessage='The Name of the Resource Group to deploy')]
        [string]$ResourceGroupName,
             
    [Parameter( Mandatory=$true, HelpMessage='The location to store the Resource Group in')]
        [string]$Location,
        
        $tagValues
)
$rgExists = Get-AzResourceGroup -Name $ResourceGroupName -ErrorAction 'SilentlyContinue'
    if(-not $rgExists)
    {
        try {
            Write-Output "Creating Resource Group $ResourceGroupName"
            New-AzResourceGroup -Name $ResourceGroupName `
                            -Location $Location `
                            -Tag $tagValues 
            Write-Output "Resource Group: $ResourceGroupName has been added successfully" 
        }
        catch [System.Management.Automation.PSInvalidOperationException]
        {
            Write-Error "Error: $($error[0].Exception)"
            Write-Output "Unable to add Resource Group: $ResourceGroupName - FAILED!" 
            Exit
        }
    }
} #EndFunction verifyResourceGroup 

function Get-AzTemplateParameters
{
    param(
      [string]
      $ParametersFilePath,
  
      [hashtable]
      $TemplateParameterObject = @{}
    )
  
    if (!$ParametersFilePath) {
      return $TemplateParameterObject
    }
  
    $parameterFileJson = (Get-Content -Raw $ParametersFilePath | ConvertFrom-Json)
    $parameters = @{}
    $keys = ($parameterFileJson.parameters | get-member -MemberType NoteProperty | ForEach-Object {$_.Name})
    foreach ($key in $keys) {
      $parameters[$key] = $parameterFileJson.parameters.$key.value
    }
    foreach ($key in $TemplateParameterObject.Keys) {
      if ($parameters.ContainsKey($key)) {
        $parameters.Remove($key)
      }
    }
  
    return $parameters + $TemplateParameterObject
}#EndFunction: Get-AzTemplateParameters
Write-Output "******* Azure Powershell deployment started *******"
###################################################################################################################
## DO NOT EDIT ANY OF THE FOLLOWING VARIABLES:
$rootSubscriptionId = "4f0c6183-3096-4614-bd36-d1ba8dddd55a"
$vaultName = "WUS2-CS-Automation-VLT" ## Vault Name:
$dcJoinSecretEntry = "avdhostpool-dcJoinSecret" ## DC Join secrets:
$vmAdministratorAccSecretEntry = "avdhostpool-vmAdministratorAccountPassword" ## Virtaul Machine secrets:
###################################################################################################################
## Parameter intake:
$paramsJson = Get-Content -Path $parameterFile | ConvertFrom-Json #| Convert-ObjectToHashTable
$deploymentConfig = $paramsJson.parameters

## Capture the hosts IP Address - will be added/removed from the vault access policy:
$HostedIPAddress = Invoke-RestMethod http://ipinfo.io/json | Select-Object -ExpandProperty ip
Write-Output "INFO: IPAddress: $HostedIPAddress"

## Ensure we are in the correct subscription to retrieve our secrets:
$currentContext = Get-AzContext
if($currentContext.Subscription.Id -inotmatch $rootSubscriptionId)
{
    try
    {
        Write-Output "INFO: Setting context to $rootSubscriptionId"
        Set-AzContext -SubscriptionId $rootSubscriptionId
        Write-Output "SUCCESS: Sucessfully connected to Subscription: $rootSubscriptionId"
    }
    catch {
        Write-Output "ERROR: Unable to set Azure context to Subscription: $rootSubscriptionId"
    }
}
else {
    Write-Output "INFO: Already connected to $rootSubscriptionId"
}
 
####################################################################
## START - VAULT SECRET RETRIEVAL:
Add-VaultFirewallRule -KeyVaultName $vaultName -callerIpaddress "$HostedIPAddress"

## VM Secret:
$vmAdministratorSecret = Get-AzKeyVaultSecret -VaultName $vaultName -Name $vmAdministratorAccSecretEntry -AsPlainText
$vmAdminSecretSec = ConvertTo-SecureString "$vmAdministratorSecret" -asplaintext -force
## DC Secret:
$dcJoinSecret = Get-AzKeyVaultSecret -VaultName $vaultName -Name $dcJoinSecretEntry -AsPlainText
$dcJoinpasswordSec = ConvertTo-SecureString "$dcJoinSecret" -asplaintext -force
Remove-VaultFirewallRule -KeyVaultName $vaultName -callerIpaddress "$HostedIPAddress"
## COMPLETE 
####################################################################

## Loop through our parameters file:
foreach($pool in $deploymentConfig)
{
    ## Tenant connectivity block:
    $currentContext = Get-AzContext
    $SubscriptionId = Get-AzSubscription -SubscriptionName $SubscriptionName
    $resourceGroupTags = $pool.Tags.value
    $tagHash = $resourceGroupTags| Convert-ObjectToHashTable
    $tmpDate = (Get-Date).AddDays(1)
    $tokenExpirationTime = (Get-Date $tmpDate -Format u).Replace(' ','T')

    if($currentContext.Subscription.Id -inotmatch $SubscriptionId)
    {
        try
        {
            Write-Output "INFO: Setting context to $SubscriptionId"
            Set-AzContext -TenantId $SourceTenantID -SubscriptionId $SubscriptionId
            Write-Output "SUCCESS: Sucessfully connected to Tenant: $SourceTenantID / Subscription: $SubscriptionId"
        }
        catch {
            Write-Output "ERROR: Unable to set Azure context to Tenant: $SourceTenantID / Subscription: $SubscriptionId"
        }
    }
    else {
        Write-Output "INFO: Already connected to $SubscriptionId"
    }

    verifyResourceGroup -ResourceGroupName $ResourceGroupName -Location $pool.location.value -tagValues $tagHash

    try {
        Write-Output "INFO: Validatinmg AVD HostPool: $($pool.hostpoolName.value) deployment for Region: $($pool.location.value) --------------------"
        Test-ResourceGroupName $ResourceGroupName -TemplateFile $deploymentTemplate -vmAdministratorAccountPassword $vmAdminSecretSec -administratorAccountPassword $dcJoinpasswordSec -TemplateParameterFile $parameterFile -tokenExpirationTime $tokenExpirationTime -Verbose
        Write-Output "SUCCESS: Pool is being deployed to Resource Group: $ResourceGroupName"
    }
    catch {
        $ErrorMessage = $_
        Write-Output "ERROR: Validation FAILED!"
        Write-Output $ErrorMessage
    }

    try {
        Write-Output "INFO: Validatinmg AVD HostPool: $($pool.hostpoolName.value) deployment for Region: $($pool.location.value) --------------------"
        New-AzResourceGroupDeployment -ResourceGroupName $ResourceGroupName -TemplateFile $deploymentTemplate -vmAdministratorAccountPassword $vmAdminSecretSec -administratorAccountPassword $dcJoinpasswordSec -TemplateParameterFile $parameterFile -tokenExpirationTime $tokenExpirationTime -Verbose
        Write-Output "SUCCESS: Pool is being deployed to Resource Group: $ResourceGroupName"
    }
    catch {
        $ErrorMessage = $_
        Write-Output "ERROR: Validation FAILED!"
        Write-Output $ErrorMessage
    }
}