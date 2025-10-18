using AISQuick.IntegrationTests.Clients;
using AISQuick.IntegrationTests.Configuration;
using AISQuick.IntegrationTests.Models;

namespace AISQuick.IntegrationTests;

[TestClass]
public sealed class AISQuickSampleTests
{
    [TestMethod]
    public async Task TestSampleApplicationWorkflow()
    {
        // Arrange
        var config = TestConfiguration.Load();

        var keyVaultClient = new KeyVaultClient(config.AzureKeyVaultName);
        var apimSubscriptionKey = await keyVaultClient.GetSecretValueAsync("apim-master-subscription-key");

        using var apiClient = new SampleApiClient(config.AzureApiManagementName, apimSubscriptionKey);

        // Act & Assert

        // 1. Publish a message to the aisquick-sample topic
        var request = new PublishMessageRequest("Hello, world!");
        var publishResult = await apiClient.PublishMessageAsync(request);

        Assert.IsNotNull(publishResult, "Publish response should not be null");
        Assert.IsFalse(string.IsNullOrWhiteSpace(publishResult.Id), "Message ID should not be empty");

        // 4a. Get the table entity (if Function App is included)
        if (config.IncludeFunctionApp)
        {
            var tableEntity = await apiClient.GetTableEntityAsync(publishResult.Id);

            Assert.IsNotNull(tableEntity, "Table entity should not be null");
            Assert.AreEqual("aisquick-sample", tableEntity.PartitionKey, "Table entity should have correct partition key");
            Assert.AreEqual(publishResult.Id, tableEntity.RowKey, "Table entity should have correct row key");
            Assert.AreEqual(request.Message, tableEntity.Message, "Table entity should contain the original message");
            Assert.AreEqual("Service Bus", tableEntity.Via, "Table entity should indicate it came via Service Bus");
        }

        // 4b. Get the blob (if Logic App is included)
        if (config.IncludeLogicApp)
        {
            var blobContent = await apiClient.GetBlobAsync(publishResult.Id);

            Assert.IsNotNull(blobContent, "Blob content should not be null");
            Assert.AreEqual(request.Message, blobContent.Message, "Blob should contain the original message");
            Assert.AreEqual(publishResult.Id, blobContent.Id, "Blob should contain the correct message ID");
            Assert.AreEqual("Service Bus", blobContent.Via, "Blob should indicate it came via Service Bus");
        }
    }
}
