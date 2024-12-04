//=============================================================================
// Azure Integration Services Quickstart
// Source: https://github.com/ronaldbosma/azure-integration-services-quickstart
//=============================================================================

targetScope = 'subscription'

//=============================================================================
// Imports
//=============================================================================

import { getResourceName } from './functions/naming-conventions.bicep'
import * as settings from './types/settings.bicep'


//=============================================================================
// Parameters
//=============================================================================

@description('Specifies the Azure Active Directory tenant ID that should be used for authenticating requests to the key vault.')
param tenantId string = subscription().tenantId

@description('Location to use for all resources')
param location string

@description('The name of the environment to deploy to')
@maxLength(12) // The maximum length of the storage account name and key vault name is 24 characters. To prevent errors the environment name should be short.
param environment string

@description('The instance number to will be added to the deployed resources names to make them unique')
@maxLength(5) // The maximum length of the storage account name and key vault name is 24 characters. To prevent errors the instance name should be short.
param instance string

@description('The principal ID of the user that will be assigned roles to the Key Vault and Storage Account.')
param currentUserPrincipalId string


//=============================================================================
// Variables
//=============================================================================

var resourceGroupName = getResourceName('resourceGroup', environment, location, instance)

var apiManagementSettings = {
  serviceName: getResourceName('apiManagement', environment, location, instance)
  identityName: getResourceName('managedIdentity', environment, location, 'apim-${instance}')
  publisherName: 'admin@example.org'
  publisherEmail: 'admin@example.org'
}

var appInsightsSettings = {
  appInsightsName: getResourceName('applicationInsights', environment, location, instance)
  logAnalyticsWorkspaceName: getResourceName('logAnalyticsWorkspace', environment, location, instance)
  retentionInDays: 30
}

var functionAppSettings = {
  functionAppName: getResourceName('functionApp', environment, location, instance)
  identityName: getResourceName('managedIdentity', environment, location, 'functionapp-${instance}')
  appServicePlanName: getResourceName('appServicePlan', environment, location, 'functionapp-${instance}')
  netFrameworkVersion: 'v8.0'
}

var logicAppSettings = {
  logicAppName: getResourceName('logicApp', environment, location, instance)
  identityName: getResourceName('managedIdentity', environment, location, 'logicapp-${instance}')
  appServicePlanName: getResourceName('appServicePlan', environment, location, 'logicapp-${instance}')
  netFrameworkVersion: 'v8.0'
}

var keyVaultName = getResourceName('keyVault', environment, location, instance)

var storageAccountName = getResourceName('storageAccount', environment, location, instance)


//=============================================================================
// Resources
//=============================================================================

resource resourceGroup 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: resourceGroupName
  location: location
}

module keyVault 'modules/key-vault.bicep' = {
  name: 'keyVault'
  scope: resourceGroup
  params: {
    tenantId: tenantId
    location: location
    keyVaultName: keyVaultName
  }
}

module storageAccount 'modules/storage-account.bicep' = {
  name: 'storageAccount'
  scope: resourceGroup
  params: {
    location: location
    storageAccountName: storageAccountName
  }
}

module appInsights 'modules/app-insights.bicep' = {
  name: 'appInsights'
  scope: resourceGroup
  params: {
    location: location
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

module assignRolesToCurrentUser 'modules/assign-roles-to-principal.bicep' = if (currentUserPrincipalId != null) {
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
output storageAccountName string = storageAccountName
