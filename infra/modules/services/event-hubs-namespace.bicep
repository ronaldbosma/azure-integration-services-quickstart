//=============================================================================
// Event Hubs namespace
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

@description('The settings for the Event Hubs namespace that will be created')
param eventHubSettings eventHubSettingsType

//=============================================================================
// Resources
//=============================================================================

resource eventHubsNamespace 'Microsoft.EventHub/namespaces@2024-01-01' = {
  name: eventHubSettings.namespaceName
  location: location
  tags: tags
  sku: {
    name: 'Standard'  // Standard is the minimum version that supports multiple consumer groups on an event hub
    tier: 'Standard'
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

//=============================================================================
// Outputs
//=============================================================================

output serviceBusEndpoint string = eventHubsNamespace.properties.serviceBusEndpoint
