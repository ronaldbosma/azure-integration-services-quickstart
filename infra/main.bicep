//=============================================================================
// Azure Integration Services Quickstart
// Source: https://github.com/ronaldbosma/azure-integration-services-quickstart
//=============================================================================

targetScope = 'subscription'

//=============================================================================
// Imports
//=============================================================================

import { getResourceName, getInstanceId } from './functions/naming-conventions.bicep'

//=============================================================================
// Parameters
//=============================================================================

@minLength(1)
@description('Location to use for all resources')
param location string

@minLength(1)
@maxLength(32)
@description('The name of the environment to deploy to')
param environmentName string

@maxLength(5) // The maximum length of the storage account name and key vault name is 24 characters. To prevent errors the instance name should be short.
@description('The instance that will be added to the deployed resources names to make them unique. Will be generated if not provided.')
param instance string = ''

@description('Include the API Management service in the deployment.')
param includeApiManagement bool

@description('Include the Event Hubs namespace in the deployment.')
param includeEventHubsNamespace bool

@description('Include the Function App in the deployment.')
param includeFunctionApp bool

@description('Include the Logic App in the deployment.')
param includeLogicApp bool

@description('Include the Service Bus in the deployment.')
param includeServiceBus bool

@description('Include the application infrastructure resources, like the Sample API, topics, etc., in the deployment.')
param includeApplicationInfraResources bool

//=============================================================================
// Variables
//=============================================================================

// Determine the instance id based on the provided instance or by generating a new one
var instanceId = getInstanceId(environmentName, location, instance)

var resourceGroupName = getResourceName('resourceGroup', environmentName, location, instanceId)

var apiManagementSettings = !includeApiManagement ? null : {
  serviceName: getResourceName('apiManagement', environmentName, location, instanceId)
  identityName: getResourceName('managedIdentity', environmentName, location, 'apim-${instanceId}')
  publisherName: 'admin@example.org'
  publisherEmail: 'admin@example.org'
}

var appInsightsSettings = {
  appInsightsName: getResourceName('applicationInsights', environmentName, location, instanceId)
  logAnalyticsWorkspaceName: getResourceName('logAnalyticsWorkspace', environmentName, location, instanceId)
  retentionInDays: 30
}

var eventHubSettings = !includeEventHubsNamespace ? null : {
  namespaceName: getResourceName('eventHubsNamespace', environmentName, location, instanceId)
}

var functionAppSettings = !includeFunctionApp ? null : {
  functionAppName: getResourceName('functionApp', environmentName, location, instanceId)
  identityName: getResourceName('managedIdentity', environmentName, location, 'functionapp-${instanceId}')
  appServicePlanName: getResourceName('appServicePlan', environmentName, location, 'functionapp-${instanceId}')
  netFrameworkVersion: 'v9.0'
}

var logicAppSettings = !includeLogicApp ? null : {
  logicAppName: getResourceName('logicApp', environmentName, location, instanceId)
  identityName: getResourceName('managedIdentity', environmentName, location, 'logicapp-${instanceId}')
  appServicePlanName: getResourceName('appServicePlan', environmentName, location, 'logicapp-${instanceId}')
  netFrameworkVersion: 'v9.0'
}

var keyVaultName = getResourceName('keyVault', environmentName, location, instanceId)

var serviceBusSettings = !includeServiceBus ? null : {
  namespaceName: getResourceName('serviceBusNamespace', environmentName, location, instanceId)
}

var storageAccountName = getResourceName('storageAccount', environmentName, location, instanceId)

var tags = {
  'azd-env-name': environmentName
  'azd-template': 'ronaldbosma/azure-integration-services-quickstart'
  SecurityControl: 'Ignore'
}

//=============================================================================
// Resources
//=============================================================================

resource resourceGroup 'Microsoft.Resources/resourceGroups@2024-07-01' = {
  name: resourceGroupName
  location: location
  tags: tags
}

module keyVault 'modules/services/key-vault.bicep' = {
  scope: resourceGroup
  params: {
    location: location
    tags: tags
    keyVaultName: keyVaultName
  }
}

module storageAccount 'modules/services/storage-account.bicep' = {
  scope: resourceGroup
  params: {
    location: location
    tags: tags
    storageAccountName: storageAccountName
  }
}

module appInsights 'modules/services/app-insights.bicep' = {
  scope: resourceGroup
  params: {
    location: location
    tags: tags
    appInsightsSettings: appInsightsSettings
  }
}

module eventHubsNamespace 'modules/services/event-hubs-namespace.bicep' = if (eventHubSettings != null) {
  scope: resourceGroup
  params: {
    location: location
    tags: tags
    eventHubSettings: eventHubSettings!
  }
}

module serviceBus 'modules/services/service-bus.bicep' = if (serviceBusSettings != null) {
  scope: resourceGroup
  params: {
    location: location
    tags: tags
    serviceBusSettings: serviceBusSettings!
  }
}

module apiManagement 'modules/services/api-management.bicep' = if (apiManagementSettings != null) {
  scope: resourceGroup
  params: {
    location: location
    tags: tags
    apiManagementSettings: apiManagementSettings!
    appInsightsName: appInsightsSettings.appInsightsName
    eventHubSettings: eventHubSettings
    keyVaultName: keyVaultName
    serviceBusSettings: serviceBusSettings
    storageAccountName: storageAccountName
  }
  dependsOn: [
    appInsights
    eventHubsNamespace
    keyVault
    serviceBus
  ]
}

module functionApp 'modules/services/function-app.bicep' = if (functionAppSettings != null) {
  scope: resourceGroup
  params: {
    location: location
    tags: tags
    functionAppSettings: functionAppSettings!
    apiManagementSettings: apiManagementSettings
    appInsightsName: appInsightsSettings.appInsightsName
    eventHubSettings: eventHubSettings
    keyVaultName: keyVaultName
    serviceBusSettings: serviceBusSettings
    storageAccountName: storageAccountName
  }
  dependsOn: [
    appInsights
    eventHubsNamespace
    keyVault
    serviceBus
    storageAccount
  ]
}

module logicApp 'modules/services/logic-app.bicep' = if (logicAppSettings != null) {
  scope: resourceGroup
  params: {
    location: location
    tags: tags
    logicAppSettings: logicAppSettings!
    apiManagementSettings: apiManagementSettings
    appInsightsName: appInsightsSettings.appInsightsName
    eventHubSettings: eventHubSettings
    keyVaultName: keyVaultName
    serviceBusSettings: serviceBusSettings
    storageAccountName: storageAccountName
  }
  dependsOn: [
    appInsights
    eventHubsNamespace
    keyVault
    serviceBus
    storageAccount
  ]
}

module assignRolesToDeployer 'modules/shared/assign-roles-to-principal.bicep' = {
  scope: resourceGroup
  params: {
    principalId: deployer().objectId
    isAdmin: true
    eventHubSettings: eventHubSettings
    keyVaultName: keyVaultName
    serviceBusSettings: serviceBusSettings
    storageAccountName: storageAccountName
  }
  dependsOn: [
    eventHubsNamespace
    keyVault
    serviceBus
    storageAccount
  ]
}


//=============================================================================
// Application Resources
//=============================================================================

module applicationResources 'modules/application/application.bicep' = if (includeApplicationInfraResources) {
  scope: resourceGroup
  params: {
    apiManagementSettings: apiManagementSettings
    functionAppSettings: functionAppSettings
    logicAppSettings: logicAppSettings
    serviceBusSettings: serviceBusSettings
    storageAccountName: storageAccountName
  }
  dependsOn: [
    apiManagement
    serviceBus
    storageAccount
  ]
}


//=============================================================================
// Outputs
//=============================================================================

// Return the names of the resources
output AZURE_API_MANAGEMENT_NAME string = apiManagementSettings.?serviceName ?? ''
output AZURE_APPLICATION_INSIGHTS_NAME string = appInsightsSettings.appInsightsName
output AZURE_EVENT_HUB_NAMESPACE_NAME string = eventHubSettings.?namespaceName ?? ''
output AZURE_FUNCTION_APP_NAME string = functionAppSettings.?functionAppName ?? ''
output AZURE_KEY_VAULT_NAME string = keyVaultName
output AZURE_LOG_ANALYTICS_WORKSPACE_NAME string = appInsightsSettings.logAnalyticsWorkspaceName
output AZURE_LOGIC_APP_NAME string = logicAppSettings.?logicAppName ?? ''
output AZURE_RESOURCE_GROUP string = resourceGroupName
output AZURE_SERVICE_BUS_NAMESPACE_NAME string = serviceBusSettings.?namespaceName ?? ''
output AZURE_STORAGE_ACCOUNT_NAME string = storageAccountName

// Return which services are included in the deployment
output INCLUDE_API_MANAGEMENT bool = includeApiManagement
output INCLUDE_EVENT_HUBS_NAMESPACE bool = includeEventHubsNamespace
output INCLUDE_FUNCTION_APP bool = includeFunctionApp
output INCLUDE_LOGIC_APP bool = includeLogicApp
output INCLUDE_SERVICE_BUS bool = includeServiceBus

// Return if the application infra resources are included in the deployment
output INCLUDE_APPLICATION_INFRA_RESOURCES bool = includeApplicationInfraResources
