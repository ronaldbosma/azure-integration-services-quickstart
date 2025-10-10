<#
  This PowerShell script is executed before the resources are removed. 
  It permanently deletes the Log Analytics workspace to prevent issues with future deployments. 
  Sometimes the requests and traces don't show up in Application Insights & Log Analytics when removing and deploying the template multiple times.
  A predown hook is used and not a postdown hook because permanent deletion of the workspace doesn't work
  if it's already in the soft-deleted state after azd has removed it.
#>

param(
    [Parameter(Mandatory = $false)]
    [string]$SubscriptionId = $env:AZURE_SUBSCRIPTION_ID,
    
    [Parameter(Mandatory = $false)]
    [string]$ResourceGroup = $env:AZURE_RESOURCE_GROUP,
    
    [Parameter(Mandatory = $false)]
    [string]$LogAnalyticsWorkspaceName = $env:AZURE_LOG_ANALYTICS_WORKSPACE_NAME
)

# Validate required parameters
if ([string]::IsNullOrEmpty($SubscriptionId)) {
    throw "SubscriptionId parameter is required. Please provide it as a parameter or set the AZURE_SUBSCRIPTION_ID environment variable."
}

if ([string]::IsNullOrEmpty($ResourceGroup)) {
    throw "ResourceGroup parameter is required. Please provide it as a parameter or set the AZURE_RESOURCE_GROUP environment variable."
}

if ([string]::IsNullOrEmpty($LogAnalyticsWorkspaceName)) {
    throw "LogAnalyticsWorkspaceName parameter is required. Please provide it as a parameter or set the AZURE_LOG_ANALYTICS_WORKSPACE_NAME environment variable."
}


# First, ensure the Azure CLI is logged in and set to the correct subscription
az account set --subscription $SubscriptionId
if ($LASTEXITCODE -ne 0) {
    throw "Unable to set the Azure subscription. Please make sure that you're logged into the Azure CLI with the same credentials as the Azure Developer CLI."
}


# Delete the Log Analytics workspace
Write-Host "Deleting Log Analytics workspace $LogAnalyticsWorkspaceName"
az monitor log-analytics workspace delete --subscription $SubscriptionId --resource-group $ResourceGroup --workspace-name $LogAnalyticsWorkspaceName --force --yes