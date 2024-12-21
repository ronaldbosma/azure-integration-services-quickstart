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

resource apiManagementService 'Microsoft.ApiManagement/service@2022-08-01' existing = {
  name: apiManagementServiceName
}

//=============================================================================
// Resources
//=============================================================================

resource sampleApi 'Microsoft.ApiManagement/service/apis@2022-08-01' = {
  name: 'sample'
  parent: apiManagementService
  properties: {
    path: 'sample'
    format: 'openapi'
    value: loadTextContent('sample-api.openapi.yaml')
    type: 'http'
    protocols: [
      'https'
    ]
    subscriptionRequired: true
  }
}
