<#
Exports specified Azure Developer CLI (azd) environment variables as GitHub Actions output.
Usage samples:
    .\export-azd-env-variables.ps1 -VariableNames "AZURE_RESOURCE_GROUP"
    .\export-azd-env-variables.ps1 -VariableNames @("AZURE_RESOURCE_GROUP", "AZURE_LOCATION")
#>

param(
    [Parameter(Mandatory = $false)]
    [string[]]$VariableNames = @()
)

# Export specific variables
foreach ($varName in $VariableNames) {
    $value = azd env get-value $varName
    if ($value) {
        Write-Host "Exporting $varName"
        "$varName=$value" >> $env:GITHUB_OUTPUT
    }
}
