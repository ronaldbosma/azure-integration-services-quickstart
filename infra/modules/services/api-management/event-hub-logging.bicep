//=============================================================================
// Configure logging to Event Hub for API Management
// This will make it possible to use the 'log-to-eventhub' policy
//=============================================================================

//=============================================================================
// Imports
//=============================================================================

import * as helpers from '../../../functions/helpers.bicep'
import { apiManagementSettingsType, eventHubSettingsType } from '../../../types/settings.bicep'

//=============================================================================
// Parameters
//=============================================================================

@description('The settings for the API Management Service that will be created')
param apiManagementSettings apiManagementSettingsType

@description('The settings for the Event Hub')
param eventHubSettings eventHubSettingsType

//=============================================================================
// Existing resources
//=============================================================================

resource apiManagementService 'Microsoft.ApiManagement/service@2023-09-01-preview' existing = {
  name: apiManagementSettings.serviceName
}

//=============================================================================
// Resources
//=============================================================================

// Create an API Management logger that logs to the Event Hub

resource apimEventHubLogger 'Microsoft.ApiManagement/service/loggers@2023-09-01-preview' = {
  name: 'apim-event-hub-logger'
  parent: apiManagementService
  properties: {
    loggerType: 'azureEventHub'
    description: 'Event Hub logger'
    credentials: {
      endpointAddress: helpers.getEventHubEndpointAddress(eventHubSettings.namespaceName, eventHubSettings.eventHubName)
      identityClientId: 'systemAssigned'
      name: eventHubSettings.eventHubName
    }
  }
}
