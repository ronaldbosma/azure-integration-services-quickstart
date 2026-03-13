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
    .WithTracing(tracing =>
    {
        tracing
            // Enables HttpClient instrumentation.
            .AddHttpClientInstrumentation()
            // Enable instrumentation for Azure SDK clients.
            .AddSource("Azure.*");
    });

builder.Services.AddOpenTelemetry().UseAzureMonitorExporter(options =>
{
    // Set the Azure Monitor credential to the DefaultAzureCredential.
    // This credential will use the Azure identity of the current user or
    // the service principal that the application is running as to authenticate
    // to Azure Monitor.
    options.Credential = new DefaultAzureCredential();
});

builder.Services.AddOpenTelemetry().UseFunctionsWorkerDefaults();

builder.Build().Run();