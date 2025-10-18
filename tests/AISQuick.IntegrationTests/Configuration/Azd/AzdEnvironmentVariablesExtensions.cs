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
            string path = AzdEnvironmentFileLocator.LocateEnvFileOfDefaultAzdEnvironment();
            return builder.AddAzdEnvironmentVariables(path);
        }

        /// <summary>
        /// Adds the azd environment variables configuration provider at <paramref name="path"/> to <paramref name="builder"/>.
        /// </summary>
        /// <param name="builder">The <see cref="IConfigurationBuilder"/> to add to.</param>
        /// <param name="path">The path to the .env file.</param>
        /// <returns>The <see cref="IConfigurationBuilder"/>.</returns>
        public static IConfigurationBuilder AddAzdEnvironmentVariables(this IConfigurationBuilder builder, string path)
        {
            if (string.IsNullOrWhiteSpace(path))
            {
                throw new ArgumentException("Path to the .env file must be a non-empty string.", nameof(path));
            }

            // We need to create our own PhysicalFileProvider because the default one excludes hiddens files and files starting with a dot.
            var root = Path.GetDirectoryName(path) ?? throw new ArgumentException($"Unable to determine directory from path: {path}", nameof(path));
            var fileProvider = new PhysicalFileProvider(root, ExclusionFilters.System);

            return builder.AddAzdEnvFile(s =>
            {
                s.Path = Path.GetFileName(path);
                s.Optional = false;
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
