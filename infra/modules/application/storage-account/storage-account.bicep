//=============================================================================
// Storage Account Containers, Tables, etc.
//=============================================================================

//=============================================================================
// Parameters
//=============================================================================

@description('Name of the storage account that will be used by the Function App')
param storageAccountName string

//=============================================================================
// Existing resources
//=============================================================================

resource storageAccount 'Microsoft.Storage/storageAccounts@2023-05-01' existing = {
  name: storageAccountName
}

resource storageAccountBlobServices 'Microsoft.Storage/storageAccounts/blobServices@2023-05-01' existing = {
  parent: storageAccount
  name: 'default'
}

resource storageAccountTableServices 'Microsoft.Storage/storageAccounts/tableServices@2023-05-01' existing = {
  parent: storageAccount
  name: 'default'
}

//=============================================================================
// Resources
//=============================================================================

resource sampleContainer 'Microsoft.Storage/storageAccounts/blobServices/containers@2023-05-01' = {
  parent: storageAccountBlobServices
  name: 'aisquick-sample'
}

resource sampleTable 'Microsoft.Storage/storageAccounts/tableServices/tables@2023-05-01' = {
  parent: storageAccountTableServices
  name: 'aisquickSample'
}
