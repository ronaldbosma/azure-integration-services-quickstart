using AISQuick.FunctionApp.Models;
using Microsoft.Azure.Functions.Worker;
using Microsoft.Extensions.Logging;

namespace AISQuick.FunctionApp;

public class ServiceBusSampleFunction
{
    private readonly ILogger<ServiceBusSampleFunction> _logger;

    public ServiceBusSampleFunction(ILogger<ServiceBusSampleFunction> logger)
    {
        _logger = logger;
    }

    [Function(nameof(ServiceBusSampleFunction))]
    [TableOutput("aisquickSample", Connection = "StorageAccountConnection")]
    public SampleTableEntity Run(
        [ServiceBusTrigger("aisquick-sample", "function-app", Connection = "ServiceBusConnection", AutoCompleteMessages = true)]
        SampleMessage sampleMessage
    )
    {
        _logger.LogInformation("Received message '{message}' with ID {id}", sampleMessage.Message, sampleMessage.Id);

        return new SampleTableEntity(sampleMessage.Id, sampleMessage.Message, sampleMessage.Via);
    }
}
