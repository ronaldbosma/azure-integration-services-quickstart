//=============================================================================
// Assign roles to principal on Key Vault and Storage Account
//=============================================================================

//=============================================================================
// Parameters
//=============================================================================

@description('The id of the principal that will be assigned the roles')
param principalId string

@description('The type of the principal that will be assigned the roles')
param principalType string = 'ServicePrincipal'

@description('The name of the Key Vault on which to assign roles')
param keyVaultName string

@description('The name of the Storage Account on which to assign roles')
param storageAccountName string

//=============================================================================
// Variables
//=============================================================================

var keyVaultRoles = [
  '4633458b-17de-408a-b874-0445c86b69e6'  // Key Vault Secrets User
]

var storageAccountRoles = [
  'ba92f5b4-2d11-453d-a403-e96b0029c9fe'  // Storage Blob Data Contributor
  '0c867c2a-1d8c-454a-a3db-ab2ea1bdc8bb'  // Storage File Data SMB Share Contributor
  '974c5e8b-45b9-4653-ba55-5f855dd0fb88'  // Storage Queue Data Contributor
  '0a9a7e1f-b9d0-4cc4-a60d-0319b160aaa3'  // Storage Table Data Contributor
]


//=============================================================================
// Existing Resources
//=============================================================================

resource keyVault 'Microsoft.KeyVault/vaults@2023-07-01' existing = {
  name: keyVaultName
}

resource storageAccount 'Microsoft.Storage/storageAccounts@2023-05-01' existing = {
  name: storageAccountName
}

//=============================================================================
// Resources
//=============================================================================

// Assign roles on Key Vault to the principal

resource assignRolesOnKeyVaultToManagedIdentity 'Microsoft.Authorization/roleAssignments@2022-04-01' = [for role in keyVaultRoles: {
  name: guid(principalId, keyVault.id, subscriptionResourceId('Microsoft.Authorization/roleDefinitions', role))
  scope: keyVault
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', role)
    principalId: principalId
    principalType: principalType
  }
}]

// Assign roles on Storage Account to the principal

resource assignRolesOnStorageAccountToManagedIdentity 'Microsoft.Authorization/roleAssignments@2022-04-01' = [for role in storageAccountRoles: {
  name: guid(principalId, storageAccount.id, subscriptionResourceId('Microsoft.Authorization/roleDefinitions', role))
  scope: storageAccount
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', role)
    principalId: principalId
    principalType: principalType
  }
}]
