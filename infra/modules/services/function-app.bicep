//=============================================================================
// Function App
//=============================================================================

//=============================================================================
// Imports
//=============================================================================

import { apiManagementSettingsType, functionAppSettingsType, serviceBusSettingsType } from '../../types/settings.bicep'

//=============================================================================
// Parameters
//=============================================================================

@description('Location to use for all resources')
param location string

@description('The tags to associate with the resource')
param tags object

@description('The settings for the Function App that will be created')
param functionAppSettings functionAppSettingsType

@description('The settings for the API Management Service')
param apiManagementSettings apiManagementSettingsType?

@description('The name of the App Insights instance that will be used by the Function App')
param appInsightsName string

@description('The name of the Key Vault that will contain the secrets')
param keyVaultName string

@description('The settings for the Service Bus namespace')
param serviceBusSettings serviceBusSettingsType?

@description('Name of the storage account that will be used by the Function App')
param storageAccountName string

//=============================================================================
// Variables
//=============================================================================

var serviceTags = union(tags, {
  'azd-service-name': 'functionApp'
})

var storageAccountConnectionString = 'DefaultEndpointsProtocol=https;AccountName=${storageAccountName};EndpointSuffix=${environment().suffixes.storage};AccountKey=${storageAccount.listKeys().keys[0].value}'
var baseAppSettings = {
  APPINSIGHTS_INSTRUMENTATIONKEY: appInsights.properties.InstrumentationKey
  APPLICATIONINSIGHTS_CONNECTION_STRING: appInsights.properties.ConnectionString
  AzureWebJobsStorage: storageAccountConnectionString
  FUNCTIONS_EXTENSION_VERSION: '~4'
  FUNCTIONS_WORKER_RUNTIME: 'dotnet-isolated'
  WEBSITE_CONTENTAZUREFILECONNECTIONSTRING: storageAccountConnectionString
  WEBSITE_CONTENTSHARE: toLower(functionAppSettings.functionAppName)
  WEBSITE_USE_PLACEHOLDER_DOTNETISOLATED: '1'
}

// If API Management is deployed, add app settings to connect to it
var apimAppSettings = apiManagementSettings == null ? {} : {
  API_MANAGEMENT_BASE_URL: 'https://${apiManagementSettings!.serviceName}.azure-api.net'
  API_MANAGEMENT_MASTER_SUBSCRIPTION_KEY: '@Microsoft.KeyVault(SecretUri=https://${keyVaultName}.vault.azure.net/secrets/apim-master-subscription-key)'
}

var appSettings = union(baseAppSettings, apimAppSettings)

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

// Create Function App user-assigned identity and assign roles to it

resource functionAppIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: functionAppSettings.identityName
  location: location
  tags: tags
}

module assignRolesToFunctionAppUserAssignedIdentity '../shared/assign-roles-to-principal.bicep' = {
  name: 'assignRolesToFunctionAppUserAssignedIdentity'
  params: {
    principalId: functionAppIdentity.properties.principalId
    keyVaultName: keyVaultName
    serviceBusSettings: serviceBusSettings
    storageAccountName: storageAccountName
  }
}


// Create the Application Service Plan for the Function App

resource hostingPlan 'Microsoft.Web/serverfarms@2024-04-01' = {
  name: functionAppSettings.appServicePlanName
  location: location
  tags: tags
  kind: 'functionapp'
  sku: {
    name: 'Y1'
    tier: 'Dynamic'
  }
  properties: {}
}


// Create the Function App

resource functionApp 'Microsoft.Web/sites@2024-04-01' = {
  name: functionAppSettings.functionAppName
  location: location
  tags: serviceTags
  kind: 'functionapp'
  identity: {
    type: 'SystemAssigned, UserAssigned'
    userAssignedIdentities: {
      '${functionAppIdentity.id}': {}
    }
  }
  properties: {
    serverFarmId: hostingPlan.id
    siteConfig: {
      // NOTE: the app settings will be set separately
      ftpsState: 'FtpsOnly'
      minTlsVersion: '1.2'
      netFrameworkVersion: functionAppSettings.netFrameworkVersion
    }
    httpsOnly: true
  }
}


// Set App Settings
//  NOTE: this is done in a separate module that merges the app settings with the existing ones 
//        to prevent other (manually) created app settings from being removed.

module setFunctionAppSettings '../shared/merge-app-settings.bicep' = {
  name: 'setFunctionAppSettings'
  params: {
    siteName: functionAppSettings.functionAppName
    currentAppSettings: list('${functionApp.id}/config/appsettings', functionApp.apiVersion).properties
    newAppSettings: appSettings
  }
}


// Assign roles to system-assigned identity of Function App

module assignRolesToFunctionAppSystemAssignedIdentity '../shared/assign-roles-to-principal.bicep' = {
  name: 'assignRolesToFunctionAppSystemAssignedIdentity'
  params: {
    principalId: functionApp.identity.principalId
    keyVaultName: keyVaultName
    serviceBusSettings: serviceBusSettings
    storageAccountName: storageAccountName
  }
}
