using Azure.Data.Tables;
using Azure.Identity;
using Azure.Monitor.OpenTelemetry.Exporter;

using Microsoft.Azure.Functions.Worker.Builder;
using Microsoft.Azure.Functions.Worker.OpenTelemetry;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;

using OpenTelemetry.Trace;

var builder = FunctionsApplication.CreateBuilder(args);

builder.ConfigureFunctionsWebApplication();

builder.Logging.AddOpenTelemetry(logging =>
{
    logging.IncludeFormattedMessage = true;
    logging.IncludeScopes = true;
});

builder.Services.AddOpenTelemetry()
    // Enable HttpClient instrumentation.
    .WithTracing(tracing => tracing.AddHttpClientInstrumentation());

builder.Services.AddOpenTelemetry().UseAzureMonitorExporter(options =>
{
    // Set the Azure Monitor credential to the DefaultAzureCredential.
    // This credential will use the Azure identity of the current user or
    // the service principal that the application is running as to authenticate
    // to Azure Monitor.
    // Use a more specific credential in production scenarios. For best practices, see
    // https://learn.microsoft.com/en-us/dotnet/azure/sdk/authentication/best-practices?tabs=aspdotnet
    options.Credential = new DefaultAzureCredential();
});

builder.Services.AddOpenTelemetry().UseFunctionsWorkerDefaults();

var tableServiceUri = builder.Configuration["StorageAccountConnection:tableServiceUri"]
    ?? throw new InvalidOperationException("Configuration setting 'StorageAccountConnection:tableServiceUri' is missing.");
builder.Services.AddSingleton(new TableServiceClient(new Uri(tableServiceUri), new DefaultAzureCredential()));

builder.Build().Run();