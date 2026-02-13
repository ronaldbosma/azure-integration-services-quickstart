using Microsoft.Extensions.Configuration;

namespace AISQuick.IntegrationTests.Configuration;

/// <summary>
/// Provides extension methods for <see cref="IConfiguration"/> to retrieve required configuration values.
/// </summary>
internal static class IConfigurationExtensions
{
    public static Uri GetRequiredUri(this IConfiguration configuration, string key)
    {
        return new Uri(configuration.GetRequiredString(key));
    }

    public static string GetRequiredString(this IConfiguration configuration, string key)
    {
        var value = configuration[key];
        if (string.IsNullOrWhiteSpace(value))
        {
            throw new InvalidOperationException($"Configuration value for '{key}' is null or empty.");
        }
        return value;
    }

    public static bool GetRequiredBool(this IConfiguration configuration, string key)
    {
        var value = configuration[key];
        if (string.IsNullOrWhiteSpace(value) || !bool.TryParse(value, out var result))
        {
            throw new InvalidOperationException($"Configuration value for '{key}' is null, empty or not a valid boolean.");
        }
        return result;
    }
}
