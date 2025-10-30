using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.FileProviders;
using Microsoft.Extensions.FileProviders.Physical;

namespace AISQuick.IntegrationTests.Configuration.Azd
{
    /// <summary>
    /// Extension methods for adding <see cref="EnvFileConfigurationProvider"/>.
    /// </summary>
    internal static class EnvFileExtensions
    {
        /// <summary>
        /// Adds the .env file configuration provider at <paramref name="path"/> to <paramref name="builder"/>.
        /// </summary>
        /// <param name="builder">The <see cref="IConfigurationBuilder"/> to add to.</param>
        /// <param name="path">The path to the .env file.</param>
        /// <param name="optional">Indication if loading the .env file is optional.</param>
        /// <returns>The <see cref="IConfigurationBuilder"/>.</returns>
        public static IConfigurationBuilder AddEnvFile(this IConfigurationBuilder builder, string path, bool optional)
        {
            if (string.IsNullOrWhiteSpace(path))
            {
                throw new ArgumentNullException(nameof(path));
            }

            if (!File.Exists(path))
            {
                if (!optional)
                {
                    throw new FileNotFoundException($"Unable to find .env file: {path}");
                }
                return builder;
            }

            // We need to create our own PhysicalFileProvider because the default one excludes hiddens files and files starting with a dot.
            var root = Path.GetDirectoryName(path) ?? throw new ArgumentException($"Unable to determine directory from path: {path}", nameof(path));
            var fileProvider = new PhysicalFileProvider(root, ExclusionFilters.System);

            return builder.AddEnvFile(s =>
            {
                s.Path = Path.GetFileName(path);
                s.Optional = optional;
                s.ReloadOnChange = false;
                s.FileProvider = fileProvider;
            });
        }

        /// <summary>
        /// Add the .env file configuration source to <paramref name="builder"/>.
        /// </summary>
        /// <param name="builder">The <see cref="IConfigurationBuilder"/> to add to.</param>
        /// <param name="configureSource">An action to configure the source.</param>
        /// <returns>The <see cref="IConfigurationBuilder"/>.</returns>
        public static IConfigurationBuilder AddEnvFile(this IConfigurationBuilder builder, Action<EnvFileConfigurationSource>? configureSource)
            => builder.Add(configureSource);

    }
}
