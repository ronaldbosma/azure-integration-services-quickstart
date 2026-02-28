namespace AISQuick.IntegrationTests.Models;

public sealed record TableEntityResponse(
    string PartitionKey,
    string RowKey,
    string Message,
    string Via);