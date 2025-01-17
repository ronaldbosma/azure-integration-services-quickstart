using Azure;
using Azure.Data.Tables;

namespace AISQuick.FunctionApp.Models
{
    public class SampleTableEntity : ITableEntity
    {
        public SampleTableEntity(Guid id, string message, string via)
        {
            PartitionKey = "aisquick-sample";
            RowKey = id.ToString();
            Message = message;
            Via = via;
        }

        public string PartitionKey { get; set; }
        
        public string RowKey { get; set; }

        public string Message { get; set; }

        public string Via { get; set; }

        public DateTimeOffset? Timestamp { get; set; }
        
        public ETag ETag { get; set; }
    }
}
