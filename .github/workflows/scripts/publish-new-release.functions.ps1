function Assert-HasChanges {
    <#
    .SYNOPSIS
        Checks if there are any changes since the last tag.
        Fails if no changes are found.
    #>
    
    Write-Host "Checking for changes since last tag"
    
    $latestTag = git describe --tags --abbrev=0 2>$null
    
    if (-not $latestTag) {
        Write-Host "No previous tags found. Proceeding with initial release."
        return
    }
    
    $changeCount = git rev-list "$latestTag..HEAD" --count
    
    if ($changeCount -eq 0) {
        throw "No changes found since tag $latestTag. Aborting release."
    }
    
    Write-Host "Found $changeCount commit(s) since $latestTag"
    Write-Host ""
}


function Get-NewVersion {
    <#
    .SYNOPSIS
        Determines the new version based on the latest tag and version bump type.
        If no tags are found, it starts with an initial version of 1.0.0.
    #>
    param(
        [Parameter(Mandatory=$true)]
        [ValidateSet("major", "minor", "patch")]
        [string]$VersionBump
    )
    
    Write-Host "Finding latest version tag"
    $latestTag = git describe --tags --abbrev=0 2>$null

    if (-not $latestTag) {
        $initialVersion = "1.0.0"
        Write-Host "No version tags found. Using initial version: $initialVersion"
        return $initialVersion
    }

    Write-Host "Latest tag: $latestTag"
    
    Write-Host "Parsing version from tag"
    # Handle tags with or without 'v' prefix
    $versionMatch = $latestTag -match '^v?(\d+)\.(\d+)\.(\d+)$'
    if (-not $versionMatch) {
        throw "Tag format does not match semantic versioning (v#.#.# or #.#.#). Found: $latestTag"
    }
    
    $major = [int]$matches[1]
    $minor = [int]$matches[2]
    $patch = [int]$matches[3]
    
    Write-Host "Current version: $major.$minor.$patch"

    Write-Host "Calculating new version"
    
    switch ($VersionBump) {
        "major" {
            $major = $major + 1
            $minor = 0
            $patch = 0
        }
        "minor" {
            $minor = $minor + 1
            $patch = 0
        }
        "patch" {
            $patch = $patch + 1
        }
    }
    
    $newVersion = "$major.$minor.$patch"
    
    Write-Host "New version will be: $newVersion"
    Write-Host ""
    
    return $newVersion
}


function Update-AzureYamlVersion {
    <#
    .SYNOPSIS
        Updates the azure.yaml template version
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$NewVersion
    )
    
    Write-Host "Updating azure.yaml template version"
    
    $azureYamlPath = "azure.yaml"
    
    if (Test-Path $azureYamlPath) {
        $azureYamlContent = Get-Content $azureYamlPath -Raw
        
        # Match template line with name@version pattern and capture the template name
        if ($azureYamlContent -match 'template:\s+(.+?)@[\d\.]+') {
            $templateName = $matches[1]
            $oldPattern = "template:\s+$([regex]::Escape($templateName))@[\d\.]+"
            $newValue = "template: $templateName@$NewVersion"
            
            $updatedContent = $azureYamlContent -replace $oldPattern, $newValue
            Set-Content -Path $azureYamlPath -Value $updatedContent -NoNewline
            
            Write-Host "Updated template version to $NewVersion in azure.yaml"
            
            # Commit the change
            git add $azureYamlPath
            git commit -m "Update template version to $NewVersion"
            Write-Host "Committed azure.yaml changes"

            Write-Host "Pushing changes to main branch"
            git push origin main --force
            Write-Host ""
        }
        else {
            throw "No template version found in azure.yaml"
        }
    }
    else {
        throw "azure.yaml not found"
    }
}


function Set-ReleaseTag {
    <#
    .SYNOPSIS
        Creates and pushes a new release tag
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$Tag
    )
    
    Write-Host "Creating and pushing tag"
    git tag $Tag
    Write-Host "Tag $Tag created"
    
    git push origin main
    git push origin $Tag
    Write-Host "Changes and tag $Tag pushed to GitHub"
    Write-Host ""
}


function New-GitHubRelease {
    <#
    .SYNOPSIS
        Publish a GitHub release with generated notes
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$Tag
    )
    
    Write-Host "Creating release"
    gh release create $Tag `
        --generate-notes `
        --target main `
        --latest
    
    Write-Host "Published release $Tag successfully!"
    Write-Host ""
}
