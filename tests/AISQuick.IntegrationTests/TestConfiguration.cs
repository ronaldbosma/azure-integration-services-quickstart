using DotNetEnv;

namespace AISQuick.IntegrationTests;

public sealed class TestConfiguration
{
    public required string AzureKeyVaultName { get; init; }
    public required string AzureApiManagementName { get; init; }
    public required bool IncludeFunctionApp { get; init; }
    public required bool IncludeLogicApp { get; init; }

    public readonly string ApimSubscriptionKeySecretName = "apim-master-subscription-key";

    public static TestConfiguration FromEnvironment()
    {
        AzdEnv.Load();

        return new TestConfiguration
        {
            AzureKeyVaultName = Env.GetString("AZURE_KEY_VAULT_NAME"),
            AzureApiManagementName = Env.GetString("AZURE_API_MANAGEMENT_NAME"),
            IncludeFunctionApp = Env.GetBool("INCLUDE_FUNCTION_APP", false),
            IncludeLogicApp = Env.GetBool("INCLUDE_LOGIC_APP", false)
        };
    }
}