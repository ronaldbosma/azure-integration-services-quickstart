//=============================================================================
// Tests for the getResourceName function
// 
// - Run tests with the command: bicep test .\naming-conventions.tests.bicep
//=============================================================================

//=============================================================================
// Prefixes
//=============================================================================

test testPrefixResourceGroup 'naming-conventions.test-module.bicep' = {
  params: {
    resourceType: 'resourceGroup'
    environment: 'aisquick'
    region: 'norwayeast'
    instance: '12345'
    expectedResult: 'rg-aisquick-nwe-12345'
  }
}

test testPrefixApiManagement 'naming-conventions.test-module.bicep' = {
  params: {
    resourceType: 'apiManagement'
    environment: 'aisquick'
    region: 'norwayeast'
    instance: '12345'
    expectedResult: 'apim-aisquick-nwe-12345'
  }
}

test testPrefixFunctionApp 'naming-conventions.test-module.bicep' = {
  params: {
    resourceType: 'functionApp'
    environment: 'aisquick'
    region: 'norwayeast'
    instance: '12345'
    expectedResult: 'func-aisquick-nwe-12345'
  }
}
