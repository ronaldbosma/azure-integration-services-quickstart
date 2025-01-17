//=============================================================================
// Event Hub & Consumer Groups in Event Hub Namespace
//=============================================================================

//=============================================================================
// Imports
//=============================================================================

import { functionAppSettingsType, logicAppSettingsType, eventHubSettingsType } from '../../../types/settings.bicep'

//=============================================================================
// Parameters
//=============================================================================

@description('The settings for the Event Hub namespace')
param eventHubSettings eventHubSettingsType

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
