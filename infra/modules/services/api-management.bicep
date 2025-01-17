//=============================================================================
// API Management
//=============================================================================

//=============================================================================
// Imports
//=============================================================================

import { apiManagementSettingsType, eventHubSettingsType, serviceBusSettingsType } from '../../types/settings.bicep'

//=============================================================================
// Parameters
//=============================================================================

@description('Location to use for all resources')
param location string

@description('The tags to associate with the resource')
param tags object

@description('The settings for the API Management Service that will be created')
param apiManagementSettings apiManagementSettingsType

@description('The name of the App Insights instance that will be used by API Management')
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
// Resources
//=============================================================================

module apiManagementService './api-management/api-management-service.bicep' = {
  name: 'apiManagementService'
  params: {
    location: location
    tags: tags
    apiManagementSettings: apiManagementSettings
    eventHubSettings: eventHubSettings
    keyVaultName: keyVaultName
    serviceBusSettings: serviceBusSettings
    storageAccountName: storageAccountName
  }
}

module appInsightsLogging './api-management/app-insights-logging.bicep' = {
  name: 'appInsightsLogging'
  params: {
    apiManagementSettings: apiManagementSettings
    appInsightsName: appInsightsName
  }
  dependsOn: [
    apiManagementService
  ]
}

module eventHubLogging './api-management/event-hub-logging.bicep' = if (eventHubSettings != null) {
  name: 'eventHubLogging'
  params: {
    apiManagementSettings: apiManagementSettings
    eventHubSettings: eventHubSettings!
  }
  dependsOn: [
    apiManagementService
  ]
}

module backends './api-management/backends.bicep' = {
  name: 'backends'
  params: {
    apiManagementSettings: apiManagementSettings
    eventHubSettings: eventHubSettings
    serviceBusSettings: serviceBusSettings
    storageAccountName: storageAccountName
  }
  dependsOn: [
    apiManagementService
  ]
}
