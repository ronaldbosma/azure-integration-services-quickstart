using AISQuick.IntegrationTests.Configuration.Azd;
using Microsoft.Extensions.Configuration;

namespace AISQuick.IntegrationTests.Configuration;

/// <summary>
/// Provides Azure environment configuration by loading environment variables from a `.env` file 
/// located within the `.azure` directory hierarchy and exposing configuration properties.
/// </summary>
/// <remarks>
/// This class searches for a `.azure` directory in the current working directory or its parent
/// directories. Once located, it searches for a `.env` file within the subfolders of the `.azure` directory. If both
/// the `.azure` directory and the `.env` file are found, the environment variables from the `.env` file are loaded into
/// the current process using <see cref="Env"/>.
/// </remarks>
public class AzdEnvironmentConfiguration
{
    public required string AzureKeyVaultName { get; init; }
    public required string AzureApiManagementName { get; init; }
    public required bool IncludeFunctionApp { get; init; }
    public required bool IncludeLogicApp { get; init; }

    public readonly string ApimSubscriptionKeySecretName = "apim-master-subscription-key";

    /// <summary>
    /// Loads the Azure environment configuration.
    /// </summary>
    public static AzdEnvironmentConfiguration Load()
    {
        var configuration = new ConfigurationBuilder()
            .AddEnvironmentVariables()
            .AddAzdEnvironmentVariables()
            .Build();

        return new AzdEnvironmentConfiguration
        {
            AzureKeyVaultName = configuration.GetRequiredString("AZURE_KEY_VAULT_NAME"),
            AzureApiManagementName = configuration.GetRequiredString("AZURE_API_MANAGEMENT_NAME"),
            IncludeFunctionApp = configuration.GetRequiredBool("INCLUDE_FUNCTION_APP"),
            IncludeLogicApp = configuration.GetRequiredBool("INCLUDE_LOGIC_APP")
        };
    }
}