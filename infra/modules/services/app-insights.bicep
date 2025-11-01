//=============================================================================
// Application Insights
//=============================================================================

//=============================================================================
// Imports
//=============================================================================

import { appInsightsSettingsType } from '../../types/settings.bicep'

//=============================================================================
// Parameters
//=============================================================================

@description('Location to use for all resources')
param location string

@description('The tags to associate with the resource')
param tags object

@description('The settings for the App Insights instance that will be created')
param appInsightsSettings appInsightsSettingsType

//=============================================================================
// Resources
//=============================================================================

// Log Analytics Workspace

resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2025-02-01' = {
  name: appInsightsSettings.logAnalyticsWorkspaceName
  location: location
  tags: tags
  properties: {
    retentionInDays: appInsightsSettings.retentionInDays
    sku: {
      name: 'PerGB2018'
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
