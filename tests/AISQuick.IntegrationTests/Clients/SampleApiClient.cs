using AISQuick.IntegrationTests.Models;
using Polly;
using System.Diagnostics;
using System.Net.Http.Json;

namespace AISQuick.IntegrationTests.Clients;

/// <summary>
/// Provides a client for interacting with the Sample API on Azure API Management (APIM).
/// </summary>
/// <remarks>
/// This client is designed to simplify communication with the Sample API by handling common tasks
/// such as authentication, retry policies, and HTTP request/response handling. Use <see cref="CreateAsync"/> to
/// instantiate the client with the necessary configuration.
/// </remarks>
public class SampleApiClient : IDisposable
{
    private readonly HttpClient _httpClient;
    private readonly IAsyncPolicy<HttpResponseMessage> _retryPolicy;

    public SampleApiClient(string apiManagementName, string subscriptionKey)
    {
        _httpClient = new HttpClient();
        _httpClient.BaseAddress = new Uri($"https://{apiManagementName}.azure-api.net");
        _httpClient.DefaultRequestHeaders.Add("Ocp-Apim-Subscription-Key", subscriptionKey);

        _retryPolicy = CreateRetryPolicy();
    }

    public async Task<PublishMessageResponse> PublishMessageAsync(PublishMessageRequest request)
    {
        Trace.WriteLine("Publish message");

        var response = await _httpClient.PostAsJsonAsync("/aisquick-sample/messages", request);
        response.EnsureSuccessStatusCode();
        
        var result = await response.Content.ReadFromJsonAsync<PublishMessageResponse>();
        return result ?? throw new InvalidOperationException("Failed to deserialize publish message response");
    }

    public async Task<TableEntityResponse> GetTableEntityAsync(string messageId)
    {
        Trace.WriteLine($"Retrieve table entity for message id: {messageId}");

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
        Trace.WriteLine($"Retrieve blob for message id: {messageId}");

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

    public void Dispose()
    {
        _httpClient?.Dispose();
    }
}