namespace AISQuick.FunctionApp.Models
{
    /// <summary>
    /// Sample message that is received by the function.
    /// </summary>
    public record SampleMessage(Guid Id, string Message, string Via)
    {
    }
}
