using Microsoft.Extensions.Configuration;

namespace AISQuick.IntegrationTests.Configuration.Azd;

/// <summary>
/// Represents an .env file as an <see cref="IConfigurationSource"/>.
/// </summary>
internal class EnvFileConfigurationSource : FileConfigurationSource
{
    /// <summary>
    /// Builds the <see cref="EnvFileConfigurationProvider"/> for this source.
    /// </summary>
    /// <param name="builder">The <see cref="IConfigurationBuilder"/>.</param>
    /// <returns>A <see cref="EnvFileConfigurationProvider"/> instance.</returns>
    public override IConfigurationProvider Build(IConfigurationBuilder builder)
    {
        EnsureDefaults(builder);
        return new EnvFileConfigurationProvider(this);
    }
}
