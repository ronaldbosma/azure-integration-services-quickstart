using AISQuick.IntegrationTests.Configuration.Azd;
using Microsoft.Extensions.Configuration;

namespace AISQuick.IntegrationTests.Configuration;

/// <summary>
/// Contains configuration settings for the integration tests.
/// </summary>
internal class TestConfiguration
{
    public required string AzureKeyVaultName { get; init; }
    public required string AzureApiManagementName { get; init; }
    public required bool IncludeFunctionApp { get; init; }
    public required bool IncludeLogicApp { get; init; }

    public static TestConfiguration Load()
    {
        var configuration = new ConfigurationBuilder()
            .AddEnvironmentVariables()
            .AddAzdEnvironmentVariables()
            .Build();

        return new TestConfiguration
        {
            AzureKeyVaultName = configuration.GetRequiredString("AZURE_KEY_VAULT_NAME"),
            AzureApiManagementName = configuration.GetRequiredString("AZURE_API_MANAGEMENT_NAME"),
            IncludeFunctionApp = configuration.GetRequiredBool("INCLUDE_FUNCTION_APP"),
            IncludeLogicApp = configuration.GetRequiredBool("INCLUDE_LOGIC_APP")
        };
    }
}