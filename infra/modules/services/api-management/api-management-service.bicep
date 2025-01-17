//=============================================================================
// Create API Management Service including
// - role assignments
// - stores the master subscription key in Key Vault
//=============================================================================

//=============================================================================
// Imports
//=============================================================================

import { apiManagementSettingsType, eventHubSettingsType, serviceBusSettingsType } from '../../../types/settings.bicep'

//=============================================================================
// Parameters
//=============================================================================

@description('Location to use for all resources')
param location string

@description('The tags to associate with the resource')
param tags object

@description('The settings for the API Management Service that will be created')
param apiManagementSettings apiManagementSettingsType

@description('The settings for the Event Hub namespace')
param eventHubSettings eventHubSettingsType?

@description('The name of the Key Vault that will contain the secrets')
param keyVaultName string

@description('The settings for the Service Bus namespace')
param serviceBusSettings serviceBusSettingsType?

@description('Name of the storage account that will be used by the Function App')
param storageAccountName string

//=============================================================================
// Variables
//=============================================================================

var serviceTags = union(tags, {
  'azd-service-name': 'apim'
})

//=============================================================================
// Existing resources
//=============================================================================

resource keyVault 'Microsoft.KeyVault/vaults@2023-07-01' existing = {
  name: keyVaultName
}

resource masterSubscription 'Microsoft.ApiManagement/service/subscriptions@2023-09-01-preview' existing = {
  name: 'master'
  parent: apiManagementService
}

//=============================================================================
// Resources
//=============================================================================

// API Management - Consumption tier (see also: https://learn.microsoft.com/en-us/azure/api-management/quickstart-bicep?tabs=CLI)

resource apiManagementService 'Microsoft.ApiManagement/service@2023-09-01-preview' = {
  name: apiManagementSettings.serviceName
  location: location
  tags: serviceTags
  sku: {
    name: 'Consumption'
    capacity: 0
  }
  properties: {
    publisherName: apiManagementSettings.publisherName
    publisherEmail: apiManagementSettings.publisherEmail
  }
  identity: {
    type: 'SystemAssigned'
  }
}

// Assign roles to system-assigned identity of API Management

module assignRolesToApimSystemAssignedIdentity '../../shared/assign-roles-to-principal.bicep' = {
  name: 'assignRolesToApimSystemAssignedIdentity'
  params: {
    principalId: apiManagementService.identity.principalId
    eventHubSettings: eventHubSettings
    keyVaultName: keyVaultName
    serviceBusSettings: serviceBusSettings
    storageAccountName: storageAccountName
  }
}

// Store master subscription key in Key Vault

resource apimMasterSubscriptionKeySecret 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = {
  name: 'apim-master-subscription-key'
  parent: keyVault
  properties: {
    value: masterSubscription.listSecrets(apiManagementService.apiVersion).primaryKey
  }
}
