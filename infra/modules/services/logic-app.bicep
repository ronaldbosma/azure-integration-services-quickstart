//=============================================================================
// Logic App
//=============================================================================

//=============================================================================
// Imports
//=============================================================================

import { logicAppSettingsType } from '../../types/settings.bicep'

//=============================================================================
// Parameters
//=============================================================================

@description('Location to use for all resources')
param location string

@description('The tags to associate with the resource')
param tags object

@description('The settings for the Logic App that will be created')
param logicAppSettings logicAppSettingsType

@description('The name of the App Insights instance that will be used by the Logic App')
param appInsightsName string

@description('The name of the Key Vault that will contain the secrets')
param keyVaultName string

@description('Name of the storage account that will be used by the Logic App')
param storageAccountName string

//=============================================================================
// Variables
//=============================================================================

var storageAccountConnectionString = 'DefaultEndpointsProtocol=https;AccountName=${storageAccountName};EndpointSuffix=${environment().suffixes.storage};AccountKey=${storageAccount.listKeys().keys[0].value}'
var appSettings = {
  APP_KIND: 'workflowApp'
  APPLICATIONINSIGHTS_CONNECTION_STRING: appInsights.properties.ConnectionString
  AzureFunctionsJobHost__extensionBundle__id: 'Microsoft.Azure.Functions.ExtensionBundle.Workflows'
  AzureFunctionsJobHost__extensionBundle__version: '[1.*, 2.0.0)'
  AzureWebJobsStorage: storageAccountConnectionString
  FUNCTIONS_EXTENSION_VERSION: '~4'
  FUNCTIONS_WORKER_RUNTIME: 'dotnet'
  WEBSITE_CONTENTAZUREFILECONNECTIONSTRING: storageAccountConnectionString
  WEBSITE_CONTENTSHARE: toLower(logicAppSettings.logicAppName)
  WEBSITE_NODE_DEFAULT_VERSION: '~20'
}

//=============================================================================
// Existing resources
//=============================================================================

resource appInsights 'Microsoft.Insights/components@2020-02-02' existing = {
  name: appInsightsName
}

resource storageAccount 'Microsoft.Storage/storageAccounts@2023-05-01' existing = {
  name: storageAccountName
}

//=============================================================================
// Resources
//=============================================================================

// Create Logic App identity and assign roles to it

resource logicAppIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: logicAppSettings.identityName
  location: location
  tags: tags
}

module assignRolesToLogicAppUserAssignedIdentity '../shared/assign-roles-to-principal.bicep' = {
  name: 'assignRolesToLogicAppUserAssignedIdentity'
  params: {
    principalId: logicAppIdentity.properties.principalId
    keyVaultName: keyVaultName
    storageAccountName: storageAccountName
  }
}


// Create the Application Service Plan for the Logic App

resource hostingPlan 'Microsoft.Web/serverfarms@2024-04-01' = {
  name: logicAppSettings.appServicePlanName
  location: location
  tags: tags
  kind: 'elastic'
  sku: {
    name: 'WS1'
    tier: 'WorkflowStandard'
  }
  properties: {
    elasticScaleEnabled: false
  }
}


// Create the Logic App

resource logicApp 'Microsoft.Web/sites@2024-04-01' = {
  name: logicAppSettings.logicAppName
  location: location
  tags: tags
  kind: 'functionapp,workflowapp'
  identity: {
    type: 'SystemAssigned, UserAssigned'
    userAssignedIdentities: {
      '${logicAppIdentity.id}': {}
    }
  }
  properties: {
    serverFarmId: hostingPlan.id
    keyVaultReferenceIdentity: logicAppIdentity.id
    siteConfig: {
      // NOTE: the app settings will be set separately
      ftpsState: 'FtpsOnly'
      minTlsVersion: '1.2'
      netFrameworkVersion: logicAppSettings.netFrameworkVersion
    }
    httpsOnly: true
  }
}


// Set App Settings
//  NOTE: this is done in a separate module that merges the app settings with the existing ones 
//        to prevent other (manually) created app settings from being removed.

module setLogicAppSettings '../shared/merge-app-settings.bicep' = {
  name: 'setLogicAppSettings'
  params: {
    siteName: logicAppSettings.logicAppName
    currentAppSettings: list('${logicApp.id}/config/appsettings', logicApp.apiVersion).properties
    newAppSettings: appSettings
  }
}


// Assign roles to system-assigned identity of Logic App

module assignRolesToLogicAppSystemAssignedIdentity '../shared/assign-roles-to-principal.bicep' = {
  name: 'assignRolesToLogicAppSystemAssignedIdentity'
  params: {
    principalId: logicApp.identity.principalId
    keyVaultName: keyVaultName
    storageAccountName: storageAccountName
  }
}
