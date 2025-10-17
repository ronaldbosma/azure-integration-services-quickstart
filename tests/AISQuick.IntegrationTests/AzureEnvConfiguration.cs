using DotNetEnv;

namespace AISQuick.IntegrationTests;

/// <summary>
/// Provides Azure environment configuration by loading environment variables from a `.env` file 
/// located within the `.azure` directory hierarchy and exposing configuration properties.
/// </summary>
/// <remarks>
/// This class searches for a `.azure` directory in the current working directory or its parent
/// directories. Once located, it searches for a `.env` file within the subfolders of the `.azure` directory. If both
/// the `.azure` directory and the `.env` file are found, the environment variables from the `.env` file are loaded into
/// the current process using <see cref="DotNetEnv.Env"/>.
/// </remarks>
public sealed class AzureEnvConfiguration
{
    public required string AzureKeyVaultName { get; init; }
    public required string AzureApiManagementName { get; init; }
    public required bool IncludeFunctionApp { get; init; }
    public required bool IncludeLogicApp { get; init; }

    public readonly string ApimSubscriptionKeySecretName = "apim-master-subscription-key";

    public static AzureEnvConfiguration FromEnvironment()
    {
        LoadAzureEnvironmentFile();

        return new AzureEnvConfiguration
        {
            AzureKeyVaultName = Env.GetString("AZURE_KEY_VAULT_NAME"),
            AzureApiManagementName = Env.GetString("AZURE_API_MANAGEMENT_NAME"),
            IncludeFunctionApp = Env.GetBool("INCLUDE_FUNCTION_APP", false),
            IncludeLogicApp = Env.GetBool("INCLUDE_LOGIC_APP", false)
        };
    }

    private static void LoadAzureEnvironmentFile()
    {
        var azureDir = FindAzureDirectory() 
            ?? throw new DirectoryNotFoundException("Could not find .azure directory in parent directories");
        
        var envFile = FindEnvFileInAzureSubfolders(azureDir) 
            ?? throw new FileNotFoundException("Could not find .env file in any subfolder of .azure directory");
        
        Env.Load(envFile);
    }

    private static string? FindAzureDirectory()
    {
        var currentDir = new DirectoryInfo(Directory.GetCurrentDirectory());
        
        while (currentDir != null)
        {
            var azureDir = Path.Combine(currentDir.FullName, ".azure");
            if (Directory.Exists(azureDir))
            {
                return azureDir;
            }
            currentDir = currentDir.Parent;
        }
        
        return null;
    }

    private static string? FindEnvFileInAzureSubfolders(string azureDir)
    {
        return Directory.GetDirectories(azureDir)
            .Select(subfolder => Path.Combine(subfolder, ".env"))
            .FirstOrDefault(File.Exists);
    }
}