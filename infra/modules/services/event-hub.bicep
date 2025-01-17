//=============================================================================
// Event Hub
//=============================================================================

//=============================================================================
// Imports
//=============================================================================

import { eventHubSettingsType } from '../../types/settings.bicep'

//=============================================================================
// Parameters
//=============================================================================

@description('Location to use for all resources')
param location string

@description('The tags to associate with the resource')
param tags object

@description('The settings for the Event Hub that will be created')
param eventHubSettings eventHubSettingsType

//=============================================================================
// Resources
//=============================================================================

resource eventHubNamespace 'Microsoft.EventHub/namespaces@2024-01-01' = {
  name: eventHubSettings.eventHubNamespaceName
  location: location
  tags: tags
  sku: {
    name: 'Basic'
    tier: 'Basic'
    capacity: 1
  }
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    isAutoInflateEnabled: false
    maximumThroughputUnits: 0
  }
}

resource eventHub 'Microsoft.EventHub/namespaces/eventhubs@2024-01-01' = {
  parent: eventHubNamespace
  name: eventHubSettings.eventHubName
  properties: {
    messageRetentionInDays: 1 // Max 1 day for Basic tier
    partitionCount: 1
  }
}
