//=============================================================================
// Logic App
//=============================================================================

//=============================================================================
// Imports
//=============================================================================

import { logicAppSettingsType } from '../types/settings.bicep'

//=============================================================================
// Parameters
//=============================================================================

@description('Location to use for all resources')
param location string

@description('The settings for the Logic App that will be created')
param logicAppSettings logicAppSettingsType

@description('The name of the App Insights instance that will be used by the Logic App')
param appInsightsName string

@description('The name of the Key Vault that will contain the secrets')
param keyVaultName string

@description('Name of the storage account that will be used by the Logic App')
param storageAccountName string

//=============================================================================
// Variables
//=============================================================================

var storageAccountConnectionString = 'DefaultEndpointsProtocol=https;AccountName=${storageAccountName};EndpointSuffix=${environment().suffixes.storage};AccountKey=${storageAccount.listKeys().keys[0].value}'

//=============================================================================
// Existing resources
//=============================================================================

resource appInsights 'Microsoft.Insights/components@2020-02-02' existing = {
  name: appInsightsName
}

resource storageAccount 'Microsoft.Storage/storageAccounts@2023-04-01' existing = {
  name: storageAccountName
}

//=============================================================================
// Resources
//=============================================================================

// Create Logic App identity and assign roles to it

resource logicAppIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: logicAppSettings.identityName
  location: location
}

module assignRolesToLogicAppIdentity 'assign-roles-to-principal.bicep' = {
  name: 'assignRolesToLogicAppIdentity'
  params: {
    principalId: logicAppIdentity.properties.principalId
    keyVaultName: keyVaultName
    storageAccountName: storageAccountName
  }
}


// Create the Application Service Plan for the Logic App

resource hostingPlan 'Microsoft.Web/serverfarms@2021-03-01' = {
  name: logicAppSettings.appServicePlanName
  location: location
  kind: 'elastic'
  sku: {
    name: 'WS1'
    tier: 'WorkflowStandard'
  }
  properties: {
    elasticScaleEnabled: false
  }
}


// Create the Logic App

resource logicApp 'Microsoft.Web/sites@2021-03-01' = {
  name: logicAppSettings.logicAppName
  location: location
  kind: 'functionapp,workflowapp'
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${logicAppIdentity.id}': {}
    }
  }
  properties: {
    serverFarmId: hostingPlan.id
    keyVaultReferenceIdentity: logicAppIdentity.id
    siteConfig: {
      appSettings: [
        {
          name: 'APP_KIND'
          value: 'workflowApp'
        }
        {
          name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
          value: appInsights.properties.ConnectionString
        }
        {
          name: 'AzureWebJobsStorage'
          value: storageAccountConnectionString
        }
        {
          name: 'FUNCTIONS_EXTENSION_VERSION'
          value: '~4'
        }
        {
          name: 'FUNCTIONS_WORKER_RUNTIME'
          value: 'dotnet'
        }
        {
          name: 'WEBSITE_CONTENTAZUREFILECONNECTIONSTRING'
          value: storageAccountConnectionString
        }
        {
          name: 'WEBSITE_CONTENTSHARE'
          value: toLower(logicAppSettings.logicAppName)
        }
        {
          name: 'WEBSITE_NODE_DEFAULT_VERSION'
          value: '~20'
        }
      ]
      ftpsState: 'FtpsOnly'
      minTlsVersion: '1.2'
      netFrameworkVersion: logicAppSettings.netFrameworkVersion
    }
    httpsOnly: true
  }
}
