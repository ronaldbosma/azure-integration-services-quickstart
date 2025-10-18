using Microsoft.Extensions.Configuration;

namespace AISQuick.IntegrationTests.Configuration.Azd;

/// <summary>
/// Provides configuration key-value pairs that are obtained from an .env file.
/// </summary>
internal class AzdEnvironmentVariablesConfigurationProvider : FileConfigurationProvider
{
    /// <summary>
    /// Initializes a new instance with the specified source.
    /// </summary>
    /// <param name="source">The source settings.</param>
    public AzdEnvironmentVariablesConfigurationProvider(FileConfigurationSource source) : base(source)
    {
    }

    /// <summary>
    /// Load the env data from a stream.
    /// </summary>
    /// <param name="stream">The stream to read.</param>
    public override void Load(Stream stream)
    {
        var data = new Dictionary<string, string?>();

        using var reader = new StreamReader(stream);
        string? line;
            
        while ((line = reader.ReadLine()) != null)
        {
            // Skip empty lines and comments
            line = line.Trim();
            if (string.IsNullOrEmpty(line) || line.StartsWith('#'))
            {
                continue;
            }

            // Find the equals sign
            var equalIndex = line.IndexOf('=');
            if (equalIndex == -1)
            {
                continue;
            }

            var key = line.Substring(0, equalIndex).Trim();
            var value = line.Substring(equalIndex + 1).Trim();

            // Remove surrounding quotes if present
            if (value.Length >= 2 && value.StartsWith('"') && value.EndsWith('"'))
            {
                value = value.Substring(1, value.Length - 2);
            }

            data[key] = value;
        }

        Data = data;
    }
}
