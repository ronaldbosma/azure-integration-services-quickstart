//=============================================================================
// Event Hub & Consumer Groups in Event Hub Namespace
// and adds Event Hub logger to API Management
//=============================================================================

//=============================================================================
// Imports
//=============================================================================

import { getEventHubEndpointAddress } from '../../../functions/helpers.bicep'
import { apiManagementSettingsType, functionAppSettingsType, logicAppSettingsType, eventHubSettingsType } from '../../../types/settings.bicep'

//=============================================================================
// Parameters
//=============================================================================

@description('The settings for the Event Hub namespace')
param eventHubSettings eventHubSettingsType

@description('The settings for the API Management Service')
param apiManagementSettings apiManagementSettingsType?

@description('The settings for the Function App')
param functionAppSettings functionAppSettingsType?

@description('The settings for the Logic App')
param logicAppSettings logicAppSettingsType?

//=============================================================================
// Existing Resources
//=============================================================================

resource eventHubNamespace 'Microsoft.EventHub/namespaces@2024-01-01' existing = {
  name: eventHubSettings.namespaceName
}

resource apiManagementService 'Microsoft.ApiManagement/service@2023-09-01-preview' existing = if (apiManagementSettings != null) {
  name: apiManagementSettings!.serviceName
}

//=============================================================================
// Resources
//=============================================================================

resource eventHub 'Microsoft.EventHub/namespaces/eventhubs@2024-01-01' = {
  name: 'aisquick-sample'
  parent: eventHubNamespace
  properties: {
    messageRetentionInDays: 1
    partitionCount: 1
  }
}

resource functionAppConsumerGroup 'Microsoft.EventHub/namespaces/eventhubs/consumergroups@2024-01-01' = if (functionAppSettings != null) {
  name: 'function-app'
  parent: eventHub
}

resource logicAppConsumerGroup 'Microsoft.EventHub/namespaces/eventhubs/consumergroups@2024-01-01' = if (logicAppSettings != null) {
  name: 'logic-app'
  parent: eventHub
}

resource apimEventHubLogger 'Microsoft.ApiManagement/service/loggers@2023-09-01-preview' = if (apiManagementSettings != null) {
  name: 'apim-event-hub-logger'
  parent: apiManagementService
  properties: {
    loggerType: 'azureEventHub'
    description: 'Event Hub logger'
    credentials: {
      endpointAddress: getEventHubEndpointAddress(eventHubSettings.namespaceName, eventHub.name)
      identityClientId: 'systemAssigned'
      name: eventHub.name
    }
  }
}
