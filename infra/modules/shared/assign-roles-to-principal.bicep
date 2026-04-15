//=============================================================================
// Assign roles to principal on Application Insights, Key Vault, Service Bus,
// Storage Account and Event Hubs namespace
//=============================================================================

//=============================================================================
// Imports
//=============================================================================

import { eventHubSettingsType, serviceBusSettingsType } from '../../types/settings.bicep'

//=============================================================================
// Parameters
//=============================================================================

@description('The id of the principal that will be assigned the roles')
param principalId string

@description('The type of the principal that will be assigned the roles')
param principalType string?

@description('The flag to determine if the principal is an admin or not')
param isAdmin bool = false

@description('The name of the App Insights instance on which to assign roles')
param appInsightsName string

@description('The settings for the Event Hubs namespace on which to assign roles')
param eventHubSettings eventHubSettingsType?

@description('The name of the Key Vault on which to assign roles')
param keyVaultName string

@description('The settings for the Service Bus namespace on which to assign roles')
param serviceBusSettings serviceBusSettingsType?

@description('The name of the Storage Account on which to assign roles')
param storageAccountName string

//=============================================================================
// Variables
//=============================================================================

var eventHubRoles string[] = [
  'Azure Event Hubs Data Receiver'
  'Azure Event Hubs Data Sender'
]

var keyVaultRole string = isAdmin ? 'Key Vault Administrator' : 'Key Vault Secrets User'

var serviceBusRoles string[] = [
  'Azure Service Bus Data Receiver'
  'Azure Service Bus Data Sender'
]

var storageAccountRoles string[] = [
  'Storage Blob Data Contributor'
  isAdmin
    ? 'Storage File Data Privileged Contributor' // is able to browse file shares in Azure Portal
    : 'Storage File Data SMB Share Contributor'
  'Storage Queue Data Contributor'
  'Storage Table Data Contributor'
]

var monitoringMetricsPublisher string = 'Monitoring Metrics Publisher'

//=============================================================================
// Existing Resources
//=============================================================================

resource appInsights 'Microsoft.Insights/components@2020-02-02' existing = {
  name: appInsightsName
}

resource eventHubsNamespace 'Microsoft.EventHub/namespaces@2024-01-01' existing = if (eventHubSettings != null) {
  name: eventHubSettings!.namespaceName
}

resource keyVault 'Microsoft.KeyVault/vaults@2025-05-01' existing = {
  name: keyVaultName
}

resource serviceBusNamespace 'Microsoft.ServiceBus/namespaces@2024-01-01' existing = if (serviceBusSettings != null) {
  name: serviceBusSettings!.namespaceName
}

resource storageAccount 'Microsoft.Storage/storageAccounts@2025-08-01' existing = {
  name: storageAccountName
}

//=============================================================================
// Resources
//=============================================================================

// Assign role Application Insights to the principal

resource assignAppInsightRolesToPrincipal 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(principalId, appInsights.id, roleDefinitions(monitoringMetricsPublisher).id)
  scope: appInsights
  properties: {
    #disable-next-line use-resource-id-functions
    roleDefinitionId: roleDefinitions(monitoringMetricsPublisher).id
    principalId: principalId
    principalType: principalType
  }
}

// Assign role on Event Hubs namespace to the principal (if Event Hubs namespace is included)

resource assignRolesOnEventHubNamespaceToPrincipal 'Microsoft.Authorization/roleAssignments@2022-04-01' = [
  for role in eventHubRoles: if (eventHubSettings != null) {
    name: guid(principalId, eventHubsNamespace.id, roleDefinitions(role).id)
    scope: eventHubsNamespace
    properties: {
      #disable-next-line use-resource-id-functions
      roleDefinitionId: roleDefinitions(role).id
      principalId: principalId
      principalType: principalType
    }
  }
]

// Assign role on Key Vault to the principal

resource assignRolesOnKeyVaultToPrincipal 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(principalId, keyVault.id, roleDefinitions(keyVaultRole).id)
  scope: keyVault
  properties: {
    #disable-next-line use-resource-id-functions
    roleDefinitionId: roleDefinitions(keyVaultRole).id
    principalId: principalId
    principalType: principalType
  }
}

// Assign roles on Service Bus to the principal (if Service Bus is included)

resource assignRolesOnServiceBusToPrincipal 'Microsoft.Authorization/roleAssignments@2022-04-01' = [
  for role in serviceBusRoles: if (serviceBusSettings != null) {
    name: guid(principalId, serviceBusNamespace.id, roleDefinitions(role).id)
    scope: serviceBusNamespace
    properties: {
      #disable-next-line use-resource-id-functions
      roleDefinitionId: roleDefinitions(role).id
      principalId: principalId
      principalType: principalType
    }
  }
]

// Assign roles on Storage Account to the principal

resource assignRolesOnStorageAccountToPrincipal 'Microsoft.Authorization/roleAssignments@2022-04-01' = [
  for role in storageAccountRoles: {
    name: guid(principalId, storageAccount.id, roleDefinitions(role).id)
    scope: storageAccount
    properties: {
      #disable-next-line use-resource-id-functions
      roleDefinitionId: roleDefinitions(role).id
      principalId: principalId
      principalType: principalType
    }
  }
]
