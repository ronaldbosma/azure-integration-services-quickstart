//=============================================================================
// Service Bus
//=============================================================================

//=============================================================================
// Imports
//=============================================================================

import { serviceBusSettingsType } from '../../types/settings.bicep'

//=============================================================================
// Parameters
//=============================================================================

@description('Location to use for all resources')
param location string

@description('The tags to associate with the resource')
param tags object

@description('The settings for the Service Bus namespace')
param serviceBusSettings serviceBusSettingsType

//=============================================================================
// Resources
//=============================================================================

resource serviceBusNamespace 'Microsoft.ServiceBus/namespaces@2024-01-01' = {
  name: serviceBusSettings.namespaceName
  location: location
  tags: tags
  sku: {
    name: 'Standard' // Standard is the minimum version that supports topics
  }
  properties: {
    minimumTlsVersion: '1.2'
  }
}

//=============================================================================
// Outputs
//=============================================================================

output serviceBusEndpoint string = serviceBusNamespace.properties.serviceBusEndpoint
