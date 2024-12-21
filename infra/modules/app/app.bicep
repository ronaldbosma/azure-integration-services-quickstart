//=============================================================================
// Application Resources
// These are pure Bicep and can't be deployed separately by azd yet
//=============================================================================

//=============================================================================
// Imports
//=============================================================================

import { apiManagementSettingsType, serviceBusSettingsType } from '../../types/settings.bicep'

//=============================================================================
// Parameters
//=============================================================================

@description('The settings for the API Management Service')
param apiManagementSettings apiManagementSettingsType?

@description('The settings for the Service Bus namespace')
param serviceBusSettings serviceBusSettingsType?

//=============================================================================
// Resources
//=============================================================================

module sampleApi 'sample-api/sample-api.bicep' = if (apiManagementSettings != null) {
  name: 'sampleApi'
  params: {
    apiManagementServiceName: apiManagementSettings!.serviceName
  }
}

module topicsAndSubscriptions 'service-bus/topics-and-subscriptions.bicep' = if (serviceBusSettings != null) {
  name: 'topicsAndSubscriptions'
  params: {
    serviceBusSettings: serviceBusSettings!
  }
}
