using Microsoft.Extensions.Configuration;

namespace AISQuick.IntegrationTests.Configuration.Azd;

/// <summary>
/// Represents an azd .env file as an <see cref="IConfigurationSource"/>.
/// </summary>
internal class AzdEnvironmentVariablesConfigurationSource : FileConfigurationSource
{
    /// <summary>
    /// Builds the <see cref="AzdEnvironmentVariablesConfigurationProvider"/> for this source.
    /// </summary>
    /// <param name="builder">The <see cref="IConfigurationBuilder"/>.</param>
    /// <returns>A <see cref="AzdEnvironmentVariablesConfigurationProvider"/> instance.</returns>
    public override IConfigurationProvider Build(IConfigurationBuilder builder)
    {
        EnsureDefaults(builder);
        return new AzdEnvironmentVariablesConfigurationProvider(this);
    }
}
