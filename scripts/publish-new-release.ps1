#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Publishes a new release to GitHub by analyzing merged PRs and creating a new version tag.

.DESCRIPTION
    This script automates the release process by:
    - Switching to the main branch
    - Verifying no local changes or unpushed commits exist
    - Pulling the latest changes
    - Finding the latest version tag
    - Finding PRs merged after the latest tag
    - Incrementing the version (minor bump, patch reset to 0)
    - Displaying the new version and merged PRs
    - With user confirmation:
      - Updating the azure.yaml template version
      - Creating a new tag
      - Push changes to GitHub
      - Creating a GitHub release with generated release notes

.NOTES
    Requirements: git CLI and GitHub CLI (gh) must be installed and authenticated
#>

param()

# Stop on any error
$ErrorActionPreference = "Stop"

function Write-Header {
    param([string]$Message)
    Write-Host ""
    Write-Host "=== $Message ===" -ForegroundColor Cyan
    Write-Host ""
}

function Write-Success {
    param([string]$Message)
    Write-Host $Message -ForegroundColor Green
}

function Write-Error {
    param([string]$Message)
    Write-Host "ERROR: $Message" -ForegroundColor Red
}

try {
    Write-Header "Checking Prerequisites"
    
    # Verify git is available
    $gitVersion = git --version
    Write-Success "Found: $gitVersion"
    
    # Verify gh CLI is available
    $ghVersion = gh --version
    Write-Success "Found: $ghVersion"
    
    # ===== SWITCH TO MAIN BRANCH =====
    Write-Header "Switching to main branch"
    git checkout main
    
    # Verify we're actually on main
    $currentBranch = git branch --show-current
    if ($currentBranch -ne "main") {
        Write-Error "Failed to switch to main branch. Currently on: $currentBranch"
        exit 1
    }
    Write-Success "Switched to main branch"
    
    # ===== CHECK FOR LOCAL CHANGES =====
    Write-Header "Checking for local changes"
    $gitStatus = git status --porcelain
    if ($gitStatus) {
        Write-Error "Local uncommitted changes detected. Please commit or stash your changes."
        exit 1
    }
    Write-Success "No local changes"
    
    # ===== CHECK FOR UNPUSHED COMMITS =====
    Write-Header "Checking for unpushed commits"
    $unpushedCommits = git log origin/main..main --oneline
    if ($unpushedCommits) {
        Write-Error "Unpushed commits detected. Please push your changes first."
        exit 1
    }
    Write-Success "No unpushed commits"
    
    # ===== PULL LATEST CHANGES =====
    Write-Header "Pulling latest changes"
    git pull origin main
    Write-Success "Latest changes pulled"
    
    # ===== FIND LATEST TAG =====
    Write-Header "Finding latest version tag"
    $latestTag = git describe --tags --abbrev=0 2>$null
    if (-not $latestTag) {
        Write-Error "No version tags found. Please create an initial version tag (e.g., 1.0.0)"
        exit 1
    }
    $tagTimestamp = git log -1 --format=%aI $latestTag
    Write-Success "Latest tag:    $latestTag"
    Write-Host    "Tag timestamp: $tagTimestamp"
    
    # ===== EXTRACT VERSION FROM TAG =====
    Write-Header "Parsing version from tag"
    $versionMatch = $latestTag -match '^(\d+)\.(\d+)\.(\d+)$'
    if (-not $versionMatch) {
        Write-Error "Tag format does not match semantic versioning (#.#.#). Found: $latestTag"
        exit 1
    }
    
    $major = [int]$matches[1]
    $minor = [int]$matches[2]
    $patch = [int]$matches[3]
    
    Write-Success "Current version: $major.$minor.$patch"
    
    # ===== FIND MERGED PRs AFTER LATEST TAG =====
    Write-Header "Finding PRs merged after latest tag"
    
    # Get all PRs merged into main after the tag
    $mergedPRs = gh pr list --search "base:main merged:>$tagTimestamp" --state merged --json number,title,mergedAt --limit 100
    
    if (-not $mergedPRs -or $mergedPRs -eq "[]") {
        Write-Host "No PRs found merged after $latestTag" -ForegroundColor Yellow
        $prList = @()
    }
    else {
        $prList = $mergedPRs | ConvertFrom-Json
        Write-Success "Found $($prList.Count) merged PR(s)"
    }
        
    # ===== CALCULATE NEW VERSION =====
    $newMinor = $minor + 1
    $newPatch = 0
    $newVersion = "$major.$newMinor.$newPatch"
    
    # ===== SUMMARY =====
    Write-Header "Release Summary"
    Write-Host "Current version tag: $latestTag"
    Write-Host "New version:         $newVersion"
    Write-Host "Merged PRs:"
    if ($prList.Count -gt 0) {
        $prList | ForEach-Object {
            Write-Host "- $($_.title) #$($_.number)"
        }
    }
    else {
        Write-Host "  (none)" -ForegroundColor Yellow
    }
    Write-Host ""
    
    # ===== CONFIRMATION =====
    Write-Header "Proceed with Release?"
    $confirmation = Read-Host "Update template version to $newVersion and publish release to GitHub? (yes/no)"
    
    if ($confirmation -ne "yes") {
        Write-Host "Release cancelled by user." -ForegroundColor Yellow
        exit 0
    }
    
    # ===== UPDATE AZURE.YAML TEMPLATE VERSION =====
    Write-Header "Updating azure.yaml template version"
    
    $scriptDir = $PSScriptRoot
    $azureYamlPath = Join-Path $scriptDir ".." "azure.yaml"
    
    if (Test-Path $azureYamlPath) {
        $azureYamlContent = Get-Content $azureYamlPath -Raw
        
        # Match template line with name@version pattern and capture the template name
        if ($azureYamlContent -match 'template:\s+(.+?)@[\d\.]+') {
            $templateName = $matches[1]
            $oldPattern = "template:\s+$([regex]::Escape($templateName))@[\d\.]+"
            $newValue = "template: $templateName@$newVersion"
            
            $updatedContent = $azureYamlContent -replace $oldPattern, $newValue
            Set-Content -Path $azureYamlPath -Value $updatedContent -NoNewline
            
            Write-Success "Updated template version to $newVersion in azure.yaml"
            
            # Commit the change
            git add $azureYamlPath
            git commit -m "Update template version to $newVersion"
            Write-Success "Committed azure.yaml changes"
        }
        else {
            Write-Host "No template version found in azure.yaml - skipping update" -ForegroundColor Yellow
        }
    }
    else {
        Write-Host "azure.yaml not found - skipping update" -ForegroundColor Yellow
    }
    
    # ===== CREATE AND PUSH TAG =====
    Write-Header "Creating and pushing tag"
    git tag $newVersion
    Write-Success "Tag $newVersion created"
    
    git push origin $newVersion
    Write-Success "Tag $newVersion pushed to GitHub"
    
    # ===== CREATE RELEASE NOTES =====
    Write-Header "Creating release"
    $releaseNotes = "# Changes`n`n"
    if ($prList.Count -gt 0) {
        $prList | ForEach-Object {
            $releaseNotes += "- $($_.title) #$($_.number)`n"
        }
    }
    else {
        $releaseNotes += "No changes`n"
    }
    
    # ===== CREATE GITHUB RELEASE =====
    gh release create $newVersion `
        --title $newVersion `
        --notes $releaseNotes `
        --target main `
        --latest
    
    Write-Success "Release $newVersion created successfully!"
    Write-Host ""
    
}
catch {
    Write-Error "Script execution failed: $_"
    exit 1
}
