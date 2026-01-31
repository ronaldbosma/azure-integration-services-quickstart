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
    $tagDate = git log -1 --format=%aI $latestTag
    Write-Success "Latest tag: $latestTag (date: $tagDate)"
    
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
    $mergedPRs = gh pr list --search "base:main merged:>$tagDate" --state merged --json number,title,mergedAt --limit 100
    
    if (-not $mergedPRs -or $mergedPRs -eq "[]") {
        Write-Host "No PRs found merged after $latestTag (date: $tagDate)" -ForegroundColor Yellow
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
    
}
catch {
    Write-Error "Script execution failed: $_"
    exit 1
}
