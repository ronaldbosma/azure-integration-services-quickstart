using System;
using System.Text.Json;
using System.Threading.Tasks;
using AISQuick.FunctionApp.Models;
using Azure.Messaging.ServiceBus;
using Microsoft.Azure.Functions.Worker;
using Microsoft.Extensions.Logging;

namespace AISQuick.FunctionApp
{
    public class SampleFunction
    {
        private static readonly JsonSerializerOptions JsonSerializerOptions = new(JsonSerializerDefaults.Web);

        private readonly ILogger<SampleFunction> _logger;

        public SampleFunction(ILogger<SampleFunction> logger)
        {
            _logger = logger;
        }

        [Function(nameof(SampleFunction))]
        [TableOutput("sample", Connection = "TableStorageConnection")]
        public async Task<SampleTableEntity> Run(
            [ServiceBusTrigger("sample", "function-app", Connection = "ServiceBusConnection")]
            ServiceBusReceivedMessage message,
            ServiceBusMessageActions messageActions)
        {
            var messageBody = JsonSerializer.Deserialize<SampleMessage>(message.Body, JsonSerializerOptions)
                ?? throw new ArgumentException("Unable to deserialize message body", nameof(message));

            _logger.LogInformation("Received message '{message}' with ID {id}", messageBody.Message, messageBody.Id);

            // Complete the message
            await messageActions.CompleteMessageAsync(message);

            return new SampleTableEntity(messageBody.Id, messageBody.Message);
        }
    }
}
