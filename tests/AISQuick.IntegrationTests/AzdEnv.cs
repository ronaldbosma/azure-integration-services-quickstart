using DotNetEnv;

namespace AISQuick.IntegrationTests;

/// <summary>
/// Provides functionality to load environment variables from a `.env` file located within the `.azure` directory hierarchy.
/// </summary>
/// <remarks>This class searches for a `.azure` directory in the current working directory or its parent
/// directories. Once located, it searches for a `.env` file within the subfolders of the `.azure` directory. If both
/// the `.azure` directory and the `.env` file are found, the environment variables from the `.env` file are loaded into
/// the current process using <see cref="DotNetEnv.Env"/>.
/// </remarks>
public static class AzdEnv
{
    public static void Load()
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