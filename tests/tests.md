# Tests

## REST Client for Visual Studio Code

To use the tests in [tests.http](tests.http) in Visual Studio Code, install the [REST Client extension](https://marketplace.visualstudio.com/items?itemName=humao.rest-client). After installing the extension, you can configure [environment variables](https://github.com/Huachao/vscode-restclient#environment-variables) in your VS Code user settings by adding the following section. Replace `<env-name>`, `<apim-name>`, and `<apim-subscription-key>` with the appropriate values.

```json
"rest-client.environmentVariables": {
    "<env-name>": {
        "apimHostname": "<apim-name>.azure-api.net",
        "apimSubscriptionKey": "<apim-subscription-key>"
    },
}
```
