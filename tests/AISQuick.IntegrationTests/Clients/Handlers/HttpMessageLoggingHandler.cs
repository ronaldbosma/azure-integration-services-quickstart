using System.Text.Json;

namespace AISQuick.IntegrationTests.Clients.Handlers
{
    /// <summary>
    /// Handler to log HTTP request and response message details like the Content, HTTP method, URL, Status Code
    /// </summary>
    /// <remarks>
    /// This handler is used for demo purposes. Be careful adding this in a production scenario.
    /// </remarks>
    internal class HttpMessageLoggingHandler : DelegatingHandler
    {
        /// <summary>
        /// Initializes a new instance of the <see cref="HttpMessageLoggingHandler"/>.
        /// </summary>
        public HttpMessageLoggingHandler()
        {
        }

        /// <summary>
        /// Initializes a new instance of the <see cref="HttpMessageLoggingHandler"/>.
        /// </summary>
        /// <param name="innerHandler">The inner handler to wrap.</param>
        public HttpMessageLoggingHandler(HttpMessageHandler innerHandler) : base(innerHandler)
        {
        }

        protected override async Task<HttpResponseMessage> SendAsync(HttpRequestMessage request, CancellationToken cancellationToken)
        {
            Console.WriteLine($"[Request]: {request.Method} {request.RequestUri}");
            Console.WriteLine(await GetContentAsync(request.Content, cancellationToken));

            var response = await base.SendAsync(request, cancellationToken);

            Console.WriteLine($"[Response]: {(int)response.StatusCode} {response.ReasonPhrase}");
            Console.WriteLine(await GetContentAsync(response.Content, cancellationToken));

            return response;
        }

        private static async Task<string> GetContentAsync(HttpContent? content, CancellationToken cancellationToken)
        {
            if (content is null) return "<null>";

            var contentString = await content.ReadAsStringAsync(cancellationToken);

            if (content.Headers.ContentType?.MediaType?.Contains("application/json") == true)
            {
                try
                {
                    // Return content as formatted JSON
                    var jsonDocument = JsonDocument.Parse(contentString);
                    return JsonSerializer.Serialize(jsonDocument, new JsonSerializerOptions { WriteIndented = true });
                }
                catch (JsonException)
                {
                    return contentString; // If JSON parsing fails, return as string
                }
            }

            return contentString;
        }
    }
}