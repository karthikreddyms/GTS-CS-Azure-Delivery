@description('The base URI where artifacts required by this template are located.')
param nestedTemplatesLocation string = 'https://wvdportalstorageblob.blob.core.windows.net/galleryartifacts/armtemplates/Hostpool_3-9-2022/nestedTemplates/'

@description('The base URI where artifacts required by this template are located.')
param artifactsLocation string

@description('The name of the Hostpool to be created.')
param hostpoolName string

@description('The friendly name of the Hostpool to be created.')
param hostpoolFriendlyName string = ''

@description('The description of the Hostpool to be created.')
param hostpoolDescription string = ''

@description('The storage uri to put the diagnostic logs')
param hostpoolDiagnosticSettingsStorageAccount string = ''

@description('The description of the Hostpool to be created.')
param hostpoolDiagnosticSettingsLogAnalyticsWorkspaceId string = ''

@description('The event hub name to send logs to')
param hostpoolDiagnosticSettingsEventHubName string = ''

@description('The event hub policy to use')
param hostpoolDiagnosticSettingsEventHubAuthorizationId string = ''

@description('Categories of logs to be created for hostpools')
param hostpoolDiagnosticSettingsLogCategories array = [
  'Checkpoint'
  'Error'
  'Management'
  'Connection'
  'HostRegistration'
  'AgentHealthStatus'
]

@description('Categories of logs to be created for app groups')
param appGroupDiagnosticSettingsLogCategories array = [
  'Checkpoint'
  'Error'
  'Management'
]

@description('Categories of logs to be created for workspaces')
param workspaceDiagnosticSettingsLogCategories array = [
  'Checkpoint'
  'Error'
  'Management'
  'Feed'
]

@description('The location where the resources will be deployed.')
param location string

@description('The name of the workspace to be attach to new Applicaiton Group.')
param workSpaceName string = ''

@description('The location of the workspace.')
param workspaceLocation string = ''

@description('The workspace resource group Name.')
param workspaceResourceGroup string = ''

@description('True if the workspace is new. False if there is no workspace added or adding to an existing workspace.')
param isNewWorkspace bool = false

@description('The existing app groups references of the workspace selected.')
param allApplicationGroupReferences string = ''

@description('Whether to add applicationGroup to workspace.')
param addToWorkspace bool

@description('A username in the domain that has privileges to join the session hosts to the domain. For example, \'vmjoiner@contoso.com\'.')
param administratorAccountUsername string = ''

@description('The password that corresponds to the existing domain username.')
@secure()
param administratorAccountPassword string = ''

@description('A username to be used as the virtual machine administrator account. The vmAdministratorAccountUsername and  vmAdministratorAccountPassword parameters must both be provided. Otherwise, domain administrator credentials provided by administratorAccountUsername and administratorAccountPassword will be used.')
param vmAdministratorAccountUsername string = ''

@description('The password associated with the virtual machine administrator account. The vmAdministratorAccountUsername and  vmAdministratorAccountPassword parameters must both be provided. Otherwise, domain administrator credentials provided by administratorAccountUsername and administratorAccountPassword will be used.')
@secure()
param vmAdministratorAccountPassword string = ''

@description('Select the availability options for the VMs.')
@allowed([
  'None'
  'AvailabilitySet'
  'AvailabilityZone'
])
param availabilityOption string = 'None'

@description('The name of avaiability set to be used when create the VMs.')
param availabilitySetName string = ''

@description('Whether to create a new availability set for the VMs.')
param createAvailabilitySet bool = false

@description('The platform update domain count of avaiability set to be created.')
@allowed([
  1
  2
  3
  4
  5
  6
  7
  8
  9
  10
  11
  12
  13
  14
  15
  16
  17
  18
  19
  20
])
param availabilitySetUpdateDomainCount int = 5

@description('The platform fault domain count of avaiability set to be created.')
@allowed([
  1
  2
  3
])
param availabilitySetFaultDomainCount int = 2

@description('The number of availability zone to be used when create the VMs.')
@allowed([
  1
  2
  3
])
param availabilityZone int = 1

@description('The resource group of the session host VMs.')
param vmResourceGroup string = ''

@description('The location of the session host VMs.')
param vmLocation string = ''

@description('The size of the session host VMs.')
param vmSize string = ''

@description('The size of the session host VMs in GB. If the value of this parameter is 0, the disk will be created with the default size set in the image.')
param vmDiskSizeGB int = 0

@description('Whether the VMs created will be hibernate enabled')
param vmHibernate bool = false

@description('Number of session hosts that will be created and added to the hostpool.')
param vmNumberOfInstances int = 0

@description('This prefix will be used in combination with the VM number to create the VM name. If using \'rdsh\' as the prefix, VMs would be named \'rdsh-0\', \'rdsh-1\', etc. You should use a unique prefix to reduce name collisions in Active Directory.')
param vmNamePrefix string = ''

@description('Select the image source for the session host vms. VMs from a Gallery image will be created with Managed Disks.')
@allowed([
  'CustomVHD'
  'CustomImage'
  'Gallery'
])
param vmImageType string = 'Gallery'

@description('(Required when vmImageType = Gallery) Gallery image Offer.')
param vmGalleryImageOffer string = ''

@description('(Required when vmImageType = Gallery) Gallery image Publisher.')
param vmGalleryImagePublisher string = ''

@description('Whether the VM has plan or not')
param vmGalleryImageHasPlan bool = false

@description('(Required when vmImageType = Gallery) Gallery image SKU.')
param vmGalleryImageSKU string = ''

@description('(Required when vmImageType = Gallery) Gallery image version.')
param vmGalleryImageVersion string = ''

@description('(Required when vmImageType = CustomVHD) URI of the sysprepped image vhd file to be used to create the session host VMs. For example, https://rdsstorage.blob.core.windows.net/vhds/sessionhostimage.vhd')
param vmImageVhdUri string = ''

@description('(Required when vmImageType = CustomImage) Resource ID of the image')
param vmCustomImageSourceId string = ''

@description('The VM disk type for the VM: HDD or SSD.')
@allowed([
  'Premium_LRS'
  'StandardSSD_LRS'
  'Standard_LRS'
])
param vmDiskType string = 'StandardSSD_LRS'

@description('The name of the virtual network the VMs will be connected to.')
param existingVnetName string = ''

@description('The subnet the VMs will be placed in.')
param existingSubnetName string = ''

@description('The resource group containing the existing virtual network.')
param virtualNetworkResourceGroupName string = ''

@description('Whether to create a new network security group or use an existing one')
param createNetworkSecurityGroup bool = false

@description('The resource id of an existing network security group')
param networkSecurityGroupId string = ''

@description('The rules to be given to the new network security group')
param networkSecurityGroupRules array = []

@description('Set this parameter to Personal if you would like to enable Persistent Desktop experience. Defaults to false.')
@allowed([
  'Personal'
  'Pooled'
])
param hostpoolType string

@description('Set the type of assignment for a Personal hostpool type')
@allowed([
  'Automatic'
  'Direct'
  ''
])
param personalDesktopAssignmentType string = ''

@description('Maximum number of sessions.')
param maxSessionLimit int = 99999

@description('Type of load balancer algorithm.')
@allowed([
  'BreadthFirst'
  'DepthFirst'
  'Persistent'
])
param loadBalancerType string = 'BreadthFirst'

@description('Hostpool rdp properties')
param customRdpProperty string = ''

@description('The necessary information for adding more VMs to this Hostpool')
param vmTemplate string = ''

@description('Hostpool token expiration time')
param tokenExpirationTime string

@description('The tags to be assigned')
param Tags object = {
}

@description('WVD api version')
param apiVersion string = '2019-12-10-preview'

@description('GUID for the deployment')
param deploymentId string = ''

@description('Whether to use validation enviroment.')
param validationEnvironment bool = false

@description('Preferred App Group type to display')
param preferredAppGroupType string = 'Desktop'

@description('OUPath for the domain join')
param ouPath string = ''

@description('Domain to join')
param domain string = ''

@description('IMPORTANT: You can use this parameter for the test purpose only as AAD Join is public preview. True if AAD Join, false if AD join')
param aadJoin bool = false

@description('IMPORTANT: Please don\'t use this parameter as intune enrollment is not supported yet. True if intune enrollment is selected.  False otherwise')
param intune bool = false

@description('Boot diagnostics object taken as body of Diagnostics Profile in VM creation')
param bootDiagnostics object = {
  enabled: false
}

@description('The name of user assigned identity that will assigned to the VMs. This is an optional parameter.')
param userAssignedIdentity string = ''

@description('Arm template that contains custom configurations to be run after the Virtual Machines are created.')
param customConfigurationTemplateUrl string = ''

@description('Url to the Arm template parameter file for the customConfigurationTemplateUrl parameter. This input will be used when the template is ran after the VMs have been deployed.')
param customConfigurationParameterUrl string = ''

@description('System data is used for internal purposes, such as support preview features.')
param systemData object = {
}

@description('Specifies the SecurityType of the virtual machine. It is set as TrustedLaunch to enable UefiSettings. Default: UefiSettings will not be enabled unless this property is set as TrustedLaunch.')
param securityType string = ''

@description('Specifies whether secure boot should be enabled on the virtual machine.')
param secureBoot bool = false

@description('Specifies whether vTPM (Virtual Trusted Platform Module) should be enabled on the virtual machine.')
param vTPM bool = false

var createVMs = (vmNumberOfInstances > 0)
var domain_var = ((domain == '') ? last(split(administratorAccountUsername, '@')) : domain)
var rdshPrefix = '${vmNamePrefix}-'
var vhds = 'vhds/${rdshPrefix}'
var subnet_id = resourceId(virtualNetworkResourceGroupName, 'Microsoft.Network/virtualNetworks/subnets', existingVnetName, existingSubnetName)
var hostpoolName_var = replace(hostpoolName, '"', '')
var vmTemplateName = 'managedDisks-${toLower(replace(vmImageType, ' ', ''))}vm'
var vmTemplateUri = '${nestedTemplatesLocation}${vmTemplateName}.json'
var rdshVmNamesOutput = {
  rdshVmNamesCopy: [for j in range(0, (createVMs ? vmNumberOfInstances : 1)): {
    name: concat(rdshPrefix, j)
  }]
}
var appGroupName = '${hostpoolName_var}-DAG'
var appGroupResourceId = [
  appGroup.id
]
var workspaceResourceGroup_var = (empty(workspaceResourceGroup) ? resourceGroup().name : workspaceResourceGroup)
var applicationGroupReferencesArr = (('' == allApplicationGroupReferences) ? appGroupResourceId : concat(split(allApplicationGroupReferences, ','), appGroupResourceId))
var hostpoolRequiredProps = {
  friendlyName: hostpoolFriendlyName
  description: hostpoolDescription
  hostpoolType: hostpoolType
  personalDesktopAssignmentType: personalDesktopAssignmentType
  maxSessionLimit: maxSessionLimit
  loadBalancerType: loadBalancerType
  validationEnvironment: validationEnvironment
  preferredAppGroupType: preferredAppGroupType
  ring: null
  registrationInfo: {
    expirationTime: tokenExpirationTime
    token: null
    registrationTokenOperation: 'Update'
  }
  vmTemplate: vmTemplate
}
var hostpoolOptionalProps = {
  customRdpProperty: customRdpProperty
}
var sessionHostConfigurationImageMarketPlaceInfoProps = {
  publisher: vmGalleryImagePublisher
  offer: vmGalleryImageOffer
  sku: vmGalleryImageSKU
  exactVersion: vmGalleryImageVersion
}
var sessionHostConfigurationImageCustomInfoProps = {
  resourceId: vmCustomImageSourceId
}
var sessionHostConfigurationDomainActiveDirectoryInfoProps = {
  domainName: domain_var
  ouPath: ouPath
}
var sessionHostConfigurationDomainAzureActiveDirectoryInfoProps = {
  mdmProviderGuid: (intune ? '0000000a-0000-0000-c000-000000000000' : null)
}
var sendLogsToStorageAccount = (!empty(hostpoolDiagnosticSettingsStorageAccount))
var sendLogsToLogAnalytics = (!empty(hostpoolDiagnosticSettingsLogAnalyticsWorkspaceId))
var sendLogsToEventHub = (!empty(hostpoolDiagnosticSettingsEventHubName))
var storageAccountIdProperty = (sendLogsToStorageAccount ? hostpoolDiagnosticSettingsStorageAccount : null)
var hostpoolDiagnosticSettingsLogProperties = [for item in hostpoolDiagnosticSettingsLogCategories: {
  category: item
  enabled: true
  retentionPolicy: {
    enabled: true
    days: 30
  }
}]
var appGroupDiagnosticSettingsLogProperties = [for item in appGroupDiagnosticSettingsLogCategories: {
  category: item
  enabled: true
  retentionPolicy: {
    enabled: true
    days: 30
  }
}]
var workspaceDiagnosticSettingsLogProperties = [for item in workspaceDiagnosticSettingsLogCategories: {
  category: item
  enabled: true
  retentionPolicy: {
    enabled: true
    days: 30
  }
}]

resource hostpool 'Microsoft.DesktopVirtualization/hostpools@[parameters(\'apiVersion\')]' = {
  name: hostpoolName
  location: location
  tags: Tags
  properties: (empty(customRdpProperty) ? hostpoolRequiredProps : union(hostpoolOptionalProps, hostpoolRequiredProps))
}

resource hostpoolName_default 'Microsoft.DesktopVirtualization/hostpools/sessionHostConfigurations@[parameters(\'apiVersion\')]' = if (createVMs && contains(systemData, 'hostpoolUpdateFeature') && systemData.hostpoolUpdateFeature && ((vmImageType == 'Gallery') || (vmImageType == 'CustomImage'))) {
  name: '${hostpoolName}/default'
  properties: {
    vmSizeId: vmSize
    diskInfo: {
      type: vmDiskType
    }
    customConfigurationTemplateUrl: (empty(customConfigurationTemplateUrl) ? null : customConfigurationTemplateUrl)
    customConfigurationParameterUrl: (empty(customConfigurationParameterUrl) ? null : customConfigurationParameterUrl)
    imageInfo: {
      type: ((vmImageType == 'Gallery') ? 'Marketplace' : 'Custom')
      marketPlaceInfo: ((vmImageType == 'Gallery') ? sessionHostConfigurationImageMarketPlaceInfoProps : null)
      customInfo: ((vmImageType == 'CustomImage') ? sessionHostConfigurationImageCustomInfoProps : null)
    }
    domainInfo: {
      joinType: (aadJoin ? 'AzureActiveDirectory' : 'ActiveDirectory')
      activeDirectoryInfo: ((!aadJoin) ? sessionHostConfigurationDomainActiveDirectoryInfoProps : null)
      azureActiveDirectoryInfo: (aadJoin ? sessionHostConfigurationDomainAzureActiveDirectoryInfoProps : null)
    }
  }
  dependsOn: [
    hostpool
  ]
}

resource appGroup 'Microsoft.DesktopVirtualization/applicationgroups@[parameters(\'apiVersion\')]' = {
  name: appGroupName
  location: location
  tags: Tags
  properties: {
    hostpoolarmpath: hostpool.id
    friendlyName: 'Default Desktop'
    description: 'Desktop Application Group created through the Hostpool Wizard'
    applicationGroupType: 'Desktop'
  }
}

module Workspace_linkedTemplate_deploymentId './nested_Workspace_linkedTemplate_deploymentId.bicep' = if (addToWorkspace) {
  name: 'Workspace-linkedTemplate-${deploymentId}'
  scope: resourceGroup(workspaceResourceGroup_var)
  params: {
    variables_applicationGroupReferencesArr: applicationGroupReferencesArr
    apiVersion: apiVersion
    workSpaceName: workSpaceName
    workspaceLocation: workspaceLocation
  }
}

module AVSet_linkedTemplate_deploymentId './nested_AVSet_linkedTemplate_deploymentId.bicep' = if (createVMs && (availabilityOption == 'AvailabilitySet') && createAvailabilitySet) {
  name: 'AVSet-linkedTemplate-${deploymentId}'
  scope: resourceGroup(vmResourceGroup)
  params: {
    availabilitySetName: availabilitySetName
    vmLocation: vmLocation
    Tags: Tags
    availabilitySetUpdateDomainCount: availabilitySetUpdateDomainCount
    availabilitySetFaultDomainCount: availabilitySetFaultDomainCount
  }
  dependsOn: [
    appGroup
  ]
}

module vmCreation_linkedTemplate_deploymentId '?' /*TODO: replace with correct path to [variables('vmTemplateUri')]*/ = if (createVMs) {
  name: 'vmCreation-linkedTemplate-${deploymentId}'
  scope: resourceGroup(vmResourceGroup)
  params: {
    artifactsLocation: artifactsLocation
    availabilityOption: availabilityOption
    availabilitySetName: availabilitySetName
    availabilityZone: availabilityZone
    vmImageVhdUri: vmImageVhdUri
    vmGalleryImageOffer: vmGalleryImageOffer
    vmGalleryImagePublisher: vmGalleryImagePublisher
    vmGalleryImageHasPlan: vmGalleryImageHasPlan
    vmGalleryImageSKU: vmGalleryImageSKU
    vmGalleryImageVersion: vmGalleryImageVersion
    rdshPrefix: rdshPrefix
    rdshNumberOfInstances: vmNumberOfInstances
    rdshVMDiskType: vmDiskType
    rdshVmSize: vmSize
    rdshVmDiskSizeGB: vmDiskSizeGB
    rdshHibernate: vmHibernate
    enableAcceleratedNetworking: false
    vmAdministratorAccountUsername: vmAdministratorAccountUsername
    vmAdministratorAccountPassword: vmAdministratorAccountPassword
    administratorAccountUsername: administratorAccountUsername
    administratorAccountPassword: administratorAccountPassword
    'subnet-id': subnet_id
    vhds: vhds
    rdshImageSourceId: vmCustomImageSourceId
    location: vmLocation
    createNetworkSecurityGroup: createNetworkSecurityGroup
    networkSecurityGroupId: networkSecurityGroupId
    networkSecurityGroupRules: networkSecurityGroupRules
    Tags: Tags
    hostpoolToken: hostpool.properties.registrationInfo.token
    hostpoolName: hostpoolName
    domain: domain
    ouPath: ouPath
    aadJoin: aadJoin
    intune: intune
    bootDiagnostics: bootDiagnostics
    '_guidValue': deploymentId
    userAssignedIdentity: userAssignedIdentity
    customConfigurationTemplateUrl: customConfigurationTemplateUrl
    customConfigurationParameterUrl: customConfigurationParameterUrl
    SessionHostConfigurationVersion: ((createVMs && contains(systemData, 'hostpoolUpdateFeature') && systemData.hostpoolUpdateFeature) ? hostpoolName_default.properties.version : '')
    securityType: securityType
    secureBoot: secureBoot
    vTPM: vTPM
  }
  dependsOn: [
    AVSet_linkedTemplate_deploymentId
  ]
}

resource hostpoolName_Microsoft_Insights_diagnosticSetting 'Microsoft.DesktopVirtualization/hostpools/providers/diagnosticSettings@2017-05-01-preview' = if (sendLogsToEventHub || sendLogsToLogAnalytics || sendLogsToStorageAccount) {
  name: '${hostpoolName}/Microsoft.Insights/diagnosticSetting'
  location: location
  properties: {
    storageAccountId: (sendLogsToStorageAccount ? storageAccountIdProperty : null)
    eventHubAuthorizationRuleId: (sendLogsToEventHub ? hostpoolDiagnosticSettingsEventHubAuthorizationId : null)
    eventHubName: (sendLogsToEventHub ? hostpoolDiagnosticSettingsEventHubName : null)
    workspaceId: (sendLogsToLogAnalytics ? hostpoolDiagnosticSettingsLogAnalyticsWorkspaceId : null)
    logs: hostpoolDiagnosticSettingsLogProperties
  }
  dependsOn: [
    hostpool
  ]
}

resource appGroupName_Microsoft_Insights_diagnosticSetting 'Microsoft.DesktopVirtualization/applicationgroups/providers/diagnosticSettings@2017-05-01-preview' = if (sendLogsToEventHub || sendLogsToLogAnalytics || sendLogsToStorageAccount) {
  name: '${appGroupName}/Microsoft.Insights/diagnosticSetting'
  location: location
  properties: {
    storageAccountId: (sendLogsToStorageAccount ? storageAccountIdProperty : null)
    eventHubAuthorizationRuleId: (sendLogsToEventHub ? hostpoolDiagnosticSettingsEventHubAuthorizationId : null)
    eventHubName: (sendLogsToEventHub ? hostpoolDiagnosticSettingsEventHubName : null)
    workspaceId: (sendLogsToLogAnalytics ? hostpoolDiagnosticSettingsLogAnalyticsWorkspaceId : null)
    logs: appGroupDiagnosticSettingsLogProperties
  }
  dependsOn: [
    appGroup
  ]
}

resource isNewWorkspace_workSpaceName_placeholder_Microsoft_Insights_diagnosticSetting 'Microsoft.DesktopVirtualization/workspaces/providers/diagnosticSettings@2017-05-01-preview' = if (isNewWorkspace && (sendLogsToEventHub || sendLogsToLogAnalytics || sendLogsToStorageAccount)) {
  name: '${(isNewWorkspace ? workSpaceName : 'placeholder')}/Microsoft.Insights/diagnosticSetting'
  location: location
  properties: {
    storageAccountId: (sendLogsToStorageAccount ? storageAccountIdProperty : null)
    eventHubAuthorizationRuleId: (sendLogsToEventHub ? hostpoolDiagnosticSettingsEventHubAuthorizationId : null)
    eventHubName: (sendLogsToEventHub ? hostpoolDiagnosticSettingsEventHubName : null)
    workspaceId: (sendLogsToLogAnalytics ? hostpoolDiagnosticSettingsLogAnalyticsWorkspaceId : null)
    logs: workspaceDiagnosticSettingsLogProperties
  }
  dependsOn: [
    Workspace_linkedTemplate_deploymentId
  ]
}

output rdshVmNamesObject object = rdshVmNamesOutput