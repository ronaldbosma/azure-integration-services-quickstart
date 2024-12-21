//=============================================================================
// Topics & Subscriptions in Service Bus
//=============================================================================

//=============================================================================
// Imports
//=============================================================================

import { serviceBusSettingsType } from '../../../types/settings.bicep'

//=============================================================================
// Parameters
//=============================================================================

@description('The settings for the Service Bus namespace')
param serviceBusSettings serviceBusSettingsType

//=============================================================================
// Existing Resources
//=============================================================================

resource serviceBusNamespace 'Microsoft.ServiceBus/namespaces@2024-01-01' existing = {
  name: serviceBusSettings.namespaceName
}

//=============================================================================
// Resources
//=============================================================================

resource sampleTopic 'Microsoft.ServiceBus/namespaces/topics@2024-01-01' = {
  name: 'sample'
  parent: serviceBusNamespace
}
