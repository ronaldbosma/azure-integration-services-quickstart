using Azure.Identity;
using Azure.Security.KeyVault.Secrets;

namespace AISQuick.IntegrationTests.Clients;

/// <summary>
/// Provides a client for interacting with Azure Key Vault to retrieve secrets.
/// </summary>
internal class KeyVaultClient
{
    private readonly SecretClient _secretClient;

    /// <summary>
    /// Creates an instance of <see cref="KeyVaultClient"/> to interact with the specified Key Vault.
    /// </summary>
    /// <param name="keyVaultName">The name of the Azure Key Vault instance.</param>
    public KeyVaultClient(string keyVaultName)
    {
        var keyVaultUri = new Uri($"https://{keyVaultName}.vault.azure.net/");
        _secretClient = new SecretClient(keyVaultUri, new DefaultAzureCredential());
    }

    /// <summary>
    /// Retrieves the value of a secret from Azure Key Vault asynchronously.
    /// </summary>
    /// <param name="secretName">The name of the secret to retrieve.</param>
    /// <returns>The value of the secret.</returns>
    public async Task<string> GetSecretValueAsync(string secretName)
    {
        var secret = await _secretClient.GetSecretAsync(secretName);
        return secret.Value.Value;
    }
}
