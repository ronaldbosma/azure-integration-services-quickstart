using AISQuick.FunctionApp.Models;

using Azure.Data.Tables;

using Microsoft.Azure.Functions.Worker;
using Microsoft.Extensions.Logging;

namespace AISQuick.FunctionApp;

/// <summary>
/// Sample function that triggers on a Service Bus message and writes the message to a table.
/// </summary>
public class SampleFunction
{
    private readonly ILogger<SampleFunction> _logger;
    private readonly TableServiceClient _tableServiceClient;

    public SampleFunction(ILogger<SampleFunction> logger, TableServiceClient tableServiceClient)
    {
        _logger = logger;
        _tableServiceClient = tableServiceClient;
    }

    [Function(nameof(SampleFunction))]
    public async Task Run(
        [ServiceBusTrigger("aisquick-sample", "function-app", Connection = "ServiceBusConnection", AutoCompleteMessages = true)]
        SampleMessage sampleMessage
    )
    {
        _logger.LogInformation("Received message '{message}' with ID {id}", sampleMessage.Message, sampleMessage.Id);

        var entity = new SampleTableEntity(sampleMessage);
        var tableClient = _tableServiceClient.GetTableClient("aisquickSample");
        await tableClient.AddEntityAsync(entity);
    }
}