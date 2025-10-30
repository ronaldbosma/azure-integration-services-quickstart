using Microsoft.Extensions.Configuration;

namespace AISQuick.IntegrationTests.Configuration.Azd
{
    /// <summary>
    /// Extension methods for adding <see cref="EnvFileConfigurationProvider"/>.
    /// </summary>
    internal static class AzdEnvironmentVariablesExtensions
    {
        /// <summary>
        /// Adds the azd environment variables configuration provider to <paramref name="builder"/>.
        /// </summary>
        /// <param name="builder">The <see cref="IConfigurationBuilder"/> to add to.</param>
        /// <returns>The <see cref="IConfigurationBuilder"/>.</returns>
        public static IConfigurationBuilder AddAzdEnvironmentVariables(this IConfigurationBuilder builder)
        {
            return builder.AddAzdEnvironmentVariables(optional: false);
        }

        /// <summary>
        /// Adds the azd environment variables configuration provider to <paramref name="builder"/>.
        /// </summary>
        /// <param name="builder">The <see cref="IConfigurationBuilder"/> to add to.</param>
        /// <param name="optional">Indication if loading the azd env variables is optional.</param>
        /// <returns>The <see cref="IConfigurationBuilder"/>.</returns>
        public static IConfigurationBuilder AddAzdEnvironmentVariables(this IConfigurationBuilder builder, bool optional)
        {
            string path = AzdEnvironmentFileLocator.LocateEnvFileOfDefaultAzdEnvironment(optional);
            return builder.AddAzdEnvironmentVariables(path, optional);
        }

        /// <summary>
        /// Adds the azd environment variables configuration provider at <paramref name="path"/> to <paramref name="builder"/>.
        /// </summary>
        /// <param name="builder">The <see cref="IConfigurationBuilder"/> to add to.</param>
        /// <param name="path">The path to the .env file.</param>
        /// <param name="optional">Indication if loading the azd env variables is optional.</param>
        /// <returns>The <see cref="IConfigurationBuilder"/>.</returns>
        private static IConfigurationBuilder AddAzdEnvironmentVariables(this IConfigurationBuilder builder, string path, bool optional)
        {
            if (string.IsNullOrWhiteSpace(path) && !optional)
            {
                throw new ArgumentException("Path to the azd .env file must be a non-empty string.", nameof(path)); 
            }

            return builder.AddEnvFile(path, optional);
        }
    }
}
