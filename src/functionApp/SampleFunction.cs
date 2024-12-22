using System;
using System.Threading.Tasks;
using Azure.Messaging.ServiceBus;
using Microsoft.Azure.Functions.Worker;
using Microsoft.Extensions.Logging;

namespace AISQuick.FunctionApp
{
    public class SampleFunction
    {
        private readonly ILogger<SampleFunction> _logger;

        public SampleFunction(ILogger<SampleFunction> logger)
        {
            _logger = logger;
        }

        [Function(nameof(SampleFunction))]
        public async Task Run(
            [ServiceBusTrigger("sample", "function-app-subscription-on-sample", Connection = "")]
            ServiceBusReceivedMessage message,
            ServiceBusMessageActions messageActions)
        {
            _logger.LogInformation("Message ID: {id}", message.MessageId);
            _logger.LogInformation("Message Body: {body}", message.Body);
            _logger.LogInformation("Message Content-Type: {contentType}", message.ContentType);

             // Complete the message
            await messageActions.CompleteMessageAsync(message);
        }
    }
}
