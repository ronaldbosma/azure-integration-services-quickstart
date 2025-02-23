# Azure Integration Services Quickstart - Demo Scenario

In this demo scenario, we will demonstrate how to use Azure Integration Services to build a simple application that uses API Management, Azure Functions, Logic Apps and Service Bus. The application consists of an API that allows a message to be published to a Service Bus topic. A function and a workflow are triggered by the message. The function stores the message in table storage, while the workflow stores the message in blob storage. Using the API, stored messages can be retrieved. See the following diagram for an overview:

![Infra](../images/aisquick-diagrams-app.png)

## 1. What resources are getting deployed

For this scenario, you'll need to deploy all optional resources except for the Event Hubs namespace. The following resources will be deployed:

![Deployed Resources](../images/deployed-resources.png)

See the [Naming Convention](../readme.md#naming-convention) section in the readme for more information on the naming convention.


## 2. What can I demo from this scenario after deployment

### Publish messages

Follow the [Test](../README.md#test) section in the README to publish a few messages to the Service Bus topic.


### API Management

Show the deployed API and its operations.

1. Navigate to the API Management instance in the Azure portal.  
1. Click the `APIs` tab.  
1. Select the `AISQuick Sample` API.  
1. Review the operations:  
    1. `POST Publish Message`: Publishes a message to the Service Bus topic and returns an ID. This ID can be used in subsequent operations to retrieve the message from storage.  
    1. `GET Blob`: Retrieves a message from blob storage.  
    1. `GET Table Entity`: Retrieves a message from table storage.  


### Key Vault  

Show the secrets stored in Key Vault.  

1. Navigate to the Key Vault in the Azure portal.  
1. Click the `Secrets` tab.  
1. Verify that a secret has been created for the API Management master subscription key.  


### Service Bus  

Show the Service Bus topic and its subscriptions.  

1. Navigate to the Service Bus namespace in the Azure portal.  
1. Click the `Topics` tab and open the `aisquick-sample` topic.  
1. View the traffic that has passed through the topic in the overview.  
1. Click the `Subscriptions` tab to see the subscriptions created for the Function App and Logic App.  


### Logic App  

Show the Logic App and deployed workflow.

1. Navigate to the Logic App in the Azure portal.  
1. Click the `Workflows` tab.  
1. Select the `aisquick-sample-workflow` workflow.  
1. Review the workflow in the designer:  
    1. The workflow is triggered by a Service Bus message.  
    1. The message is parsed to extract the ID.  
    1. The message is stored in blob storage with the ID in the file name.  
1. Click the `Run history` tab and review the executed runs.  
1. Go back to the Logic App.  
1. Click the `Connections` tab.  
1. Open the `Service Provider Connections` tab and review the deployed connections.  
1. Click the `Parameters` tab and review the available parameters.  
1. Click the `Environment variables` tab.  
1. Show that the `ApiManagement_subscriptionKey` variable uses a key vault reference.  
1. Show the different variables used by the connections.  


### Azure Function  

Show the source code.  

1. Open [SampleFunction.cs](../src/functionApp/SampleFunction.cs).  
1. Show the `ServiceBusTrigger` attribute, which is configured with the Service Bus topic and subscription, and uses the `ServiceBusConnection` connection.  
1. Show the `TableOutput` output binding, which uses the `StorageAccountConnection` connection to store the return value in table storage.  

Show the deployed function.  

1. Navigate to the Function App in the Azure portal.  
1. Click `SampleFunction` in the Functions tab on the Overview screen.
1. Open the `Invocations` tab.  
1. Show the function invocations that have occurred. It might take a few minutes for the first invocation to appear.  
   **NOTE**: If you've deployed and removed the same environment multiple times, you might see older invocation history from previous deployments.  
1. Go back to the Function App.  
1. Click the `Environment variables` tab.  
1. Show that the `ApiManagement_subscriptionKey` variable uses a key vault reference.  
1. Show the different `Connection` variables that can be used by triggers and bindings within the function.


### Storage Account  

Show the messages stored in blob and table storage.  

1. Navigate to the Storage Account in the Azure portal.  
1. Click the `Storage browser` tab.  
1. Select `Blob containers` and then `aisquick-sample`.  
1. Show the messages stored in blob storage.  
1. Select `Tables` and then `aisquickSample`.  
1. Show the messages stored in table storage.  
