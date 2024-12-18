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

//=============================================================================
// Variables
//=============================================================================

// Determine the instance id based on the provided instance or by generating a new one
var instanceId = getInstanceId(environmentName, location, instance)

var resourceGroupName = getResourceName('resourceGroup', environmentName, location, instanceId)

var apiManagementSettings = {
  serviceName: getResourceName('apiManagement', environmentName, location, instanceId)
  identityName: getResourceName('managedIdentity', environmentName, location, 'apim-${instanceId}')
  publisherName: 'admin@example.org'
  publisherEmail: 'admin@example.org'
  isIncluded: includeApiManagement
}

var appInsightsSettings = {
  appInsightsName: getResourceName('applicationInsights', environmentName, location, instanceId)
  logAnalyticsWorkspaceName: getResourceName('logAnalyticsWorkspace', environmentName, location, instanceId)
  retentionInDays: 30
}

var functionAppSettings = {
  functionAppName: getResourceName('functionApp', environmentName, location, instanceId)
  identityName: getResourceName('managedIdentity', environmentName, location, 'functionapp-${instanceId}')
  appServicePlanName: getResourceName('appServicePlan', environmentName, location, 'functionapp-${instanceId}')
  netFrameworkVersion: 'v8.0'
  isIncluded: includeFunctionApp
}

var logicAppSettings = {
  logicAppName: getResourceName('logicApp', environmentName, location, instanceId)
  identityName: getResourceName('managedIdentity', environmentName, location, 'logicapp-${instanceId}')
  appServicePlanName: getResourceName('appServicePlan', environmentName, location, 'logicapp-${instanceId}')
  netFrameworkVersion: 'v8.0'
  isIncluded: includeLogicApp
}

var keyVaultName = getResourceName('keyVault', environmentName, location, instanceId)

var serviceBusNamespaceName = getResourceName('serviceBusNamespace', environmentName, location, instanceId)

var storageAccountName = getResourceName('storageAccount', environmentName, location, instanceId)

var tags = {
  'azd-env-name': environmentName
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
  dependsOn: [
    keyVault
  ]
}

module serviceBus 'modules/services/service-bus.bicep' = if (includeServiceBus) {
  name: 'serviceBus'
  scope: resourceGroup
  params: {
    location: location
    tags: tags
    serviceBusNamespaceName: serviceBusNamespaceName
  }
}

module apiManagement 'modules/services/api-management.bicep' = if (includeApiManagement) {
  name: 'apiManagement'
  scope: resourceGroup
  params: {
    location: location
    tags: tags
    apiManagementSettings: apiManagementSettings
    appInsightsName: appInsightsSettings.appInsightsName
    keyVaultName: keyVaultName
    storageAccountName: storageAccountName
  }
  dependsOn: [
    appInsights
    storageAccount
  ]
}

module functionApp 'modules/services/function-app.bicep' = if (includeFunctionApp) {
  name: 'functionApp'
  scope: resourceGroup
  params: {
    location: location
    tags: tags
    functionAppSettings: functionAppSettings
    appInsightsName: appInsightsSettings.appInsightsName
    keyVaultName: keyVaultName
    storageAccountName: storageAccountName
  }
  dependsOn: [
    appInsights
    storageAccount
  ]
}

module logicApp 'modules/services/logic-app.bicep' = if (includeLogicApp){
  name: 'logicApp'
  scope: resourceGroup
  params: {
    location: location
    tags: tags
    logicAppSettings: logicAppSettings
    appInsightsName: appInsightsSettings.appInsightsName
    keyVaultName: keyVaultName
    storageAccountName: storageAccountName
  }
  dependsOn: [
    appInsights
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
    storageAccountName: storageAccountName
  }
  dependsOn: [
    keyVault
    storageAccount
  ]
}


//=============================================================================
// Outputs
//=============================================================================

// Return the names of the resources
output AZURE_API_MANAGEMENT_NAME string = (includeApiManagement ? apiManagementSettings.serviceName : '')
output AZURE_APPLICATION_INSIGHTS_NAME string = appInsightsSettings.appInsightsName
output AZURE_FUNCTION_APP_NAME string = (includeFunctionApp ? functionAppSettings.functionAppName : '')
output AZURE_KEY_VAULT_NAME string = keyVaultName
output AZURE_LOGIC_APP_NAME string = (includeLogicApp ? logicAppSettings.logicAppName : '')
output AZURE_STORAGE_ACCOUNT_NAME string = storageAccountName

// Return which services are included in the deployment
output INCLUDE_API_MANAGEMENT bool = includeApiManagement
output INCLUDE_FUNCTION_APP bool = includeFunctionApp
output INCLUDE_LOGIC_APP bool = includeLogicApp
