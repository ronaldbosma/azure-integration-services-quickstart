param (
    [ValidateLength(5,15)][string]$Environment = "aisquick-dev",
    [string]$Location = "norwayeast",
    [ValidateLength(0,5)][string]$Instance = $null,
    [string]$CurrentUserPrincipalId = $null
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest


# =============================================================================
#  Get Id of Current User
# =============================================================================

# If the Id of the Current User is not specified, try to get the signed in user and use theirs.
# NOTE: depending on the access rights of the signed in user, this might fail.
if (-not($CurrentUserPrincipalId))
{
    $signedInUser = az ad signed-in-user show | ConvertFrom-Json
    if ($signedInUser)
    {
        $CurrentUserPrincipalId = $signedInUser.id
    }
}


# =============================================================================
#  Deploy Resources
# =============================================================================
    
# Print the time and date before starting the deployment so you can estimate when it's finished if you have an expected duration
Write-Host "Start deployment at: $(Get-Date -Format "dd-MM-yyyy HH:mm:ss")"

# Deploy the resources with Bicep
az deployment sub create `
    --name "deploy-$Environment-$(Get-Date -Format "yyyyMMdd-HHmmss")" `
    --location $Location `
    --template-file './main.bicep' `
    --parameters environmentName=$Environment `
                 location=$Location `
                 instance=$Instance `
                 currentUserPrincipalId=$CurrentUserPrincipalId `
    --verbose
