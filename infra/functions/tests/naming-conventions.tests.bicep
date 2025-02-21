//=============================================================================
// Tests for the getResourceName function
// 
// - Run tests with the command: bicep test .\naming-conventions.tests.bicep
//=============================================================================

//=============================================================================
// Prefixes
//=============================================================================

test testPrefixResourceGroup 'naming-conventions.getResourceName.bicep' = {
  params: {
    resourceType: 'resourceGroup'
    environment: 'myenv'
    region: 'norwayeast'
    instance: '12345'
    expectedResult: 'rg-myenv-nwe-12345'
  }
}

test testPrefixApiManagement 'naming-conventions.getResourceName.bicep' = {
  params: {
    resourceType: 'apiManagement'
    environment: 'myenv'
    region: 'norwayeast'
    instance: '12345'
    expectedResult: 'apim-myenv-nwe-12345'
  }
}

test testPrefixFunctionApp 'naming-conventions.getResourceName.bicep' = {
  params: {
    resourceType: 'functionApp'
    environment: 'myenv'
    region: 'norwayeast'
    instance: '12345'
    expectedResult: 'func-myenv-nwe-12345'
  }
}


//=============================================================================
// Environment Names
//=============================================================================

test testEnvironmentName 'naming-conventions.getResourceName.bicep' = {
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

test testLocationNorwayEast 'naming-conventions.getResourceName.bicep' = {
  params: {
    resourceType: 'resourceGroup'
    environment: 'myenv'
    region: 'norwayeast'
    instance: '12345'
    expectedResult: 'rg-myenv-nwe-12345'
  }
}

test testLocationSwedenCentral 'naming-conventions.getResourceName.bicep' = {
  params: {
    resourceType: 'resourceGroup'
    environment: 'myenv'
    region: 'swedencentral'
    instance: '12345'
    expectedResult: 'rg-myenv-sdc-12345'
  }
}

test testLocationEastUS2 'naming-conventions.getResourceName.bicep' = {
  params: {
    resourceType: 'resourceGroup'
    environment: 'myenv'
    region: 'eastus2'
    instance: '12345'
    expectedResult: 'rg-myenv-eus2-12345'
  }
}


//=============================================================================
// Instances
//=============================================================================

test testInstance12345 'naming-conventions.getResourceName.bicep' = {
  params: {
    resourceType: 'resourceGroup'
    environment: 'myenv'
    region: 'norwayeast'
    instance: '12345'
    expectedResult: 'rg-myenv-nwe-12345'
  }
}

test testInstanceAbcde 'naming-conventions.getResourceName.bicep' = {
  params: {
    resourceType: 'resourceGroup'
    environment: 'myenv'
    region: 'norwayeast'
    instance: 'abcde'
    expectedResult: 'rg-myenv-nwe-abcde'
  }
}


//=============================================================================
// Shortened Names
//=============================================================================

test testShortenedStorageAccountName 'naming-conventions.getResourceName.bicep' = {
  params: {
    resourceType: 'storageAccount'
    environment: 'myenv'
    region: 'norwayeast'
    instance: 'abcde'
    expectedResult: 'stmyenvnweabcde'
  }
}

test testShortenedKeyVaultName 'naming-conventions.getResourceName.bicep' = {
  params: {
    resourceType: 'keyVault'
    environment: 'myenv'
    region: 'norwayeast'
    instance: 'abcde'
    expectedResult: 'kvmyenvnweabcde'
  }
}

test testStorageAccountNameWhenEnvironmentNameIsTooLong 'naming-conventions.getResourceName.bicep' = {
  params: {
    resourceType: 'storageAccount'
    environment: 'thisenvironmentnameistoolong'
    region: 'eastus2'
    instance: 'abcde'
    expectedResult: 'stthisenvironmeus2abcde'
  }
}

test testKeyVaultNameWhenEnvironmentNameIsTooLong 'naming-conventions.getResourceName.bicep' = {
  params: {
    resourceType: 'keyVault'
    environment: 'thisenvironmentnameistoolong'
    region: 'eastus2'
    instance: 'abcde'
    expectedResult: 'kvthisenvironmeus2abcde'
  }
}


//=============================================================================
// Sanitizing Name
//=============================================================================

test testSanitizeColon 'naming-conventions.getResourceName.bicep' = {
  params: {
    resourceType: 'virtualNetwork'
    environment: 'my;env'
    region: 'norwayeast'
    instance: '0;01'
    expectedResult: 'vnet-myenv-nwe-001'
  }
}

test testSanitizeComma 'naming-conventions.getResourceName.bicep' = {
  params: {
    resourceType: 'virtualNetwork'
    environment: 'my,env'
    region: 'norwayeast'
    instance: '0,01'
    expectedResult: 'vnet-myenv-nwe-001'
  }
}

test testSanitizeDot 'naming-conventions.getResourceName.bicep' = {
  params: {
    resourceType: 'virtualNetwork'
    environment: 'my.env'
    region: 'norwayeast'
    instance: '0.01'
    expectedResult: 'vnet-myenv-nwe-001'
  }
}

test testSanitizeSemicolon 'naming-conventions.getResourceName.bicep' = {
  params: {
    resourceType: 'virtualNetwork'
    environment: 'my:env'
    region: 'norwayeast'
    instance: '0:01'
    expectedResult: 'vnet-myenv-nwe-001'
  }
}

test testSanitizeUnderscore 'naming-conventions.getResourceName.bicep' = {
  params: {
    resourceType: 'virtualNetwork'
    environment: 'my_env'
    region: 'norwayeast'
    instance: '0_01'
    expectedResult: 'vnet-myenv-nwe-001'
  }
}

test testSanitizeWhiteSpace 'naming-conventions.getResourceName.bicep' = {
  params: {
    resourceType: 'virtualNetwork'
    environment: 'my env'
    region: 'norwayeast'
    instance: '0 01'
    expectedResult: 'vnet-myenv-nwe-001'
  }
}

test testSanitizUpperCaseToLowerCase 'naming-conventions.getResourceName.bicep' = {
  params: {
    resourceType: 'virtualNetwork'
    environment: 'MY Env'
    region: 'norwayeast'
    instance: 'Main'
    expectedResult: 'vnet-myenv-nwe-main'
  }
}

test testSanitizeTrailingHyphenWhenInstanceIsEmpty 'naming-conventions.getResourceName.bicep' = {
  params: {
    resourceType: 'virtualNetwork'
    environment: 'myenv'
    region: 'norwayeast'
    instance: ''
    expectedResult: 'vnet-myenv-nwe'
  }
}


//=============================================================================
// Get Instance Id
// NOTE: subscription().subscriptionId = 00000000-0000-0000-0000-000000000000
//=============================================================================


test testGetInstanceIdReturnsGeneratedId 'naming-conventions.getInstanceId.bicep' = {
  params: {
    environment: 'myenv'
    region: 'norwayeast'
    instance: ''
    expectedResult: 'g6r5i'
  }
}

test testGetInstanceIdWithDifferentEnvironment 'naming-conventions.getInstanceId.bicep' = {
  params: {
    environment: 'testenvironment'
    region: 'norwayeast'
    instance: ''
    expectedResult: 'fn7w7'
  }
}

test testGetInstanceIdWithDifferentRegion 'naming-conventions.getInstanceId.bicep' = {
  params: {
    environment: 'myenv'
    region: 'swedencentral'
    instance: ''
    expectedResult: 'gxci3'
  }
}

test testGetInstanceIdReturnsInstanceIfSpecified 'naming-conventions.getInstanceId.bicep' = {
  params: {
    environment: 'myenv'
    region: 'norwayeast'
    instance: 'myinstance'
    expectedResult: 'myinstance'
  }
}
