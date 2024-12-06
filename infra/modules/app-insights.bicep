//=============================================================================
// Application Insights
//=============================================================================

//=============================================================================
// Imports
//=============================================================================

import { appInsightsSettingsType } from '../types/settings.bicep'

//=============================================================================
// Parameters
//=============================================================================

@description('Location to use for all resources')
param location string

@description('The tags to associate with the resource')
param tags object

@description('The settings for the App Insights instance that will be created')
param appInsightsSettings appInsightsSettingsType

@description('The name of the Key Vault that will contain the secrets')
@maxLength(24)
param keyVaultName string

//=============================================================================
// Existing Resources
//=============================================================================

resource keyVault 'Microsoft.KeyVault/vaults@2023-07-01' existing = {
  name: keyVaultName
}

//=============================================================================
// Resources
//=============================================================================

// Log Analytics Workspace

resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2023-09-01' = {
  name: appInsightsSettings.logAnalyticsWorkspaceName
  location: location
  tags: tags
  properties: {
    retentionInDays: appInsightsSettings.retentionInDays
    sku: {
      name: 'Standalone'
    }
  }
}


// Application Insights

resource appInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: appInsightsSettings.appInsightsName
  location: location
  tags: tags
  kind: 'web'
  properties: {
    Application_Type: 'web'
    publicNetworkAccessForIngestion: 'Enabled'
    publicNetworkAccessForQuery: 'Enabled'
    WorkspaceResourceId: logAnalyticsWorkspace.id
    RetentionInDays: appInsightsSettings.retentionInDays
  }
}


// Store secrets in Key Vault

resource appInsightsInstrumentationKeySecret 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = {
  name: 'applicationinsights-instrumentationkey'
  parent: keyVault
  properties: {
    value: appInsights.properties.InstrumentationKey
  }
}

resource appInsightsConnectionStringSecret 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = {
  name: 'applicationinsights-connectionstring'
  parent: keyVault
  properties: {
    value: appInsights.properties.ConnectionString
  }
}
