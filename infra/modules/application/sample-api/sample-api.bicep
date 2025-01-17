//=============================================================================
// Sample API in API Management
//=============================================================================

//=============================================================================
// Imports
//=============================================================================

import { apiManagementSettingsType, serviceBusSettingsType } from '../../../types/settings.bicep'

//=============================================================================
// Parameters
//=============================================================================

@description('The name of the API Management service')
param apiManagementServiceName string

@description('The settings for the Service Bus namespace')
param serviceBusSettings serviceBusSettingsType?

//=============================================================================
// Existing resources
//=============================================================================

resource apiManagementService 'Microsoft.ApiManagement/service@2023-09-01-preview' existing = {
  name: apiManagementServiceName
}

//=============================================================================
// Resources
//=============================================================================

resource sampleApi 'Microsoft.ApiManagement/service/apis@2023-09-01-preview' = {
  name: 'aisquick-sample'
  parent: apiManagementService
  properties: {
    path: 'aisquick-sample'
    format: 'openapi'
    value: loadTextContent('openapi.yaml')
    type: 'http'
    protocols: [
      'https'
    ]
    subscriptionRequired: true
  }
  
  resource policies 'policies' = {
    name: 'policy'
    properties: {
      format: 'rawxml'
      value: loadTextContent('sample-api.xml')
    }
  }
}

resource getBlobOperation 'Microsoft.ApiManagement/service/apis/operations@2023-09-01-preview' existing = {
  name: 'get-blob'
  parent: sampleApi

  resource policies 'policies' = {
    name: 'policy'
    properties:{
      format: 'rawxml'
      value: loadTextContent('operations/get-blob.xml') 
    }
  }
}

resource getTableEntityOperation 'Microsoft.ApiManagement/service/apis/operations@2023-09-01-preview' existing = {
  name: 'get-table-entity'
  parent: sampleApi

  resource policies 'policies' = {
    name: 'policy'
    properties:{
      format: 'rawxml'
      value: loadTextContent('operations/get-table-entity.xml') 
    }
  }
}

// Only set policy on publish message operation if the Service Bus has been deployed, otherwise it will fail
resource publishMessageToServiceBusOperation 'Microsoft.ApiManagement/service/apis/operations@2023-09-01-preview' existing = if (serviceBusSettings != null) {
  name: 'publish-message-to-service-bus'
  parent: sampleApi

  resource policies 'policies' = {
    name: 'policy'
    properties:{
      format: 'rawxml'
      value: loadTextContent('operations/publish-message-to-service-bus.xml') 
    }
  }
}
