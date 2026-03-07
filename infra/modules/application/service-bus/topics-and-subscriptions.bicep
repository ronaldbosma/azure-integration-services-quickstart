//=============================================================================
// Topics & Subscriptions in Service Bus
//=============================================================================

//=============================================================================
// Imports
//=============================================================================

import { functionAppSettingsType, logicAppSettingsType, serviceBusSettingsType } from '../../../types/settings.bicep'

//=============================================================================
// Parameters
//=============================================================================

@description('The settings for the Service Bus namespace')
param serviceBusSettings serviceBusSettingsType

@description('The settings for the Function App')
param functionAppSettings functionAppSettingsType?

@description('The settings for the Logic App')
param logicAppSettings logicAppSettingsType?

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
  name: 'aisquick-sample'
  parent: serviceBusNamespace
}

resource functionAppSubscriptionOnSampleTopic 'Microsoft.ServiceBus/namespaces/topics/subscriptions@2024-01-01' = if (functionAppSettings != null) {
  name: 'function-app'
  parent: sampleTopic
}

resource logicAppSubscriptionOnSampleTopic 'Microsoft.ServiceBus/namespaces/topics/subscriptions@2024-01-01' = if (logicAppSettings != null) {
  name: 'logic-app'
  parent: sampleTopic
}
