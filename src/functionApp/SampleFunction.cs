using AISQuick.FunctionApp.Models;

using Microsoft.Azure.Functions.Worker;
using Microsoft.Extensions.Logging;

namespace AISQuick.FunctionApp;

/// <summary>
/// Sample function that triggers on a Service Bus message and writes the message to a table.
/// </summary>
public class SampleFunction
{
    private readonly ILogger<SampleFunction> _logger;

    public SampleFunction(ILogger<SampleFunction> logger)
    {
        _logger = logger;
    }

    [Function(nameof(SampleFunction))]
    [TableOutput("aisquickSample", Connection = "StorageAccountConnection")]
    public SampleTableEntity Run(
        [ServiceBusTrigger("aisquick-sample", "function-app", Connection = "ServiceBusConnection", AutoCompleteMessages = true)]
        SampleMessage sampleMessage
    )
    {
        _logger.LogInformation("Received message '{message}' with ID {id}", sampleMessage.Message, sampleMessage.Id);

        return new SampleTableEntity(sampleMessage);
    }
}