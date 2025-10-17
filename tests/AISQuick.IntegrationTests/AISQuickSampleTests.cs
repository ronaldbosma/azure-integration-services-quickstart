using AISQuick.IntegrationTests.Models;
using Azure.Identity;
using Azure.Security.KeyVault.Secrets;
using System.Net.Http.Json;

namespace AISQuick.IntegrationTests
{
    [TestClass]
    public sealed class AISQuickSampleTests
    {
        private HttpClient? _httpClient = null;
        private AzureEnvConfiguration? _configuration;

        [TestInitialize]
        public async Task TestInitialize()
        {
            // Load configuration directly from environment variables
            _configuration = AzureEnvConfiguration.FromEnvironment();

            // Get subscription key from Key Vault
            var subscriptionKey = await GetSubscriptionKeyFromKeyVaultAsync(_configuration);
            
            // Set up HttpClient with retry handler and default headers
            _httpClient = new HttpClient();
            _httpClient.DefaultRequestHeaders.Add("Ocp-Apim-Subscription-Key", subscriptionKey);
            _httpClient.DefaultRequestHeaders.Add("Ocp-Apim-Trace", "true");
            _httpClient.BaseAddress = new Uri($"https://{_configuration.AzureApiManagementName}.azure-api.net");
        }

        [TestCleanup]
        public void TestCleanup()
        {
            _httpClient?.Dispose();
        }

        [TestMethod]
        public async Task TestSampleApplicationWorkflow()
        {
            // Arrange
            var request = new PublishMessageRequest("Hello, world!");

            // 1. Publish a message to the aisquick-sample topic
            var publishResponse = await PublishMessageAsync(request);
            publishResponse.EnsureSuccessStatusCode();

            var publishResult = await publishResponse.Content.ReadFromJsonAsync<PublishMessageResponse>();
            Assert.IsNotNull(publishResult, "Publish response should not be null");
            Assert.IsFalse(string.IsNullOrWhiteSpace(publishResult.Id), "Message ID should not be empty");

            var messageId = publishResult.Id;

            await Task.Delay(10000);


            // 4a. Get the table entity (if Function App is included)
            if (_configuration!.IncludeFunctionApp)
            {
                var tableResponse = await GetTableEntityAsync(messageId);
                tableResponse.EnsureSuccessStatusCode();
                
                var tableEntity = await tableResponse.Content.ReadFromJsonAsync<TableEntityResponse>();
                Assert.IsNotNull(tableEntity, "Table entity should not be null");
                Assert.AreEqual("aisquick-sample", tableEntity.PartitionKey, "Table entity should have correct partition key");
                Assert.AreEqual(messageId, tableEntity.RowKey, "Table entity should have correct row key");
                Assert.AreEqual(request.Message, tableEntity.Message, "Table entity should contain the original message");
                Assert.AreEqual("Service Bus", tableEntity.Via, "Table entity should indicate it came via Service Bus");
            }

            // 4b. Get the blob (if Logic App is included)
            if (_configuration.IncludeLogicApp)
            {
                var blobResponse = await GetBlobAsync(messageId);
                blobResponse.EnsureSuccessStatusCode();
                
                var blobContent = await blobResponse.Content.ReadFromJsonAsync<BlobResponse>();
                Assert.IsNotNull(blobContent, "Blob content should not be null");
                Assert.AreEqual(request.Message, blobContent.Message, "Blob should contain the original message");
                Assert.AreEqual(messageId, blobContent.Id, "Blob should contain the correct message ID");
                Assert.AreEqual("Service Bus", blobContent.Via, "Blob should indicate it came via Service Bus");
            }
        }

        private async Task<HttpResponseMessage> PublishMessageAsync(PublishMessageRequest request)
        {
            return await _httpClient!.PostAsJsonAsync("/aisquick-sample/messages", request);
        }

        private async Task<HttpResponseMessage> GetTableEntityAsync(string id)
        {
            return await _httpClient!.GetAsync($"/aisquick-sample/table-entities/{id}");
        }

        private async Task<HttpResponseMessage> GetBlobAsync(string id)
        {
            return await _httpClient!.GetAsync($"/aisquick-sample/blobs/{id}");
        }

        private static async Task<string> GetSubscriptionKeyFromKeyVaultAsync(AzureEnvConfiguration config)
        {
            var keyVaultUri = new Uri($"https://{config.AzureKeyVaultName}.vault.azure.net/");
            var client = new SecretClient(keyVaultUri, new DefaultAzureCredential());
            var secret = await client.GetSecretAsync(config.ApimSubscriptionKeySecretName);
            return secret.Value.Value;
        }
    }
}
