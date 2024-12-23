//=============================================================================
// Add app settings to other services (e.g. API Management, Service Bus)
//=============================================================================

//=============================================================================
// Imports
//=============================================================================

import { apiManagementSettingsType, serviceBusSettingsType } from '../../types/settings.bicep'

//=============================================================================
// Parameters
//=============================================================================

@description('The name of the site for which to add the app settings')
param siteName string

@description('The settings for the API Management Service')
param apiManagementSettings apiManagementSettingsType?

@description('The name of the Key Vault that will contain the secrets')
param keyVaultName string

@description('The settings for the Service Bus namespace')
param serviceBusSettings serviceBusSettingsType?

@description('Name of the storage account that will be used by the Function App')
param storageAccountName string

//=============================================================================
// Variables
//=============================================================================

// If API Management is deployed, add app settings to connect to it
var apimAppSettings = apiManagementSettings == null ? {} : {
  API_MANAGEMENT_BASE_URL: apiManagementService.properties.gatewayUrl
  API_MANAGEMENT_MASTER_SUBSCRIPTION_KEY: '@Microsoft.KeyVault(SecretUri=${apimMasterSubscriptionSecret.properties.secretUri})'
}

// If the Service Bus is deployed, add app settings to connect to it
var serviceBusAppSettings = serviceBusSettings == null ? {} : {
  ServiceBusConnection__fullyQualifiedNamespace: '${serviceBusSettings!.namespaceName}.servicebus.windows.net'
}

var storageAccountAppSettings = {
  StorageAccountConnection__blobServiceUri: storageAccount.properties.primaryEndpoints.blob
  StorageAccountConnection__fileServiceUri: storageAccount.properties.primaryEndpoints.file
  StorageAccountConnection__tableServiceUri: storageAccount.properties.primaryEndpoints.table
  StorageAccountConnection__queueServiceUri: storageAccount.properties.primaryEndpoints.queue
}

var appSettings = union(apimAppSettings, serviceBusAppSettings, storageAccountAppSettings)

//=============================================================================
// Existing resources
//=============================================================================

resource apiManagementService 'Microsoft.ApiManagement/service@2023-09-01-preview' existing = if (apiManagementSettings != null) {
  name: apiManagementSettings!.serviceName
}

resource keyVault 'Microsoft.KeyVault/vaults@2023-07-01' existing = {
  name: keyVaultName
}

resource apimMasterSubscriptionSecret 'Microsoft.KeyVault/vaults/secrets@2023-07-01' existing = {
  name: 'apim-master-subscription-key'
  parent: keyVault
}

resource site 'Microsoft.Web/sites@2024-04-01' existing = {
  name: siteName
}

resource storageAccount 'Microsoft.Storage/storageAccounts@2023-05-01' existing = {
  name: storageAccountName
}

//=============================================================================
// Resources
//=============================================================================

module setSiteAppSettings '../shared/merge-app-settings.bicep' = {
  name: 'setSiteAppSettings-${substring(uniqueString(site.id), 0, 6)}' // Ensure unique name so we don't get a conflict when deploying multiple sites
  params: {
    siteName: site.name
    currentAppSettings: list('${site.id}/config/appsettings', site.apiVersion).properties
    newAppSettings: appSettings
  }
}
