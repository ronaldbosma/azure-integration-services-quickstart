//=============================================================================
// Application Resources
// These are pure Bicep and can't be deployed separately by azd yet
//=============================================================================

//=============================================================================
// Imports
//=============================================================================

import { apiManagementSettingsType, functionAppSettingsType, logicAppSettingsType, serviceBusSettingsType } from '../../types/settings.bicep'

//=============================================================================
// Parameters
//=============================================================================

@description('The settings for the API Management Service')
param apiManagementSettings apiManagementSettingsType?

@description('The settings for the Function App')
param functionAppSettings functionAppSettingsType?

@description('The settings for the Logic App')
param logicAppSettings logicAppSettingsType?

@description('The settings for the Service Bus namespace')
param serviceBusSettings serviceBusSettingsType?

@description('Name of the storage account')
param storageAccountName string

//=============================================================================
// Resources
//=============================================================================

module sampleApi 'sample-api/sample-api.bicep' = if (apiManagementSettings != null) {
  params: {
    apiManagementServiceName: apiManagementSettings!.serviceName
    serviceBusSettings: serviceBusSettings
  }
}

module topicsAndSubscriptions 'service-bus/topics-and-subscriptions.bicep' = if (serviceBusSettings != null) {
  params: {
    serviceBusSettings: serviceBusSettings!
    functionAppSettings: functionAppSettings
    logicAppSettings: logicAppSettings
  }
}

module storageAccount 'storage-account/storage-account.bicep' = {
  params: {
    storageAccountName: storageAccountName
  }
}
