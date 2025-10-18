using AISQuick.IntegrationTests.Models;
using Azure.Identity;
using Azure.Security.KeyVault.Secrets;
using Polly;
using System.Diagnostics;
using System.Net.Http.Json;

namespace AISQuick.IntegrationTests;

/// <summary>
/// Provides a client for interacting with Azure API Management (APIM).
/// </summary>
/// <remarks>
/// This client is designed to simplify communication with Azure API Management by handling common tasks
/// such as authentication, retry policies, and HTTP request/response handling. Use <see cref="CreateAsync"/> to
/// instantiate the client with the necessary configuration.
/// </remarks>
public sealed class ApimClient : IDisposable
{
    private readonly HttpClient _httpClient;
    private readonly IAsyncPolicy<HttpResponseMessage> _retryPolicy;

    private ApimClient(HttpClient httpClient)
    {
        _httpClient = httpClient;
        _retryPolicy = CreateRetryPolicy();
    }

    /// <summary>
    /// Creates a new instance of the <see cref="ApimClient"/> class configured to interact with an Azure API Management
    /// instance.
    /// </summary>
    /// <remarks>This method retrieves the subscription key from Azure Key Vault and configures an <see cref="HttpClient"/> 
    /// with the necessary headers and base address for interacting with the specified Azure API Management instance.</remarks>
    /// <param name="configuration">
    /// The configuration settings for the Azure environment, including the API Management instance name and other required details.
    /// </param>
    /// <returns>A task that represents the asynchronous operation. The task result contains an <see cref="ApimClient"/> instance
    /// configured with the appropriate subscription key and base address.</returns>
    /// <exception cref="ArgumentNullException">Thrown if <paramref name="configuration"/> is <see langword="null"/>.</exception>
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

    /// <summary>
    /// Creates an asynchronous retry policy for HTTP requests with exponential backoff that can be used to poll for results.
    /// </summary>
    private static IAsyncPolicy<HttpResponseMessage> CreateRetryPolicy()
    {
        return Policy
            .Handle<HttpRequestException>()
            .Or<TaskCanceledException>()
            .OrResult<HttpResponseMessage>(r => !r.IsSuccessStatusCode)
            .WaitAndRetryAsync(
                retryCount: 50,
                sleepDurationProvider: retryAttempt => TimeSpan.FromSeconds(1),
                onRetry: (outcome, timespan, retryCount, context) =>
                {
                    Trace.WriteLine($"Retry {retryCount} after {timespan} seconds. Reason: {outcome.Result.ReasonPhrase}");
                });
    }

    /// <summary>
    /// Retrieve the API Management subscription key from Azure Key Vault.
    /// </summary>
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