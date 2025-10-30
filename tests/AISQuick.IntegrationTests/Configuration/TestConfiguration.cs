using AISQuick.IntegrationTests.Configuration.Azd;
using Microsoft.Extensions.Configuration;

namespace AISQuick.IntegrationTests.Configuration;

/// <summary>
/// Contains configuration settings for the integration tests.
/// </summary>
internal class TestConfiguration
{
    public required Uri AzureApiManagementGatewayUrl { get; init; }
    public required Uri AzureKeyVaultUri { get; init; }
    public required bool IncludeFunctionApp { get; init; }
    public required bool IncludeLogicApp { get; init; }

    public static TestConfiguration Load()
    {
        var configuration = new ConfigurationBuilder()
            .AddEnvironmentVariables()
            .AddAzdEnvironmentVariables(optional: true) // Adds Azure Developer CLI environment variables; optional since CI/CD pipelines may use standard environment variables instead
            .Build();

        return new TestConfiguration
        {
            AzureApiManagementGatewayUrl = configuration.GetRequiredUri("AZURE_API_MANAGEMENT_GATEWAY_URL"),
            AzureKeyVaultUri = configuration.GetRequiredUri("AZURE_KEY_VAULT_URI"),
            IncludeFunctionApp = configuration.GetRequiredBool("INCLUDE_FUNCTION_APP"),
            IncludeLogicApp = configuration.GetRequiredBool("INCLUDE_LOGIC_APP")
        };
    }
}