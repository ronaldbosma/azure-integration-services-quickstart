using AISQuick.FunctionApp.Models;
using Microsoft.Azure.Functions.Worker;
using Microsoft.Extensions.Logging;

namespace AISQuick.FunctionApp;

public class EventHubSampleFunction
{
    private readonly ILogger<EventHubSampleFunction> _logger;

    public EventHubSampleFunction(ILogger<EventHubSampleFunction> logger)
    {
        _logger = logger;
    }

    [Function(nameof(EventHubSampleFunction))]
    [TableOutput("aisquickSample", Connection = "StorageAccountConnection")]
    public SampleTableEntity Run(
        [EventHubTrigger("aisquick-sample", ConsumerGroup = "function-app", Connection = "EventHubConnection", IsBatched = false)]
        SampleMessage sampleMessage
    )
    {
        _logger.LogInformation("Received message '{message}' with ID {id}", sampleMessage.Message, sampleMessage.Id);

        return new SampleTableEntity(sampleMessage);
    }
}
