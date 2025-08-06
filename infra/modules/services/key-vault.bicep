//=============================================================================
// Key Vault
//=============================================================================

//=============================================================================
// Parameters
//=============================================================================

@description('Specifies the Azure Active Directory tenant ID that should be used for authenticating requests to the key vault. Get it by using Get-AzSubscription cmdlet.')
param tenantId string = subscription().tenantId

@description('Location to use for all resources')
param location string

@description('The tags to associate with the resource')
param tags object

@description('The name of the Key Vault that will contain the secrets')
@maxLength(24)
param keyVaultName string

//=============================================================================
// Resources
//=============================================================================

// Key Vault (see also: https://learn.microsoft.com/en-us/azure/key-vault/secrets/quick-create-bicep?tabs=CLI)

resource keyVault 'Microsoft.KeyVault/vaults@2024-11-01' = {
  name: keyVaultName
  location: location
  tags: tags
  properties: {
    tenantId: tenantId
    enableRbacAuthorization: true
    enableSoftDelete: false // Disable soft delete so cleanup is easier and faster
    sku: {
      name: 'standard'
      family: 'A'
    }
    networkAcls: {
      bypass: 'AzureServices'
    }
  }
}
