using System.Text.Json;

namespace AISQuick.IntegrationTests.Configuration.Azd;

/// <summary>
/// Helper class to locate the .env file for the default azd environment.
/// </summary>
internal class AzdEnvironmentFileLocator
{
    /// <summary>
    /// Locates the .env file for the default azd environment.
    /// </summary>
    /// <returns>File path to .env file of default azd environment.</returns>
    /// <exception cref="DirectoryNotFoundException">Thrown when the .azure directory is not found.</exception>
    /// <exception cref="FileNotFoundException">Thrown when the .env file is not found.</exception>
    /// <exception cref="InvalidOperationException">Thrown when the default environment cannot be determined.</exception>
    public static string LocateEnvFileOfDefaultAzdEnvironment()
    {
        var azureDirectory = GetAzureDirectory(AppContext.BaseDirectory);
        var defaultEnvironmentName = GetDefaultEnvironmentName(azureDirectory);
        return GetEnvFileForEnvironment(azureDirectory, defaultEnvironmentName);
    }

    private static string GetAzureDirectory(string startingDirectory)
    {
        var currentDirectory = new DirectoryInfo(startingDirectory);

        while (currentDirectory != null)
        {
            var azureDirectory = Path.Combine(currentDirectory.FullName, ".azure");
            if (Directory.Exists(azureDirectory))
            {
                return azureDirectory;
            }
            currentDirectory = currentDirectory.Parent;
        }

        throw new DirectoryNotFoundException($"Could not find .azure directory in parent directories of {startingDirectory}");
    }

    private static string GetDefaultEnvironmentName(string azureDirectory)
    {
        var configFile = Path.Combine(azureDirectory, "config.json");
        if (!File.Exists(configFile))
        {
            throw new FileNotFoundException($"Unable to determine default environment. Could not find config.json file in directory: {azureDirectory}");
        }

        var configJson = File.ReadAllText(configFile);
        using var document = JsonDocument.Parse(configJson);
        if (!document.RootElement.TryGetProperty("defaultEnvironment", out var defaultEnvironmentElement))
        {
            throw new InvalidOperationException($"Property 'defaultEnvironment' not found in: {configFile}");
        }

        var defaultEnvironment = defaultEnvironmentElement.GetString();
        if (string.IsNullOrWhiteSpace(defaultEnvironment))
        {
            throw new InvalidOperationException($"Value of 'defaultEnvironment' is null or empty in: {configFile}");
        }

        return defaultEnvironment;
    }

    private static string GetEnvFileForEnvironment(string azureDirectory, string environmentName)
    {
        var envFile = Path.Combine(azureDirectory, environmentName, ".env");
        if (!File.Exists(envFile))
        {
            throw new FileNotFoundException($"Could not find .env file for environment '{environmentName}' in directory: {azureDirectory}");
        }

        return envFile;
    }
}
