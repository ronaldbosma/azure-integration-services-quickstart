//=============================================================================
// Add backends for the various services to API Management
//=============================================================================

//=============================================================================
// Imports
//=============================================================================

import * as helpers from '../../../functions/helpers.bicep'
import { apiManagementSettingsType, eventHubSettingsType, serviceBusSettingsType } from '../../../types/settings.bicep'

//=============================================================================
// Parameters
//=============================================================================

@description('The settings for the API Management Service that will be created')
param apiManagementSettings apiManagementSettingsType

@description('The settings for the Event Hub namespace')
param eventHubSettings eventHubSettingsType?

@description('The settings for the Service Bus namespace')
param serviceBusSettings serviceBusSettingsType?

@description('Name of the storage account that will be used by the Function App')
param storageAccountName string

//=============================================================================
// Existing resources
//=============================================================================

resource apiManagementService 'Microsoft.ApiManagement/service@2023-09-01-preview' existing = {
  name: apiManagementSettings.serviceName
}

//=============================================================================
// Resources
//=============================================================================

// Event Hub backends

resource eventHubBackend 'Microsoft.ApiManagement/service/backends@2023-09-01-preview' = if (eventHubSettings != null) {
  parent: apiManagementService
  name: 'event-hub'
  properties: {
    description: 'The backend for the event hub'
    url: helpers.getEventHubEndpoint(eventHubSettings!.namespaceName, eventHubSettings!.eventHubName)
    protocol: 'http'
    tls: {
      validateCertificateChain: true
      validateCertificateName: true
    }
  }
}

// Service Bus backends

resource serviceBusBackend 'Microsoft.ApiManagement/service/backends@2023-09-01-preview' = if (serviceBusSettings != null) {
  parent: apiManagementService
  name: 'service-bus'
  properties: {
    description: 'The backend for the service bus'
    url: helpers.getServiceBusEndpoint(serviceBusSettings!.namespaceName)
    protocol: 'http'
    tls: {
      validateCertificateChain: true
      validateCertificateName: true
    }
  }
}

// Storage Account backends

resource blobStorageBackend 'Microsoft.ApiManagement/service/backends@2023-09-01-preview' = {
  parent: apiManagementService
  name: 'blob-storage'
  properties: {
    description: 'The backend for blob storage'
    url: helpers.getBlobStorageEndpoint(storageAccountName)
    protocol: 'http'
    tls: {
      validateCertificateChain: true
      validateCertificateName: true
    }
  }
}

resource queueStorageBackend 'Microsoft.ApiManagement/service/backends@2023-09-01-preview' = {
  parent: apiManagementService
  name: 'queue-storage'
  properties: {
    description: 'The backend for queue storage'
    url: helpers.getQueueStorageEndpoint(storageAccountName)
    protocol: 'http'
    tls: {
      validateCertificateChain: true
      validateCertificateName: true
    }
  }
}

resource tableStorageBackend 'Microsoft.ApiManagement/service/backends@2023-09-01-preview' = {
  parent: apiManagementService
  name: 'table-storage'
  properties: {
    description: 'The backend for table storage'
    url: helpers.getTableStorageEndpoint(storageAccountName)
    protocol: 'http'
    tls: {
      validateCertificateChain: true
      validateCertificateName: true
    }
  }
}
