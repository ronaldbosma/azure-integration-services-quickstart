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
  'a638d3c7-ab3a-418d-83e6-5f17a39d4fde'      // Azure Event Hubs Data Receiver
  '2b629674-e913-4c01-ae53-ef4638d8f975'      // Azure Event Hubs Data Sender
]

var keyVaultRole string = isAdmin 
  ? '00482a5a-887f-4fb3-b363-3b7fe8e74483'    // Key Vault Administrator
  : '4633458b-17de-408a-b874-0445c86b69e6'    // Key Vault Secrets User

var serviceBusRoles string[] = [
  '4f6d3b9b-027b-4f4c-9142-0e5a2a2247e0'      // Azure Service Bus Data Receiver
  '69a216fc-b8fb-44d8-bc22-1f3c2cd27a39'      // Azure Service Bus Data Sender
]

var storageAccountRoles string[] = [
  'b7e6dc6d-f1e8-4753-8033-0f276bb0955b'      // Storage Blob Data Owner (Contributor is insufficient when using managed identity for AzureWebJobsStorage in Function or Logic Apps)
  isAdmin 
    ? '69566ab7-960f-475b-8e7c-b3118f30c6bd'  // Storage File Data Privileged Contributor (is able to browse file shares in Azure Portal)
    : '0c867c2a-1d8c-454a-a3db-ab2ea1bdc8bb'  // Storage File Data SMB Share Contributor
  '974c5e8b-45b9-4653-ba55-5f855dd0fb88'      // Storage Queue Data Contributor
  '0a9a7e1f-b9d0-4cc4-a60d-0319b160aaa3'      // Storage Table Data Contributor
]

var monitoringMetricsPublisher string = '3913510d-42f4-4e42-8a64-420c390055eb' // Monitoring Metrics Publisher

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

resource storageAccount 'Microsoft.Storage/storageAccounts@2025-06-01' existing = {
  name: storageAccountName
}

//=============================================================================
// Resources
//=============================================================================

// Assign role Application Insights to the principal

resource assignAppInsightRolesToPrincipal 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(principalId, appInsights.id, subscriptionResourceId('Microsoft.Authorization/roleDefinitions', monitoringMetricsPublisher))
  scope: appInsights
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', monitoringMetricsPublisher)
    principalId: principalId
    principalType: principalType
  }
}

// Assign role on Event Hubs namespace to the principal (if Event Hubs namespace is included)

resource assignRolesOnEventHubNamespaceToPrincipal 'Microsoft.Authorization/roleAssignments@2022-04-01' = [for role in eventHubRoles: if (eventHubSettings != null) {
  name: guid(principalId, eventHubsNamespace.id, subscriptionResourceId('Microsoft.Authorization/roleDefinitions', role))
  scope: eventHubsNamespace
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', role)
    principalId: principalId
    principalType: principalType
  }
}]

// Assign role on Key Vault to the principal

resource assignRolesOnKeyVaultToPrincipal 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(principalId, keyVault.id, subscriptionResourceId('Microsoft.Authorization/roleDefinitions', keyVaultRole))
  scope: keyVault
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', keyVaultRole)
    principalId: principalId
    principalType: principalType
  }
}

// Assign roles on Service Bus to the principal (if Service Bus is included)

resource assignRolesOnServiceBusToPrincipal 'Microsoft.Authorization/roleAssignments@2022-04-01' = [for role in serviceBusRoles: if (serviceBusSettings != null) {
  name: guid(principalId, serviceBusNamespace.id, subscriptionResourceId('Microsoft.Authorization/roleDefinitions', role))
  scope: serviceBusNamespace
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', role)
    principalId: principalId
    principalType: principalType
  }
}]

// Assign roles on Storage Account to the principal

resource assignRolesOnStorageAccountToPrincipal 'Microsoft.Authorization/roleAssignments@2022-04-01' = [for role in storageAccountRoles: {
  name: guid(principalId, storageAccount.id, subscriptionResourceId('Microsoft.Authorization/roleDefinitions', role))
  scope: storageAccount
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', role)
    principalId: principalId
    principalType: principalType
  }
}]
