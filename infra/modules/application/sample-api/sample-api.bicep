//=============================================================================
// Sample API in API Management
//=============================================================================

//=============================================================================
// Parameters
//=============================================================================

@description('The name of the API Management service')
param apiManagementServiceName string

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
}

resource getBlobOperation 'Microsoft.ApiManagement/service/apis/operations@2023-09-01-preview' existing = {
  name: 'get-blob'
  parent: sampleApi

  resource policies 'policies' = {
    name: 'policy'
    properties:{
      format: 'rawxml'
      value: loadTextContent('get-blob.xml') 
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
      value: loadTextContent('get-table-entity.xml') 
    }
  }
}

resource publishMessageOperation 'Microsoft.ApiManagement/service/apis/operations@2023-09-01-preview' existing = {
  name: 'publish-message'
  parent: sampleApi

  resource policies 'policies' = {
    name: 'policy'
    properties:{
      format: 'rawxml'
      value: loadTextContent('publish-message.xml') 
    }
  }
}
