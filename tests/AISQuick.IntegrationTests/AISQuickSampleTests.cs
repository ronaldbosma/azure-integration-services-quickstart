using System.Net.Http.Json;
using System.Text.Json;
using Azure.Identity;
using Azure.Security.KeyVault.Secrets;

namespace AISQuick.IntegrationTests
{
    [TestClass]
    public sealed class AISQuickSampleTests
    {
        private HttpClient? _httpClient;
        private TestConfiguration? _configuration;

        [TestInitialize]
        public async Task TestInitialize()
        {
            // Load configuration directly from environment variables
            _configuration = TestConfiguration.FromEnvironment();

            // Get subscription key from Key Vault
            var subscriptionKey = await GetSubscriptionKeyFromKeyVaultAsync(_configuration);

            // Set up HttpClient with default headers
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
            var message = new { message = "Hello, world!" };

            // 1. Publish a message to the aisquick-sample topic
            var publishResponse = await PublishMessageAsync(message);
            publishResponse.EnsureSuccessStatusCode();

            var publishResponseContent = await publishResponse.Content.ReadAsStringAsync();
            var publishResult = JsonDocument.Parse(publishResponseContent);
            var messageId = publishResult.RootElement.GetProperty("id").GetString()!;

            // 4a. Get the table entity (if Function App is included)
            if (_configuration!.IncludeFunctionApp)
            {
                await Task.Delay(2000); // Allow time for processing
                var tableResponse = await GetTableEntityAsync(messageId);
                tableResponse.EnsureSuccessStatusCode();
            }

            // 4b. Get the blob (if Logic App is included)
            if (_configuration.IncludeLogicApp)
            {
                await Task.Delay(2000); // Allow time for processing
                var blobResponse = await GetBlobAsync(messageId);
                blobResponse.EnsureSuccessStatusCode();
            }
        }

        private async Task<HttpResponseMessage> PublishMessageAsync(object message)
        {
            return await _httpClient!.PostAsJsonAsync("/aisquick-sample/messages", message);
        }

        private async Task<HttpResponseMessage> GetTableEntityAsync(string id)
        {
            return await _httpClient!.GetAsync($"/aisquick-sample/table-entities/{id}");
        }

        private async Task<HttpResponseMessage> GetBlobAsync(string id)
        {
            return await _httpClient!.GetAsync($"/aisquick-sample/blobs/{id}");
        }

        private static async Task<string> GetSubscriptionKeyFromKeyVaultAsync(TestConfiguration config)
        {
            var keyVaultUri = new Uri($"https://{config.AzureKeyVaultName}.vault.azure.net/");
            var client = new SecretClient(keyVaultUri, new DefaultAzureCredential());
            var secret = await client.GetSecretAsync(config.ApimSubscriptionKeySecretName);
            return secret.Value.Value;
        }
    }
}
