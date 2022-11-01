param(
    [string]$parameterFile,
    [string]$SubscriptionName
)

Function Convert-ObjectToHashTable
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

function DownloadFromBlob 
{
<#
.SYNOPSIS
Compile a Policy Compliance report for a Nuance Line of Business

.DESCRIPTION
Powershell script to create an Azure Policy compliance report for a specified Nuance Line of Business.  The script will identify the Azure Subscriptions that are owned by the Nuance LOB,
collect the compliance report for the policy requested

.PARAMETER StorageAccountName
Parameter description
634
.PARAMETER ResourceGroupName
Parameter description

.PARAMETER ContainerName
Parameter description

.PARAMETER BlobName
Parameter description

.EXAMPLE
An example

.NOTES
General notes
#>
    [CmdletBinding()]
    param (
        $StorageAccountName, 
        $ResourceGroupName, 
        $ContainerName, 
        $BlobName,
        $TenantId,
        $SubscriptionId,
        $SubscriptionName
    )

    $Context = (Get-AzContext)
    ## if(($Context).Subscription.Name -inotmatch $SubscriptionName)
    if(($Context).Tenant.Id -inotmatch $TenantId)
    {
        try
        {
            Write-Output "INFO: Not connected to Tenant: $TenantId - Setting Context"
            #Set-AzContext -TenantId $TenantId -SubscriptionId $SubscriptionId | Out-Null   
            Write-Output "SUCCESS: Sucessfully connected to Tenant: $TenantId / Subscription: $SubscriptionName"
        }
        catch {
            Write-Output "ERROR: Unable to set Azure context to Tenant: $TenantId / Subscription: $SubscriptionName"
        }
    }
    else {
        Write-Output "INFO: Already connected to $TenantId."
    }

    Set-Location $env:TEMP

    try
    {
        Write-Output "INFO: Validating Storage Account"
        $script:StorageAccount = Get-AzStorageAccount -ResourceGroupName $ResourceGroupName -Name $StorageAccountName
        Write-Output "SUCCESS: Validation for Storage Account was successful!"
    }
    catch
    {
        Write-Output "Error: Unable to validate Storage Account"
    }
    try
    {
        Write-Output "INFO: Copying Storage Key"
        $script:acctKey = (Get-AzStorageAccountKey -ResourceGroupName $ResourceGroupName -Name $StorageAccountName | Where-Object {$_.KeyName -eq "key1"}).Value
        Write-Output "SUCCESS: Copy of Storage Key - Successful"
    }
    catch 
    {
        Write-Output "Error: Unable to copy Storage Key - FAILED"
    }
    try
    {   
        Write-Output "INFO: Setting Storage Context..."
        $script:storageContext = New-AzStorageContext -StorageAccountName $StorageAccountName -StorageAccountKey "$acctKey"
        Write-Output "SUCCESS: Setting Storage Context... Successful"
    }
    catch
    {
        Write-Output "Error: Unable to set Azure Storage Context - FAILED"
    }
    try
    {
        Write-Output "INFO: Importing blob content: $BlobName"
        $BlobContent = Get-AzStorageBlobContent -Container $ContainerName -Blob $BlobName -Context $storageContext -Force
        $Filename    = $BlobContent.Name
        Write-Output "SUCCESS: Successfully imported blob content: $Filename"
    }
    catch
    {
        Write-Output "Error: Unable to imported configuration file: $BlobName, from container: $ContainerName - FAILED"
    }
}#EndFunction:DownloadFromBlob

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
###################################################################################################################
## DO NOT EDIT ANY OF THE FOLLOWING VARIABLES:
$Error.Clear()
$ScriptRoot         = Split-Path $MyInvocation.MyCommand.Path
$StartTime          = Get-Date -Format "yyyyMMddHHmmss_"
$logDir             = $ScriptRoot + "\Logs\"
$transcriptFilename = $logdir + $StartTime + "Azure_$($LoB)_$($Application)_Transcript.log"
$logFile            = $logdir + $StartTime + "Azure_$($LoB)_$($Application)_Deployment.log"
$deploymentTemplate = "avd-HostPool-template.json"
###################################################################################################################
Write-Output "******* Azure Powershell deployment started *******"

## Being Login ##
try
{
    Write-Output "Connecting to Azure Root Tenant."
    $rootConnection = Get-AutomationConnection -Name "AzureRunAsConnection"
    Connect-AzAccount `
        -ServicePrincipal -Tenant $rootConnection.TenantID `
        -ApplicationID $rootConnection.ApplicationID `
        -CertificateThumbprint $rootConnection.CertificateThumbprint

    Write-Output "SUCCESS: Connecting to Azure using SP"
}
catch {
    Write-Output "ERROR: Unable to connect to Azure"
}

## Automation Variables containing StorageAccount values:
$StorageAccountName = Get-AutomationVariable -Name 'Automated-UserRole-Assignment-StorageAccount-Name'
$StorageResourceGroupName = Get-AutomationVariable -Name 'Automated-UserRole-Assignment-Storage-ResouceGroupName'
$StorageTenantId    = Get-AutomationVariable -Name 'Automated-UserRole-Assignment-Storage-TenantId'
$ContainerName      = "avdexpansion"
####################################################################################
Write-Output "INFO: Downloading file: $parameterFile from blob storage ..."
DownloadFromBlob `
    -StorageAccountName $StorageAccountName `
    -ResourceGroupName $StorageResourceGroupName `
    -ContainerName $ContainerName `
    -BlobName $parameterFile `
    -TenantId $StorageTenantId `
    -SubscriptionId "4f0c6183-3096-4614-bd36-d1ba8dddd55a" `
    -SubscriptionName "GTS.CS.MGMT.US.PROD"

Write-Output "INFO: Download: $parameterFile -> Done ..."

Write-Output "INFO: Downloading deployment template: $deploymentTemplate from blob storage ..."
DownloadFromBlob `
    -StorageAccountName $StorageAccountName `
    -ResourceGroupName $StorageResourceGroupName `
    -ContainerName $ContainerName `
    -BlobName $deploymentTemplate `
    -TenantId $StorageTenantId `
    -SubscriptionId "4f0c6183-3096-4614-bd36-d1ba8dddd55a" `
    -SubscriptionName "GTS.CS.MGMT.US.PROD"

Write-Output "INFO: Download: $deploymentTemplate -> Done ..."

$paramsJson = Get-Content -Path $parameterFile | ConvertFrom-Json
$deploymentConfig = $paramsJson.parameters

foreach($pool in $deploymentConfig)
{
    ## Tenant connectivity block:
    $currentContext = Get-AzContext
    $SubscriptionId = Get-AzSubscription -SubscriptionName $SubscriptionName
    $Subscription = $SubscriptionName
    $ResourceGroupName = $pool.ResourceGroupName
    $resourceGroupTags = $pool.hostPoolTags
    $tagHash = $resourceGroupTags| Convert-ObjectToHashTable

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

    verifyResourceGroup -ResourceGroupName $ResourceGroupName -Location $pool.location -tagValues $tagHash

    Write-Output "INFO: Starting Virtual Machine deployment -----------------------"
    try {
        Write-Output "INFO: Performing Validation for Region: $($pool.location) --------------------"
        $templateParamHash = Get-Content $parameterFile | ConvertFrom-Json | Convert-ObjectToHashTable
        Test-AzResourceGroupDeployment `
            -ResourceGroupName 'EUS.CS.AVD.Pilot.HostPools' `
            -TemplateFile "./$deploymentTemplate" `
            -vmAdministratorAccountPassword $advm1passwordSec `
            -administratorAccountPassword $dcJoinpasswordSec `
            -TemplateParameterObject $templateParamHash `
            -Verbose
    }
    catch {
        Write-Output "ERROR: Validation FAILED!"
    }

    try {
        Write-Output "INFO: Deploying Virtual Machine: $VMName in region:  $($pool.location)  --------------------"
        Write-Output "INFO: Performing Validation for Region: $($pool.location) --------------------"
        $templateParamHash = Get-Content $parameterFile | ConvertFrom-Json | Convert-ObjectToHashTable
        New-AzResourceGroupDeployment `
            -ResourceGroupName 'EUS.CS.AVD.Pilot.HostPools' `
            -TemplateFile "./$deploymentTemplate" `
            -vmAdministratorAccountPassword $advm1passwordSec `
            -administratorAccountPassword $dcJoinpasswordSec `
            -TemplateParameterObject $templateParamHash `
            -Verbose
 
    }
    catch {
        Write-Output "ERROR: Deployment FAILED!"
    } 
}

$adminPassword = 'V!rtu@l@dm1n'
$advm1passwordSec = ConvertTo-SecureString "$adminPassword" -asplaintext -force

$dcJoin = 'kr92"FgZ&qu$'
$dcJoinpasswordSec = ConvertTo-SecureString "$dcJoin" -asplaintext -force

New-AzResourceGroupDeployment -ResourceGroupName 'EUS.CS.AVD.Pilot.HostPools' -TemplateFile ./avd-HostPool-template.json  -vmAdministratorAccountPassword $advm1passwordSec -administratorAccountPassword $dcJoinpasswordSec -TemplateParameterFile ./avd-HostPool-parameters.json -vmTemplate "$templateParams" -Verbose
 
$vaultName = "WUS2-CS-Automation-VLT"
$vmAdministratorAccSecretEntry = "avdhostpool-vmAdministratorAccountPassword"
$vmAdministratorSecret = Get-AzKeyVaultSecret -VaultName $vaultName -Name $vmAdministratorAccSecretEntry
$vmAdministratorSecret.SecretValue

$decJoinSecretEntry = "avdhostpool-dcJoinSecret"
$decJoinSecret = Get-AzKeyVaultSecret -VaultName $vaultName -Name $decJoinSecretEntry
$decJoinSecret.SecretValue