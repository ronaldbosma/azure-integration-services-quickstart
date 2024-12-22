using AISQuick.FunctionApp.Models;
using Microsoft.Azure.Functions.Worker;
using Microsoft.Extensions.Logging;

namespace AISQuick.FunctionApp;

public class SampleFunction
{
    private readonly ILogger<SampleFunction> _logger;

    public SampleFunction(ILogger<SampleFunction> logger)
    {
        _logger = logger;
    }

    [Function(nameof(SampleFunction))]
    [TableOutput("sample", Connection = "StorageAccountConnection")]
    public SampleTableEntity Run(
        [ServiceBusTrigger("sample", "function-app", Connection = "ServiceBusConnection", AutoCompleteMessages = true)]
        SampleMessage sampleMessage
    )
    {
        _logger.LogInformation("Received message '{message}' with ID {id}", sampleMessage.Message, sampleMessage.Id);

        return new SampleTableEntity(sampleMessage.Id, sampleMessage.Message);
    }
}
