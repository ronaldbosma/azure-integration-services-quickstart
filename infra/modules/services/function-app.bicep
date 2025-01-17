//=============================================================================
// Function App
//=============================================================================

//=============================================================================
// Imports
//=============================================================================

import * as helpers from '../../functions/helpers.bicep'
import { apiManagementSettingsType, eventHubSettingsType, functionAppSettingsType, serviceBusSettingsType } from '../../types/settings.bicep'

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

@description('The settings for the Event Hub')
param eventHubSettings eventHubSettingsType?

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

// If API Management is deployed, add app settings to connect to it
var apimAppSettings = apiManagementSettings == null ? {} : {
  ApiManagement_gatewayUrl: helpers.getApiManagementGatewayUrl(apiManagementSettings!.serviceName)
  ApiManagement_subscriptionKey: helpers.getKeyVaultSecretReference(keyVaultName, 'apim-master-subscription-key')
}

// If the Service Bus is deployed, add app settings to connect to it
var serviceBusAppSettings = serviceBusSettings == null ? {} : {
  ServiceBusConnection__fullyQualifiedNamespace: helpers.getServiceBusFullyQualifiedNamespace(serviceBusSettings!.namespaceName)
}

var appSettings = {
  APPLICATIONINSIGHTS_CONNECTION_STRING: appInsights.properties.ConnectionString
  AzureWebJobsStorage: helpers.getKeyVaultSecretReference(keyVaultName, 'storage-account-connection-string')
  FUNCTIONS_EXTENSION_VERSION: '~4'
  FUNCTIONS_WORKER_RUNTIME: 'dotnet-isolated'
  WEBSITE_CONTENTAZUREFILECONNECTIONSTRING: helpers.getKeyVaultSecretReference(keyVaultName, 'storage-account-connection-string')
  WEBSITE_CONTENTSHARE: toLower(functionAppSettings.functionAppName)
  WEBSITE_USE_PLACEHOLDER_DOTNETISOLATED: '1'

  // Storage Account App Settings
  StorageAccountConnection__blobServiceUri: helpers.getBlobStorageEndpoint(storageAccountName)
  StorageAccountConnection__fileServiceUri: helpers.getFileStorageEndpoint(storageAccountName)
  StorageAccountConnection__queueServiceUri: helpers.getQueueStorageEndpoint(storageAccountName)
  StorageAccountConnection__tableServiceUri: helpers.getTableStorageEndpoint(storageAccountName)

  // Include optional app settings
  ...apimAppSettings
  ...serviceBusAppSettings
}

//=============================================================================
// Existing resources
//=============================================================================

resource appInsights 'Microsoft.Insights/components@2020-02-02' existing = {
  name: appInsightsName
}

//=============================================================================
// Resources
//=============================================================================

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
    type: 'SystemAssigned'
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


// Assign roles to system-assigned identity of Function App

module assignRolesToFunctionAppSystemAssignedIdentity '../shared/assign-roles-to-principal.bicep' = {
  name: 'assignRolesToFunctionAppSystemAssignedIdentity'
  params: {
    principalId: functionApp.identity.principalId
    eventHubSettings: eventHubSettings
    keyVaultName: keyVaultName
    serviceBusSettings: serviceBusSettings
    storageAccountName: storageAccountName
  }
}


// Set standard App Settings
//  NOTE: this is done in a separate module that merges the app settings with the existing ones 
//        to prevent other (manually) created app settings from being removed.

module setFunctionAppSettings '../shared/merge-app-settings.bicep' = {
  name: 'setFunctionAppSettings'
  params: {
    siteName: functionAppSettings.functionAppName
    currentAppSettings: list('${functionApp.id}/config/appsettings', functionApp.apiVersion).properties
    newAppSettings: appSettings
  }
  dependsOn: [
    assignRolesToFunctionAppSystemAssignedIdentity // App settings might be dependent on the function app having access to e.g. Key Vault
  ]
}
