//=============================================================================
// API Management
//=============================================================================

//=============================================================================
// Imports
//=============================================================================

import { apiManagementSettingsType } from '../../types/settings.bicep'

//=============================================================================
// Parameters
//=============================================================================

@description('Location to use for all resources')
param location string

@description('The tags to associate with the resource')
param tags object

@description('The settings for the API Management Service that will be created')
param apiManagementSettings apiManagementSettingsType

@description('The name of the App Insights instance that will be created and used by API Management')
param appInsightsName string

@description('The name of the Key Vault that will contain the secrets')
param keyVaultName string

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

resource appInsights 'Microsoft.Insights/components@2020-02-02' existing = {
  name: appInsightsName
}

resource keyVault 'Microsoft.KeyVault/vaults@2023-07-01' existing = {
  name: keyVaultName
}

resource masterSubscription 'Microsoft.ApiManagement/service/subscriptions@2022-08-01' existing = {
  name: 'master'
  parent: apiManagementService
}

//=============================================================================
// Resources
//=============================================================================

// Create API Management user-assigned identity and assign roles to it

resource apimIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: apiManagementSettings.identityName
  location: location
  tags: tags
}

module assignRolesToApimUserAssignedIdentity '../shared/assign-roles-to-principal.bicep' = {
  name: 'assignRolesToApimUserAssignedIdentity'
  params: {
    principalId: apimIdentity.properties.principalId
    keyVaultName: keyVaultName
    storageAccountName: storageAccountName
  }
}


// API Management - Consumption tier (see also: https://learn.microsoft.com/en-us/azure/api-management/quickstart-bicep?tabs=CLI)

resource apiManagementService 'Microsoft.ApiManagement/service@2022-08-01' = {
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
    type: 'SystemAssigned, UserAssigned'
    userAssignedIdentities: {
      '${apimIdentity.id}': {}
    }
  }
}


// Assign roles to system-assigned identity of API Management

module assignRolesToApimSystemAssignedIdentity '../shared/assign-roles-to-principal.bicep' = {
  name: 'assignRolesToApimSystemAssignedIdentity'
  params: {
    principalId: apiManagementService.identity.principalId
    keyVaultName: keyVaultName
    storageAccountName: storageAccountName
  }
}


// Store the app insights instrumentation key in a named value

resource appInsightsInstrumentationKeyNamedValue 'Microsoft.ApiManagement/service/namedValues@2022-08-01' = {
  name: 'appin-instrumentation-key'
  parent: apiManagementService
  properties: {
    displayName: 'appin-instrumentation-key'
    value: appInsights.properties.InstrumentationKey
  }
}


// Configure API Management to log to App Insights
// - we need a logger that is connected to the App Insights instance
// - we need diagnostics settings that specify what to log to the logger

resource apimAppInsightsLogger 'Microsoft.ApiManagement/service/loggers@2022-08-01' = {
  name: appInsightsName
  parent: apiManagementService
  properties: {
    loggerType: 'applicationInsights'
    credentials: {
      // If we would reference the instrumentation key directly using appInsights.properties.InstrumentationKey,
      // a new named value is created every time we execute a deployment
      instrumentationKey: '{{${appInsightsInstrumentationKeyNamedValue.properties.displayName}}}'
    }
    resourceId: appInsights.id
  }
}

resource apimInsightsDiagnostics 'Microsoft.ApiManagement/service/diagnostics@2022-08-01' = {
  name: 'applicationinsights' // The name of the diagnostics resource has to be applicationinsights, because that's the logger type we chose
  parent: apiManagementService
  properties: {
    alwaysLog: 'allErrors'
    loggerId: apimAppInsightsLogger.id
    httpCorrelationProtocol: 'W3C' // Enable logging to app insights in W3C format
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
