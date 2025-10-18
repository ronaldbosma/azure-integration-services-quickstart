using Azure.Identity;
using Azure.Security.KeyVault.Secrets;

namespace AISQuick.IntegrationTests.Clients
{
    internal class KeyVaultClient
    {
        private readonly SecretClient _secretClient;

        public KeyVaultClient(string keyVaultName)
        {
            var keyVaultUri = new Uri($"https://{keyVaultName}.vault.azure.net/");
            _secretClient = new SecretClient(keyVaultUri, new DefaultAzureCredential());
        }

        public async Task<string> GetSecretValueAsync(string secretName)
        {
            var secret = await _secretClient.GetSecretAsync(secretName);
            return secret.Value.Value;
        }
    }
}
