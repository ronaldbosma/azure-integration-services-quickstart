using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.FileProviders;
using Microsoft.Extensions.FileProviders.Physical;

namespace AISQuick.IntegrationTests.Configuration.Azd
{
    /// <summary>
    /// Extension methods for adding <see cref="AzdEnvironmentVariablesConfigurationProvider"/>.
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
        public static IConfigurationBuilder AddAzdEnvironmentVariables(this IConfigurationBuilder builder, string path, bool optional)
        {
            if (string.IsNullOrWhiteSpace(path))
            {
                if (!optional)
                {
                    throw new ArgumentException("Path to the azd .env file must be a non-empty string.", nameof(path)); 
                }
                return builder;
            } 

            // We need to create our own PhysicalFileProvider because the default one excludes hiddens files and files starting with a dot.
            var root = Path.GetDirectoryName(path) ?? throw new ArgumentException($"Unable to determine directory from path: {path}", nameof(path));
            var fileProvider = new PhysicalFileProvider(root, ExclusionFilters.System);

            return builder.AddAzdEnvFile(s =>
            {
                s.Path = Path.GetFileName(path);
                s.Optional = optional;
                s.ReloadOnChange = false;
                s.FileProvider = fileProvider;
            });
        }

        /// <summary>
        /// Add an azd environment variables configuration source to <paramref name="builder"/>.
        /// </summary>
        /// <param name="builder">The <see cref="IConfigurationBuilder"/> to add to.</param>
        /// <param name="configureSource">An action to configure the source.</param>
        /// <returns>The <see cref="IConfigurationBuilder"/>.</returns>
        public static IConfigurationBuilder AddAzdEnvFile(this IConfigurationBuilder builder, Action<AzdEnvironmentVariablesConfigurationSource>? configureSource)
            => builder.Add(configureSource);

    }
}
