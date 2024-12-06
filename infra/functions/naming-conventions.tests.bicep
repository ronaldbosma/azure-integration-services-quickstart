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


//=============================================================================
// Environment Names
//=============================================================================

test testEnvironmentName 'naming-conventions.test-module.bicep' = {
  params: {
    resourceType: 'resourceGroup'
    environment: 'sample-environment'
    region: 'norwayeast'
    instance: '12345'
    expectedResult: 'rg-sample-environment-nwe-12345'
  }
}


//=============================================================================
// Locations
//=============================================================================

test testLocationNorwayEast 'naming-conventions.test-module.bicep' = {
  params: {
    resourceType: 'resourceGroup'
    environment: 'aisquick'
    region: 'norwayeast'
    instance: '12345'
    expectedResult: 'rg-aisquick-nwe-12345'
  }
}

test testLocationSwedenCentral 'naming-conventions.test-module.bicep' = {
  params: {
    resourceType: 'resourceGroup'
    environment: 'aisquick'
    region: 'swedencentral'
    instance: '12345'
    expectedResult: 'rg-aisquick-sdc-12345'
  }
}

test testLocationEastUS2 'naming-conventions.test-module.bicep' = {
  params: {
    resourceType: 'resourceGroup'
    environment: 'aisquick'
    region: 'eastus2'
    instance: '12345'
    expectedResult: 'rg-aisquick-eus2-12345'
  }
}


//=============================================================================
// Instances
//=============================================================================

test testInstance12345 'naming-conventions.test-module.bicep' = {
  params: {
    resourceType: 'resourceGroup'
    environment: 'aisquick'
    region: 'norwayeast'
    instance: '12345'
    expectedResult: 'rg-aisquick-nwe-12345'
  }
}

test testInstanceAbcde 'naming-conventions.test-module.bicep' = {
  params: {
    resourceType: 'resourceGroup'
    environment: 'aisquick'
    region: 'norwayeast'
    instance: 'abcde'
    expectedResult: 'rg-aisquick-nwe-abcde'
  }
}


//=============================================================================
// Shortened Names
//=============================================================================

test testShortenedStorageAccountName 'naming-conventions.test-module.bicep' = {
  params: {
    resourceType: 'storageAccount'
    environment: 'aisquick'
    region: 'norwayeast'
    instance: 'abcde'
    expectedResult: 'staisquicknweabcde'
  }
}

test testShortenedKeyVaultName 'naming-conventions.test-module.bicep' = {
  params: {
    resourceType: 'keyVault'
    environment: 'aisquick'
    region: 'norwayeast'
    instance: 'abcde'
    expectedResult: 'kvaisquicknweabcde'
  }
}

test testStorageAccountNameWhenEnvironmentNameIsTooLong 'naming-conventions.test-module.bicep' = {
  params: {
    resourceType: 'storageAccount'
    environment: 'thisenvironmentnameistoolong'
    region: 'eastus2'
    instance: 'abcde'
    expectedResult: 'stthisenvironmeus2abcde'
  }
}

test testKeyVaultNameWhenEnvironmentNameIsTooLong 'naming-conventions.test-module.bicep' = {
  params: {
    resourceType: 'keyVault'
    environment: 'thisenvironmentnameistoolong'
    region: 'eastus2'
    instance: 'abcde'
    expectedResult: 'kvthisenvironmeus2abcde'
  }
}