//=============================================================================
// Azure Integration Services Quickstart
// Source: https://github.com/ronaldbosma/azure-integration-services-quickstart
//=============================================================================

targetScope = 'subscription'

//=============================================================================
// Imports
//=============================================================================

import { getResourceName, getInstanceId } from './functions/naming-conventions.bicep'
import * as settings from './types/settings.bicep'


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

@description('The current principal ID that will be assigned roles to the Key Vault and Storage Account.')
param currentPrincipalId string = ''

@description('The type of current principal.')
param currentPrincipalType string = 'User'

@description('Include the API Management service in the deployment.')
param includeApiManagement bool

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
  publisherName: 'admin@example.org'
  publisherEmail: 'admin@example.org'
}

var appInsightsSettings = {
  appInsightsName: getResourceName('applicationInsights', environmentName, location, instanceId)
  logAnalyticsWorkspaceName: getResourceName('logAnalyticsWorkspace', environmentName, location, instanceId)
  retentionInDays: 30
}

var functionAppSettings = !includeFunctionApp ? null : {
  functionAppName: getResourceName('functionApp', environmentName, location, instanceId)
  appServicePlanName: getResourceName('appServicePlan', environmentName, location, 'functionapp-${instanceId}')
  netFrameworkVersion: 'v8.0'
  isIncluded: includeFunctionApp
}

var logicAppSettings = !includeLogicApp ? null : {
  logicAppName: getResourceName('logicApp', environmentName, location, instanceId)
  appServicePlanName: getResourceName('appServicePlan', environmentName, location, 'logicapp-${instanceId}')
  netFrameworkVersion: 'v8.0'
  isIncluded: includeLogicApp
}

var keyVaultName = getResourceName('keyVault', environmentName, location, instanceId)

var serviceBusSettings = !includeServiceBus ? null : {
  namespaceName: getResourceName('serviceBusNamespace', environmentName, location, instanceId)
}

var storageAccountName = getResourceName('storageAccount', environmentName, location, instanceId)

var tags = {
  'azd-env-name': environmentName
  'azd-template': 'ronaldbosma/azure-integration-services-quickstart'
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
  name: 'keyVault'
  scope: resourceGroup
  params: {
    location: location
    tags: tags
    keyVaultName: keyVaultName
  }
}

module storageAccount 'modules/services/storage-account.bicep' = {
  name: 'storageAccount'
  scope: resourceGroup
  params: {
    location: location
    tags: tags
    storageAccountName: storageAccountName
    keyVaultName: keyVaultName
  }
}

module appInsights 'modules/services/app-insights.bicep' = {
  name: 'appInsights'
  scope: resourceGroup
  params: {
    location: location
    tags: tags
    appInsightsSettings: appInsightsSettings
  }
}

module serviceBus 'modules/services/service-bus.bicep' = if (serviceBusSettings != null) {
  name: 'serviceBus'
  scope: resourceGroup
  params: {
    location: location
    tags: tags
    serviceBusSettings: serviceBusSettings!
  }
}

module apiManagement 'modules/services/api-management.bicep' = if (apiManagementSettings != null) {
  name: 'apiManagement'
  scope: resourceGroup
  params: {
    location: location
    tags: tags
    apiManagementSettings: apiManagementSettings!
    appInsightsName: appInsightsSettings.appInsightsName
    keyVaultName: keyVaultName
    serviceBusSettings: serviceBusSettings
    storageAccountName: storageAccountName
  }
  dependsOn: [
    appInsights
    keyVault
    storageAccount
  ]
}

module functionApp 'modules/services/function-app.bicep' = if (functionAppSettings != null) {
  name: 'functionApp'
  scope: resourceGroup
  params: {
    location: location
    tags: tags
    functionAppSettings: functionAppSettings!
    apiManagementSettings: apiManagementSettings
    appInsightsName: appInsightsSettings.appInsightsName
    keyVaultName: keyVaultName
    serviceBusSettings: serviceBusSettings
    storageAccountName: storageAccountName
  }
  dependsOn: [
    apiManagement
    appInsights
    keyVault
    storageAccount
  ]
}

module logicApp 'modules/services/logic-app.bicep' = if (logicAppSettings != null){
  name: 'logicApp'
  scope: resourceGroup
  params: {
    location: location
    tags: tags
    logicAppSettings: logicAppSettings!
    apiManagementSettings: apiManagementSettings
    appInsightsName: appInsightsSettings.appInsightsName
    keyVaultName: keyVaultName
    serviceBusSettings: serviceBusSettings
    storageAccountName: storageAccountName
  }
  dependsOn: [
    apiManagement
    appInsights
    keyVault
    storageAccount
  ]
}

module assignRolesToCurrentPrincipal 'modules/shared/assign-roles-to-principal.bicep' = if (currentPrincipalId != '') {
  name: 'assignRolesToCurrentPrincipal'
  scope: resourceGroup
  params: {
    principalId: currentPrincipalId
    principalType: currentPrincipalType
    isAdmin: true
    keyVaultName: keyVaultName
    serviceBusSettings: serviceBusSettings
    storageAccountName: storageAccountName
  }
  dependsOn: [
    keyVault
    storageAccount
  ]
}


//=============================================================================
// Application Resources
//=============================================================================

module applicationResources 'modules/application/application.bicep' = if (includeApplicationInfraResources) {
  name: 'applicationResources'
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
output AZURE_API_MANAGEMENT_NAME string = (apiManagementSettings != null ? apiManagementSettings!.serviceName : '')
output AZURE_APPLICATION_INSIGHTS_NAME string = appInsightsSettings.appInsightsName
output AZURE_FUNCTION_APP_NAME string = (functionAppSettings != null ? functionAppSettings!.functionAppName : '')
output AZURE_KEY_VAULT_NAME string = keyVaultName
output AZURE_LOGIC_APP_NAME string = (logicAppSettings != null ? logicAppSettings!.logicAppName : '')
output AZURE_RESOURCE_GROUP string = resourceGroupName
output AZURE_SERVICE_BUS_NAMESPACE_NAME string = (serviceBusSettings != null ? serviceBusSettings!.namespaceName : '')
output AZURE_STORAGE_ACCOUNT_NAME string = storageAccountName

// Return which services are included in the deployment
output INCLUDE_API_MANAGEMENT bool = includeApiManagement
output INCLUDE_FUNCTION_APP bool = includeFunctionApp
output INCLUDE_LOGIC_APP bool = includeLogicApp
output INCLUDE_SERVICE_BUS bool = includeServiceBus

// Return if the application infra resources are included in the deployment
output INCLUDE_APPLICATION_INFRA_RESOURCES bool = includeApplicationInfraResources
