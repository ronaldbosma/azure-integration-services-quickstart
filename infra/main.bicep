//=============================================================================
// Azure Integration Services Quickstart
// Source: https://github.com/ronaldbosma/azure-integration-services-quickstart
//=============================================================================

targetScope = 'subscription'

//=============================================================================
// Imports
//=============================================================================

import { getResourceName, removeWhiteSpaces } from './functions/naming-conventions.bicep'
import * as settings from './types/settings.bicep'


//=============================================================================
// Parameters
//=============================================================================

@description('Specifies the Azure Active Directory tenant ID that should be used for authenticating requests to the key vault.')
param tenantId string = subscription().tenantId

@minLength(1)
@description('Location to use for all resources')
param location string

@minLength(1)
@maxLength(12) // The maximum length of the storage account name and key vault name is 24 characters. To prevent errors the environment name should be short.
@description('The name of the environment to deploy to')
param environmentName string

@minLength(1)
@maxLength(5) // The maximum length of the storage account name and key vault name is 24 characters. To prevent errors the instance name should be short.
@description('The instance that will be added to the deployed resources names to make them unique. Will be generated if not provided.')
param instance string = ''

@description('The principal ID of the user that will be assigned roles to the Key Vault and Storage Account.')
param currentUserPrincipalId string = ''


//=============================================================================
// Variables
//=============================================================================

// Use a generated instance ID in the resource names if no instance is provided
var generatedInstanceId = substring(uniqueString(subscription().subscriptionId, environmentName, location), 0, 5)
var instanceId = (removeWhiteSpaces(instance) == '') ? generatedInstanceId : instance

var resourceGroupName = getResourceName('resourceGroup', environmentName, location, instanceId)

var apiManagementSettings = {
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

var functionAppSettings = {
  functionAppName: getResourceName('functionApp', environmentName, location, instanceId)
  identityName: getResourceName('managedIdentity', environmentName, location, 'functionapp-${instanceId}')
  appServicePlanName: getResourceName('appServicePlan', environmentName, location, 'functionapp-${instanceId}')
  netFrameworkVersion: 'v8.0'
}

var logicAppSettings = {
  logicAppName: getResourceName('logicApp', environmentName, location, instanceId)
  identityName: getResourceName('managedIdentity', environmentName, location, 'logicapp-${instanceId}')
  appServicePlanName: getResourceName('appServicePlan', environmentName, location, 'logicapp-${instanceId}')
  netFrameworkVersion: 'v8.0'
}

var keyVaultName = getResourceName('keyVault', environmentName, location, instanceId)

var storageAccountName = getResourceName('storageAccount', environmentName, location, instanceId)

var tags = {
  'azd-env-name': environmentName
}

//=============================================================================
// Resources
//=============================================================================

resource resourceGroup 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: resourceGroupName
  location: location
  tags: tags
}

module keyVault 'modules/key-vault.bicep' = {
  name: 'keyVault'
  scope: resourceGroup
  params: {
    tenantId: tenantId
    location: location
    tags: tags
    keyVaultName: keyVaultName
  }
}

module storageAccount 'modules/storage-account.bicep' = {
  name: 'storageAccount'
  scope: resourceGroup
  params: {
    location: location
    tags: tags
    storageAccountName: storageAccountName
  }
}

module appInsights 'modules/app-insights.bicep' = {
  name: 'appInsights'
  scope: resourceGroup
  params: {
    location: location
    tags: tags
    appInsightsSettings: appInsightsSettings
    keyVaultName: keyVaultName
  }
  dependsOn: [
    keyVault
  ]
}

module apiManagement 'modules/api-management.bicep' = {
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
  ]
}

module functionApp 'modules/function-app.bicep' = {
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

module logicApp 'modules/logic-app.bicep' = {
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

module assignRolesToCurrentUser 'modules/assign-roles-to-principal.bicep' = if (currentUserPrincipalId != '') {
  name: 'assignRolesToCurrentUser'
  scope: resourceGroup
  params: {
    principalId: currentUserPrincipalId
    principalType: 'User'
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
output apiManagementServiceName string = apiManagementSettings.serviceName
output appInsightsName string = appInsightsSettings.appInsightsName
output functionAppName string = functionAppSettings.functionAppName
output functionAppServicePlanName string = functionAppSettings.appServicePlanName
output keyVaultName string = keyVaultName
output logAnalyticsWorkspaceName string = appInsightsSettings.logAnalyticsWorkspaceName
output logicAppName string = logicAppSettings.logicAppName
output logicAppServicePlanName string = logicAppSettings.appServicePlanName
output resourceGroupName string = resourceGroupName
output storageAccountName string = storageAccountName
