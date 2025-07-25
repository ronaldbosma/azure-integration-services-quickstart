# Permanently delete the Log Analytics workspace to prevent issues with the next deployment.
#
# Sometimes the requests and traces don't show up in Application Insights & Log Analytics. 
# I've had this happen when I'd taken down an environment and redeployed it with the same name.
# Permanently deleting the Log Analytics workspace seems to fix this issue.
#
# A predown hook is used and not a postdown hook because permanent deletion of the workspace doesn't work
#   if it's already in the soft-deleted state after azd has removed it.


# First, ensure the Azure CLI is logged in and set to the correct subscription
az account set --subscription $env:AZURE_SUBSCRIPTION_ID
if ($LASTEXITCODE -ne 0) {
    throw "Unable to set the Azure subscription. Please make sure that you're logged into the Azure CLI with the same credentials as the Azure Developer CLI."
}


if ($env:AZURE_SUBSCRIPTION_ID -and $env:AZURE_RESOURCE_GROUP -and $env:AZURE_LOG_ANALYTICS_WORKSPACE_NAME) {
    Write-Host "Deleting Log Analytics workspace $($env:AZURE_LOG_ANALYTICS_WORKSPACE_NAME)"
    az monitor log-analytics workspace delete --subscription $env:AZURE_SUBSCRIPTION_ID --resource-group $env:AZURE_RESOURCE_GROUP --workspace-name $env:AZURE_LOG_ANALYTICS_WORKSPACE_NAME --force --yes
} else {
    Write-Host "One or more required environment variables are missing. Skipping log analytics workspace deletion."
}