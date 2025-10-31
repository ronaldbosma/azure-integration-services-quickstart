# Azure Integration Services Quickstart - Demo Sample Application

In this demo scenario, we will demonstrate the sample application that is deployed as part of the template. The application consists of an API Management API that allows a message to be published to a Service Bus topic. An Azure Function and a Logic App workflow are triggered by the message. The function stores the message in table storage, while the workflow stores the message in blob storage. Using the API, stored messages can be retrieved. See the following diagram for an overview:

![Infra](https://raw.githubusercontent.com/ronaldbosma/azure-integration-services-quickstart/refs/heads/main/images/aisquick-diagrams-app.png)

## 1. What resources are getting deployed

For this scenario, you'll need to deploy all optional resources except for the Event Hubs namespace. The following resources will be deployed:

![Deployed Resources](https://raw.githubusercontent.com/ronaldbosma/azure-integration-services-quickstart/refs/heads/main/images/deployed-resources.png)

See the [Naming Convention](https://github.com/ronaldbosma/azure-integration-services-quickstart/blob/main/README.md#naming-convention) section in the readme for more information on the naming convention.


## 2. What can I demo from this scenario after deployment

### Test the sample application

You can test the sample application in two ways:

- **Manual Testing:** Use Visual Studio Code with the REST Client extension and the provided `tests.http` file to send requests and verify responses.
- **Automated Integration Tests:** Run the .NET-based integration tests included in the repository to validate the application's functionality automatically.

Note that you'll need to deploy the application infrastructure, API Management and Service Bus, and include the Function and/or Logic App.

#### Manual testing using Visual Studio Code

To manually test the sample application, you can use the provided HTTP requests in the [tests.http](https://github.com/ronaldbosma/azure-integration-services-quickstart/blob/main/tests/tests.http) file. 
This file contains requests to publish a message to the Service Bus topic and to retrieve the stored messages from blob and table storage.

Follow these steps to test the sample application using Visual Studio Code:

1. Install the [REST Client](https://marketplace.visualstudio.com/items?itemName=humao.rest-client) extension in Visual Studio Code. 
1. The API is protected and needs to be called with a subscription key. Either:
   - Locate the `Built-in all-access` subscription in API Management and copy the primary key,
   - Or locate the `apim-master-subscription-key` secret in Key Vault and copy the secret value.
1. Add an environment to your Visual Studio Code user settings with the API Management hostname and subscription key. Use the following example and replace the values with your own:
   ```
   "rest-client.environmentVariables": {
       "aisquick": {
           "apimHostname": "apim-aisquick-sdc-5spzh.azure-api.net",
           "apimSubscriptionKey": "1234567890abcdefghijklmnopqrstuv"
       }
   }
   ```
1. Open `tests.http` and at the bottom right of the editor, select the `aisquick` environment you just configured.
1. Click on `Send Request` above the first request. This will send a message to the Service Bus topic.
1. Click on `Send Request` above the second request to retrieve the message from the storage table. A `404 Not Found` response might be returned if the message hasn't been processed yet or if you haven't deployed the Azure Function.
1. Click on `Send Request` above the third request to retrieve the message from the blob container. A `404 Not Found` response might be returned if the message hasn't been processed yet or if you haven't deployed the Logic App workflow.

#### Automated testing using .NET integration tests

The repository includes a set of .NET-based integration tests that can be used to automatically validate the functionality of the sample application. 

The main test in [AISQuickSampleTests.cs](https://github.com/ronaldbosma/azure-integration-services-quickstart/blob/main/tests/AISQuick.IntegrationTests/AISQuickSampleTests.cs) performs the following actions:
1. Retrieves the API Management subscription key from Key Vault using your Azure CLI or Azure Developer CLI credentials.
1. Sends a request to the API Management API that publishes a message to the Service Bus topic
1. Validates that the Azure Function processes the message and stores it in table storage (if Function App is deployed)
1. Confirms that the Logic App workflow processes the message and stores it in blob storage (if Logic App is deployed)

The tests automatically adapt based on which components are deployed in your environment, using configuration flags to determine whether to validate Function App or Logic App functionality.

**Prerequisites:** The tests use your local azd environment variables to connect to the deployed resources. Ensure that your azd environment is set to the correct deployment before running the tests.

To run the integration tests from the command line, follow these steps:
1. Ensure you have the [.NET SDK](https://dotnet.microsoft.com/en-us/download) installed on your machine.
1. Open a terminal and navigate to the `tests/AISQuick.IntegrationTests` folder in the repository.
1. Run the following command to execute the tests:

   ```
   dotnet run
   ```

When executing the tests from an IDE like Visual Studio, you can also view the request and response details in the test output window. 


### Review deployed resources

#### API Management

Show the deployed API and its operations.

1. Navigate to the API Management instance in the Azure portal.  
1. Click the `APIs` tab.  
1. Select the `AISQuick Sample` API.  
1. Review the operations:  
    1. `POST Publish Message`: Publishes a message to the Service Bus topic and returns an ID. This ID can be used in subsequent operations to retrieve the message from storage.  
    1. `GET Blob`: Retrieves a message from blob storage.  
    1. `GET Table Entity`: Retrieves a message from table storage.  

#### Key Vault  

Show the secrets stored in Key Vault.  

1. Navigate to the Key Vault in the Azure portal.  
1. Click the `Secrets` tab.  
1. Verify that a secret has been created for the API Management master subscription key.  

#### Service Bus  

Show the Service Bus topic and its subscriptions.  

1. Navigate to the Service Bus namespace in the Azure portal.  
1. Click the `Topics` tab and open the `aisquick-sample` topic.  
1. View the traffic that has passed through the topic in the overview.  
1. Click the `Subscriptions` tab to see the subscriptions created for the Function App and Logic App.  

#### Logic App  

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

#### Azure Function  

Show the source code.  

1. Open [SampleFunction.cs](https://github.com/ronaldbosma/azure-integration-services-quickstart/blob/main/src/functionApp/SampleFunction.cs).  
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

#### Storage Account  

Show the messages stored in blob and table storage.  

1. Navigate to the Storage Account in the Azure portal.  
1. Click the `Storage browser` tab.  
1. Select `Blob containers` and then `aisquick-sample`.  
1. Show the messages stored in blob storage.  
1. Select `Tables` and then `aisquickSample`.  
1. Show the messages stored in table storage.  
