using AISQuick.IntegrationTests.Models;
using Azure.Identity;
using Azure.Security.KeyVault.Secrets;
using Polly;
using System.Net.Http.Json;

namespace AISQuick.IntegrationTests;

public sealed class ApimClient : IDisposable
{
    private readonly HttpClient _httpClient;
    private readonly IAsyncPolicy<HttpResponseMessage> _retryPolicy;

    private ApimClient(HttpClient httpClient)
    {
        _httpClient = httpClient;
        _retryPolicy = CreateRetryPolicy();
    }

    public static async Task<ApimClient> CreateAsync(AzureEnvConfiguration configuration)
    {
        if (configuration == null)
            throw new ArgumentNullException(nameof(configuration));

        // Get subscription key from Key Vault
        var subscriptionKey = await GetSubscriptionKeyFromKeyVaultAsync(configuration);
        
        // Set up HttpClient with default headers
        var httpClient = new HttpClient();
        httpClient.DefaultRequestHeaders.Add("Ocp-Apim-Subscription-Key", subscriptionKey);
        httpClient.DefaultRequestHeaders.Add("Ocp-Apim-Trace", "true");
        httpClient.BaseAddress = new Uri($"https://{configuration.AzureApiManagementName}.azure-api.net");

        return new ApimClient(httpClient);
    }

    public async Task<PublishMessageResponse> PublishMessageAsync(PublishMessageRequest request)
    {
        var response = await _httpClient.PostAsJsonAsync("/aisquick-sample/messages", request);
        response.EnsureSuccessStatusCode();
        
        var result = await response.Content.ReadFromJsonAsync<PublishMessageResponse>();
        return result ?? throw new InvalidOperationException("Failed to deserialize publish message response");
    }

    public async Task<TableEntityResponse> GetTableEntityAsync(string messageId)
    {
        using var cts = new CancellationTokenSource(TimeSpan.FromSeconds(60));
        
        var response = await _retryPolicy.ExecuteAsync(async () =>
        {
            var httpResponse = await _httpClient.GetAsync($"/aisquick-sample/table-entities/{messageId}", cts.Token);
            return httpResponse;
        });
        
        response.EnsureSuccessStatusCode();
        
        var result = await response.Content.ReadFromJsonAsync<TableEntityResponse>();
        return result ?? throw new InvalidOperationException("Failed to deserialize table entity response");
    }

    public async Task<BlobResponse> GetBlobAsync(string messageId)
    {
        using var cts = new CancellationTokenSource(TimeSpan.FromSeconds(60));
        
        var response = await _retryPolicy.ExecuteAsync(async () =>
        {
            var httpResponse = await _httpClient.GetAsync($"/aisquick-sample/blobs/{messageId}", cts.Token);
            return httpResponse;
        });
        
        response.EnsureSuccessStatusCode();
        
        var result = await response.Content.ReadFromJsonAsync<BlobResponse>();
        return result ?? throw new InvalidOperationException("Failed to deserialize blob response");
    }

    private static IAsyncPolicy<HttpResponseMessage> CreateRetryPolicy()
    {
        return Policy
            .Handle<HttpRequestException>()
            .Or<TaskCanceledException>()
            .OrResult<HttpResponseMessage>(r => !r.IsSuccessStatusCode)
            .WaitAndRetryAsync(
                retryCount: 10,
                sleepDurationProvider: retryAttempt => TimeSpan.FromSeconds(Math.Pow(2, retryAttempt)),
                onRetry: (outcome, timespan, retryCount, context) =>
                {
                    var methodName = context.ContainsKey("MethodName") ? context["MethodName"] : "Unknown";
                    Console.WriteLine($"Retry {retryCount} for {methodName} after {timespan} seconds");
                });
    }

    private static async Task<string> GetSubscriptionKeyFromKeyVaultAsync(AzureEnvConfiguration config)
    {
        var keyVaultUri = new Uri($"https://{config.AzureKeyVaultName}.vault.azure.net/");
        var client = new SecretClient(keyVaultUri, new DefaultAzureCredential());
        var secret = await client.GetSecretAsync(config.ApimSubscriptionKeySecretName);
        return secret.Value.Value;
    }

    public void Dispose()
    {
        _httpClient?.Dispose();
    }
}