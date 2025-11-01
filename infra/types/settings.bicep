// API Management

@description('The SKU of the API Management service')
type apimSkuType = 'Consumption' | 'Developer' | 'Basic' | 'Standard' | 'Premium' | 'StandardV2' | 'BasicV2'

@description('The settings for the API Management service')
@export()
type apiManagementSettingsType = {
  @description('The name of the API Management service')
  serviceName: string

  @description('The name of the user-assigned managed identity for the API Management service')
  identityName: string

  @description('The SKU of the API Management service')
  sku: apimSkuType
}


// Application Insights

@description('Retention options for Application Insights')
type appInsightsRetentionInDaysType = 30 | 60 | 90 | 120 | 180 | 270 | 365 | 550 | 730

@description('The settings for the App Insights instance')
@export()
type appInsightsSettingsType = {
  @description('The name of the App Insights instance')
  appInsightsName: string

  @description('The name of the Log Analytics workspace that will be used by the App Insights instance')
  logAnalyticsWorkspaceName: string

  @description('Retention in days of the logging')
  retentionInDays: appInsightsRetentionInDaysType
}


// Event Hub

@description('The settings for the Event Hub')
@export()
type eventHubSettingsType = {
  @description('The name of the Event Hubs namespace')
  namespaceName: string
}


// Function App

@description('The settings for the Function App')
@export()
type functionAppSettingsType = {
  @description('The name of the Function App')
  functionAppName: string

  @description('The name of the user-assigned managed identity for the Function App')
  identityName: string

  @description('The name of the App Service for the Function App')
  appServicePlanName: string

  @description('The .NET Framework version for the Function App')
  netFrameworkVersion: string
}


// Logic App

@description('The settings for the Logic App')
@export()
type logicAppSettingsType = {
  @description('The name of the Logic App')
  logicAppName: string

  @description('The name of the user-assigned managed identity for the Logic App')
  identityName: string

  @description('The name of the App Service for the Logic App')
  appServicePlanName: string

  @description('The .NET Framework version for the Logic App')
  netFrameworkVersion: string
}


// Service Bus

@description('The settings for the Service Bus namespace')
@export()
type serviceBusSettingsType = {
  @description('The name of the Service Bus namespace')
  namespaceName: string
}
