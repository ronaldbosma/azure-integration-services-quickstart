#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Publishes a new release to GitHub

.DESCRIPTION
    This script orchestrates the automated release process by:
    - Loading release functions from publish-new-release.functions.ps1
    - Determining the new version based on the latest tag and the specified version bump type
    - Updating the azure.yaml template with the new version
    - Creating a new git tag and pushing changes to GitHub
    - Publish a GitHub release with auto-generated notes

.PARAMETER VersionBump
    The type of version bump to perform: major, minor, or patch

.NOTES
    Requirements: git CLI and GitHub CLI (gh) must be installed and authenticated
#>

param(
    [Parameter(Mandatory=$true)]
    [ValidateSet("major", "minor", "patch")]
    [string]$VersionBump
)

# Stop on any error
$ErrorActionPreference = "Stop"

# Load functions
. (Join-Path $PSScriptRoot "publish-new-release.functions.ps1")

try {
    Assert-HasChanges
    $newVersion = Get-NewVersion -VersionBump $VersionBump
    Update-AzureYamlVersion -NewVersion $newVersion
    # Set-ReleaseTag -Tag $newVersion
    # New-GitHubRelease -Tag $newVersion
}
catch {
    Write-Error "Script execution failed: $_"
    exit 1
}
