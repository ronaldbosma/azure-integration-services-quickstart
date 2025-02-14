# Azure Integration Services Quickstart

An `azd` template (Bicep) for quickly deploying Azure Integration Services, including **Azure API Management**, **Function App**, **Logic App**, **Service Bus** and **Event Hubs namespace**, along with supporting resources such as **Application Insights**, **Key Vault** and **Storage Account**. This template is ideal for demos, testing or getting started with Azure Integration Services.

## Overview

This template deploys the following resources:

![Infra](images/aisquick-diagrams-infra.png)

This template is designed to simplify and accelerate the deployment of Azure Integration Services for:

- Demos  
- Testing configurations  
- Quick setups for experimentation  
- CI scenarios in your pipeline  

To minimize cost and reduce deployment time, the cheapest possible SKUs are used for each service. Virtual networks, application gateways and other security measures typically implemented in production scenarios are not included. Keep in mind that some resources may still incur costs, so it's a good idea to clean up when you're finished to avoid unexpected charges.

A sample application is included in the template to demonstrate how the services can be used together. It consists of an API that allows a message to be published to a Service Bus topic. A function and a workflow are triggered by the message. The function stores the message in table storage, while the workflow stores the message in blob storage. Using the API, stored messages can be retrieved. See the following diagram for an overview:

![Infra](images/aisquick-diagrams-app.png)

## Getting Started

If you haven't installed the Azure Developer CLI (`azd`) yet, follow the instructions on [Install or update the Azure Developer CLI](https://learn.microsoft.com/en-us/azure/developer/azure-developer-cli/install-azd).

### Deployment

Once `azd` is installed on your machine, you can deploy this template using the following steps:

1. Run the `azd init` command in an empty directory with the `--template` parameter to clone this template into the current directory.  

    ```cmd
    azd init --template ronaldbosma/azure-integration-services-quickstart
    ```

    When prompted, specify the name of the environment, for example, `aisquick`. The maximum length is 32 characters.

1. Run the `azd auth login` command to authenticate to your Azure subscription _(if you haven't already)_.

    ```cmd
    azd auth login
    ```

1. Run the `azd up` command to provision the resources in your Azure subscription. This will deploy both the infrastructure and the sample application. _(Use `azd provision` to only deploy the infrastructure.)_

    ```cmd
    azd up
    ```

    You'll be prompted to select the Azure Integration Services to include in the deployment. For each service, use the arrow keys to select `True` to include it or `False` to skip it, then press `Enter` to continue.  

    The `includeApplicationInfraResources` parameter specifies whether the application infrastructure resources defined in Bicep should be deployed. These resources are used by the sample application and include the Sample API in API Management, topics and subscriptions in Azure Service Bus, as well as tables and containers in Azure Storage.  

    ![Select resources to include during azd up](images/azd-up-select-resources-to-include.png)

    See [Troubleshooting](#troubleshooting) if you encounter any issues during deployment.

1. Once the deployment is complete, you can locally modify the application or infrastructure and run `azd up` again to update the resources in Azure.

### Clean up

Once you're done and want to clean up, run the `azd down` command. By including the `--purge` parameter, you ensure that the API Management service doesn't remain in a soft-deleted state, which could block future deployments of the same environment.

```cmd
azd down --purge
```

### Changing which resources are deployed

There are a couple of ways to change which Azure Integration Services are deployed and whether the application infrastructure resources should be deployed.

1. Remove your environment folder from the `.azure` folder. After deletion, use `azd init` to reinitialize the environment (with the same name). You'll be prompted again to select which services to deploy when running `azd up` or `azd provision`.

1. If the environment is currently deployed, locate the file `.azure/<environment-name>/.env` and change the values of the `INCLUDE_*` variables to `true` or `false`.

   For example, to deploy API Management and the Function App, but not the Logic App, Service Bus and Event Hubs namespace, use the following settings:

   ```
   ...TRUNCATED...
   INCLUDE_API_MANAGEMENT="true"
   INCLUDE_APPLICATION_INFRA_RESOURCES="false"
   INCLUDE_EVENT_HUBS_NAMESPACE="false"
   INCLUDE_FUNCTION_APP="true"
   INCLUDE_LOGIC_APP="false"
   INCLUDE_SERVICE_BUS="false"
   ```

1. If the environment has been taken down, most variables in the `.env` file are removed. Instead, locate the `.azure/<environment-name>/config.json` file and change the values of the parameters to `true` or `false`.

   For example, to deploy API Management and the Function App, but not the Logic App, Service Bus and Event Hubs namespace, use the following settings:

   ```json
   {
     "infra": {
       "parameters": {
         "includeApiManagement": true,
         "includeApplicationInfraResources": false,
         "includeEventHubsNamespace": false,
         "includeFunctionApp": true,
         "includeLogicApp": false,
         "includeServiceBus": false
       }
     }
   }
   ```

   The environment variables take precedence over the parameters in the `config.json` file. If both are present, the environment variables will be used.

When disabling an already deployed service, it will not be removed when running `azd up` or `azd provision` again. You will need to manually remove the resources from the Azure portal or use `azd down` to remove the entire environment.


## Template Breakdown

As mentioned in the [Overview](#overview) section, this template deploys a set of Azure Integration Services along with supporting resources. The following sections provide a detailed description of the resources that are deployed and how they are connected.

### Infrastructure

#### API Management

When the `includeApiManagement` parameter or the corresponding `INCLUDE_API_MANAGEMENT` environment variable is set to `true`, a Consumption tier API Management service is deployed via the [api-management.bicep](./infra/modules/services/api-management.bicep) module:

- The system-assigned managed identity is enabled to provide access to other services. See the [Role Assignments](#role-assignments) section for more information.
- The primary key of the default `master` subscription is stored in a Key Vault secret called `apim-master-subscription-key`. This key can be used, for example, by the Function App to access APIs hosted on API Management.
- The deployment also includes backends for the Service Bus (\*), various Storage Account endpoints and the Event Hubs namespace (\*).  
  _Note: The `*` indicates that the backend is only deployed if the corresponding service is included._


#### Function App

When the `includeFunctionApp` parameter or the corresponding `INCLUDE_FUNCTION_APP` environment variable is set to `true`, a Function App is deployed via the [function-app.bicep](./infra/modules/services/function-app.bicep) module:

- The `Y1` (Consumption) pricing tier is used. 
- The worker runtime is configured to .NET 8 isolated. 
- The system-assigned managed identity is enabled to provide access to other services. See the [Role Assignments](#role-assignments) section for more information.

The following app settings (environment variables) are configured to facilitate connections to other services.

| Name                                              | Description                                                                                                                |
|---------------------------------------------------|----------------------------------------------------------------------------------------------------------------------------|
| `ApiManagement_gatewayUrl` *                      | The base URL for API Management. For example: `https://apim-aisquick-sdc-5spzh.azure-api.net`.                             |
| `ApiManagement_subscriptionKey` *                 | A Key Vault reference to the subscription key of the default `master` subscription in API Management.                      |
| `StorageAccountConnection__blobServiceUri`        | The Blob Storage endpoint. For example: `https://staisquicksdc5spzh.blob.core.windows.net`.                                |
| `StorageAccountConnection__fileServiceUri`        | The File Storage endpoint. For example: `https://staisquicksdc5spzh.file.core.windows.net`.                                |
| `StorageAccountConnection__queueServiceUri`       | The Queue Storage endpoint. For example: `https://staisquicksdc5spzh.queue.core.windows.net`.                              |
| `StorageAccountConnection__tableServiceUri`       | The Table Storage endpoint. For example: `https://staisquicksdc5spzh.table.core.windows.net`.                              |
| `EventHubConnection__fullyQualifiedNamespace` *   | The fully qualified namespace of the Event Hubs namespace. For example: `evhns-aisquick-sdc-5spzh.servicebus.windows.net`. |
| `ServiceBusConnection__fullyQualifiedNamespace` * | The fully qualified namespace of the Service Bus. For example: `sbns-aisquick-sdc-5spzh.servicebus.windows.net`.           |

_Note: The `*` indicates that the setting is only deployed if the corresponding service is included._

The `StorageAccountConnection`, `EventHubConnection` or `ServiceBusConnection` connection name can be used in triggers and bindings of a function. See [SampleFunction.cs](./src/functionApp/SampleFunction.cs) for an example.

#### Logic App

When the `includeLogicApp` parameter or the corresponding `INCLUDE_LOGIC_APP` environment variable is set to `true`, a Standard single-tenant Logic App is deployed via the [logic-app.bicep](./infra/modules/services/logic-app.bicep) module:

- The `WS1` (Workflow Standard) pricing tier is used. 
- The worker runtime is configured to .NET 8 to enable the use of [custom .NET code](https://learn.microsoft.com/en-us/azure/logic-apps/create-run-custom-code-functions). 
- The system-assigned managed identity is enabled and provides access to other services. See the [Role Assignments](#role-assignments) section for more information.

The following app settings (environment variables) are configured to facilitate connections to other services. These are used in the [connections.json](./src/logicApp/connections.json) file of the sample application.

| Name                                   | Description                                                                                                                |
|----------------------------------------|----------------------------------------------------------------------------------------------------------------------------|
| `ApiManagement_gatewayUrl` *           | The base URL for API Management. For example: `https://apim-aisquick-sdc-5spzh.azure-api.net`.                             |
| `ApiManagement_subscriptionKey` *      | A Key Vault reference to the subscription key of the default `master` subscription in API Management.                      |
| `AzureBlob_blobStorageEndpoint`        | The Blob Storage endpoint. For example: `https://staisquicksdc5spzh.blob.core.windows.net`.                                |
| `AzureFile_storageAccountUri`          | The File Storage endpoint. For example: `https://staisquicksdc5spzh.file.core.windows.net`.                                |
| `AzureQueues_queueServiceUri`          | The Queue Storage endpoint. For example: `https://staisquicksdc5spzh.queue.core.windows.net`.                              |
| `AzureTables_tableStorageEndpoint`     | The Table Storage endpoint. For example: `https://staisquicksdc5spzh.table.core.windows.net`.                              |
| `EventHub_fullyQualifiedNamespace` *   | The fully qualified namespace of the Event Hubs namespace. For example: `evhns-aisquick-sdc-5spzh.servicebus.windows.net`. |
| `ServiceBus_fullyQualifiedNamespace` * | The fully qualified namespace of the Service Bus. For example: `sbns-aisquick-sdc-5spzh.servicebus.windows.net`.           |

_Note: The `*` indicates that the setting is only deployed if the corresponding service is included._

#### Service Bus

When the `includeServiceBus` parameter or the corresponding `INCLUDE_SERVICE_BUS` environment variable is set to `true`, a Standard tier Service Bus is deployed via the [service-bus.bicep](./infra/modules/services/service-bus.bicep) module. The Standard tier enables features such as topics and subscriptions, which are used by the sample application.

#### Event Hubs namespace

When the `includeEventHubsNamespace` parameter or the corresponding `INCLUDE_EVENT_HUBS_NAMESPACE` environment variable is set to `true`, a Standard tier Event Hubs namespace is deployed via the [event-hubs-namespace.bicep](./infra/modules/services/event-hubs-namespace.bicep) module. The Standard tier supports multiple consumer groups per hub, enabling publish-subscribe scenarios.

#### Role Assignments

The [assign-roles-to-principal.bicep](./infra/modules/shared/assign-roles-to-principal.bicep) module is used to assign roles to the principal of the deployer and to the system-assigned managed identity of API Management, the Function App and Logic App. These role assignments are:

- Event Hubs namespace roles:
  - Azure Event Hubs Data Receiver
  - Azure Event Hubs Data Sender
- Key Vault roles:
  - Key Vault Administrator _(this role is only assigned to the principal of the deployer)_
  - Key Vault Secrets User _(this role is assigned to the managed identities)_
- Service Bus roles:
  - Azure Service Bus Data Receiver
  - Azure Service Bus Data Sender
- Storage Account roles:
  - Storage Blob Data Contributor
  - Storage File Data Privileged Contributor _(this role is only assigned to the principal of the deployer)_
  - Storage File Data SMB Share Contributor _(this role is assigned to the managed identities)_
  - Storage Queue Data Contributor
  - Storage Table Data Contributor

These roles are assigned to the principals based on the resources that are included in the deployment.

#### Supporting Resources  

In addition to the Azure Integration Services, the template deploys several supporting resources to enhance functionality and monitoring:  

- Application Insights: Provides monitoring, logging and diagnostics.  
- Key Vault: Securely stores secrets and keys, such as API Management subscription keys.  
- Storage Account: Used to deploy Logic App and Function App code and stores data for the sample application.  


### Application

#### Infrastructure

When the `includeApplicationInfraResources` parameter or the corresponding `INCLUDE_APPLICATION_INFRA_RESOURCES` environment variable is set to `true`, the sample application's infrastructure resources are deployed. These resources are defined in the [application.bicep](./infra/modules/application/application.bicep) module:

- An API is deployed in API Management. It allows messages to be published to a Service Bus topic and retrieves data stored in the Storage Account.  
- A topic and subscriptions are created in the Service Bus namespace. Messages published to the topic trigger the Function App and Logic App.
- A storage table and blob container are created in the Storage Account. These are used by the Function App and Logic App to store messages.  

Although these resources are part of the application, they are deployed as part of the infrastructure using `azd up` or `azd provision`. This is necessary because the Azure Developer CLI does not support deploying Bicep resources as part of the application with `azd deploy`.

#### Azure Function  

The [functionApp](./src/functionApp) directory contains the code for the Azure Function deployed to the Function App. The function is triggered by messages sent to the Service Bus topic and stores the message in a table within the Storage Account.  

#### Logic App Workflow  

The [logicApp](./src/logicApp) directory contains the Logic App workflow. The workflow is triggered by messages sent to the Service Bus topic and stores the message in a blob container within the Storage Account.  

The sample [connections.json](./src/logicApp/connections.json) file includes connections to the various Storage Account services, the Service Bus and the Event Hubs namespace.  


## Naming Convention

All resources are deployed using a naming convention based on the [Azure Resource Naming Best Practices](https://learn.microsoft.com/en-us/azure/cloud-adoption-framework/ready/azure-best-practices/resource-naming). The naming convention is implemented using (a variation of) the Bicep user-defined functions that I blogged about in [Apply Azure naming convention using Bicep functions](https://ronaldbosma.github.io/blog/2024/06/05/apply-azure-naming-convention-using-bicep-functions/).

The following image displays an example of the resources that are deployed with this template:

![](images/deployed-resources.png)


## Troubleshooting

### API Management deployment failed because the service already exists in soft-deleted state

If you've previously deployed this template and deleted the resources, you may encounter the following error when redeploying the template. This error occurs because the API Management service is in a soft-deleted state and needs to be purged before you can create a new service with the same name.

```json
{
    "code": "DeploymentFailed",
    "target": "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-aisquick-dev-nwe-00001/providers/Microsoft.Resources/deployments/apiManagement",
    "message": "At least one resource deployment operation failed. Please list deployment operations for details. Please see https://aka.ms/arm-deployment-operations for usage details.",
    "details": [
        {
            "code": "ServiceAlreadyExistsInSoftDeletedState",
            "message": "Api service apim-aisquick-sdc-5spzh was soft-deleted. In order to create the new service with the same name, you have to either undelete the service or purge it. See https://aka.ms/apimsoftdelete."
        }
    ]
}
```

Use the [az apim deletedservice list](https://learn.microsoft.com/en-us/cli/azure/apim/deletedservice?view=azure-cli-latest#az-apim-deletedservice-list) Azure CLI command to list all deleted API Management services in your subscription. Locate the service that is in a soft-deleted state and purge it using the [purge](https://learn.microsoft.com/en-us/cli/azure/apim/deletedservice?view=azure-cli-latest#az-apim-deletedservice-purge) command. See the following example:

```cmd
az apim deletedservice purge --location "swedencentral" --service-name "apim-aisquick-sdc-5spzh"
```

### Function App deployment failed because of quota limitations

If you already have a Consumption tier (`SKU=Y1`) Function App deployed in the same region, you may encounter the following error when deploying the template. This error occurs because you have reached the region's quota for your subscription.

```json
{
  "code": "InvalidTemplateDeployment",
  "message": "The template deployment 'functionApp' is not valid according to the validation procedure. The tracking id is '00000000-0000-0000-0000-000000000000'. See inner errors for details.",
  "details": [
    {
      "code": "ValidationForResourceFailed",
      "message": "Validation failed for a resource. Check 'Error.Details[0]' for more information.",
      "details": [
        {
          "code": "SubscriptionIsOverQuotaForSku",
          "message": "This region has quota of 1 instances for your subscription. Try selecting different region or SKU."
        }
      ]
    }
  ]
}
```

Use the `azd down --purge` command to delete the resources, then deploy the template in a different region.

### Logic App deployment failed because of quota limitations

If you already have a Workflow Standard WS1 tier (`SKU=WS1`) Logic App deployed in the same region, you may encounter the following error when deploying the template. This error occurs because you have reached the region's quota for your subscription.

```json
{
  "code": "InvalidTemplateDeployment",
  "message": "The template deployment 'logicApp' is not valid according to the validation procedure. The tracking id is '00000000-0000-0000-0000-000000000000'. See inner errors for details.",
  "details": [
    {
      "code": "ValidationForResourceFailed",
      "message": "Validation failed for a resource. Check 'Error.Details[0]' for more information.",
      "details": [
        {
          "code": "SubscriptionIsOverQuotaForSku",
          "message": "This region has quota of 1 instances for your subscription. Try selecting different region or SKU."
        }
      ]
    }
  ]
}
```

Use the `azd down --purge` command to delete the resources, then deploy the template in a different region.
