using Azure;
using Azure.Data.Tables;

namespace AISQuick.FunctionApp.Models
{
    /// <summary>
    /// Table entity to insert a sample message in Azure Table Storage.
    /// </summary>
    public class SampleTableEntity : ITableEntity
    {
        public SampleTableEntity(SampleMessage sampleMessage)
        {
            PartitionKey = "aisquick-sample";
            RowKey = sampleMessage.Id.ToString();
            Message = sampleMessage.Message;
            Via = sampleMessage.Via;
        }

        public string PartitionKey { get; set; }
        
        public string RowKey { get; set; }

        public string Message { get; set; }

        public string Via { get; set; }

        public DateTimeOffset? Timestamp { get; set; }
        
        public ETag ETag { get; set; }
    }
}
