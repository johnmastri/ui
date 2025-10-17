# MastrCtrl Complete Release Workflow with GitHub CLI
# Automates the entire release process from build to GitHub

param(
    [Parameter(Mandatory=$true)]
    [string]$Version,
    
    [string]$GitHubRepo = "johnmastri/ui",
    [string]$ReleaseDir = "./release",
    [switch]$SkipBuild = $false,
    [switch]$Draft = $false
)

Write-Host "=" * 70 -ForegroundColor Cyan
Write-Host "MastrCtrl Complete Release Workflow" -ForegroundColor Cyan
Write-Host "=" * 70 -ForegroundColor Cyan
Write-Host ""

# Validate version format
if ($Version -notmatch '^\d+\.\d+\.\d+$') {
    Write-Host "Error: Invalid version format. Use X.Y.Z (e.g., 1.0.0)" -ForegroundColor Red
    exit 1
}

Write-Host "Configuration:" -ForegroundColor Yellow
Write-Host "  Version: v$Version"
Write-Host "  GitHub Repo: $GitHubRepo"
Write-Host "  Release Directory: $ReleaseDir"
Write-Host "  Skip Build: $SkipBuild"
Write-Host "  Draft Release: $Draft"
Write-Host ""

# Check if gh CLI is installed
$ghInstalled = Get-Command gh -ErrorAction SilentlyContinue
if (-not $ghInstalled) {
    Write-Host "Error: GitHub CLI (gh) is not installed" -ForegroundColor Red
    Write-Host "Install it with: winget install --id GitHub.cli" -ForegroundColor Yellow
    exit 1
}

Write-Host "GitHub CLI: Installed OK" -ForegroundColor Green

# Check authentication
Write-Host "Checking GitHub authentication..." -ForegroundColor Yellow
$authStatus = gh auth status 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "  You are not authenticated with GitHub" -ForegroundColor Red
    Write-Host ""
    Write-Host "  Please authenticate with GitHub CLI:" -ForegroundColor Yellow
    Write-Host "  1. Run: gh auth login" -ForegroundColor Cyan
    Write-Host "  2. Choose 'GitHub.com'" -ForegroundColor Cyan
    Write-Host "  3. Choose 'HTTPS'" -ForegroundColor Cyan
    Write-Host "  4. Choose 'Login with a web browser'" -ForegroundColor Cyan
    Write-Host "  5. Follow the authentication flow" -ForegroundColor Cyan
    Write-Host ""
    $response = Read-Host "Authenticate now? [y/n]"
    if ($response -eq 'y') {
        gh auth login
        if ($LASTEXITCODE -ne 0) {
            Write-Host "Authentication failed" -ForegroundColor Red
            exit 1
        }
    } else {
        exit 1
    }
}

Write-Host "GitHub Authentication: OK" -ForegroundColor Green
Write-Host ""

# Step 1: Run create_release.ps1 to build packages
Write-Host "=" * 70 -ForegroundColor Cyan
Write-Host "Step 1: Building Release Packages" -ForegroundColor Cyan
Write-Host "=" * 70 -ForegroundColor Cyan
Write-Host ""

$buildParams = @{
    Version = $Version
    GitHubRepo = $GitHubRepo
    ReleaseDir = $ReleaseDir
}

if ($SkipBuild) {
    $buildParams.SkipBuild = $true
}

& "$PSScriptRoot\create_release.ps1" @buildParams

if ($LASTEXITCODE -ne 0) {
    Write-Host "Build failed" -ForegroundColor Red
    exit 1
}

# Step 2: Check if tag already exists
Write-Host ""
Write-Host "=" * 70 -ForegroundColor Cyan
Write-Host "Step 2: Checking Git Status" -ForegroundColor Cyan
Write-Host "=" * 70 -ForegroundColor Cyan
Write-Host ""

# Navigate to the git repository (package directory)
$gitRoot = "$PSScriptRoot/.."
Push-Location $gitRoot

Write-Host "Git repository: $gitRoot" -ForegroundColor Cyan
Write-Host ""

$tagExists = git tag -l "v$Version"
if ($tagExists) {
    Write-Host "Warning: Tag v$Version already exists locally" -ForegroundColor Yellow
    $response = Read-Host "Delete and recreate? [y/n]"
    if ($response -eq 'y') {
        git tag -d "v$Version"
        Write-Host "  Deleted local tag" -ForegroundColor Green
    } else {
        Write-Host "Cancelled" -ForegroundColor Red
        exit 1
    }
}

# Step 3: Create git tag
Write-Host "Creating git tag v$Version..." -ForegroundColor Yellow
git tag -a "v$Version" -m "Release v$Version"

if ($LASTEXITCODE -ne 0) {
    Write-Host "Failed to create git tag" -ForegroundColor Red
    exit 1
}

Write-Host "  Git tag created OK" -ForegroundColor Green

# Step 4: Push tag to GitHub
Write-Host "Pushing tag to GitHub..." -ForegroundColor Yellow
git push origin "v$Version"

if ($LASTEXITCODE -ne 0) {
    Write-Host "Failed to push tag" -ForegroundColor Red
    Write-Host "  Note: You may need to push to the correct remote" -ForegroundColor Yellow
    exit 1
}

Write-Host "  Tag pushed to GitHub OK" -ForegroundColor Green

# Step 5: Load CHANGELOG for release notes
$releaseNotes = "Release v$Version"
$changelogFile = "../CHANGELOG.md"
if (Test-Path $changelogFile) {
    Write-Host "Loading changelog..." -ForegroundColor Yellow
    $changelogContent = Get-Content $changelogFile -Raw
    
    # Extract the section for this version
    $pattern = "## \[$Version\].*?(?=## \[|\z)"
    if ($changelogContent -match $pattern) {
        $releaseNotes = $matches[0]
        Write-Host "  Changelog loaded OK" -ForegroundColor Green
    } else {
        $releaseNotes = "Release v$Version`n`nChanges:`n* See git history for changes`n`nInstallation:`nDownload the appropriate files and follow the installation guide.`n`nUpdate from Hardware UI:`n1. Settings - Device - System Update`n2. Check for Updates`n3. Select components to update`n4. Download and Install"
        Write-Host "  Using default release notes" -ForegroundColor Yellow
    }
}

# Step 6: Verify release files exist
Write-Host ""
Write-Host "=" * 70 -ForegroundColor Cyan
Write-Host "Step 3: Verifying Release Files" -ForegroundColor Cyan
Write-Host "=" * 70 -ForegroundColor Cyan
Write-Host ""

# Convert to absolute path if relative
if (-not [System.IO.Path]::IsPathRooted($ReleaseDir)) {
    $ReleaseDir = [System.IO.Path]::GetFullPath((Join-Path "$PSScriptRoot" $ReleaseDir))
}

$releaseFiles = @(
    "$ReleaseDir/ui-v$Version.zip",
    "$ReleaseDir/server-v$Version.zip",
    "$ReleaseDir/manifest.json"
)

# Optional firmware file
$firmwareFile = "$ReleaseDir/firmware-v$Version.bin"

$allFilesExist = $true
foreach ($file in $releaseFiles) {
    if (Test-Path $file) {
        $size = (Get-Item $file).Length
        $sizeStr = if ($size -gt 1MB) {
            "$([math]::Round($size / 1MB, 2)) MB"
        } else {
            "$([math]::Round($size / 1KB, 2)) KB"
        }
        Write-Host "  [OK] $file ($sizeStr)" -ForegroundColor Green
    } else {
        Write-Host "  [MISSING] $file" -ForegroundColor Red
        $allFilesExist = $false
    }
}

if (Test-Path $firmwareFile) {
    $size = (Get-Item $firmwareFile).Length
    $sizeKB = [math]::Round($size / 1KB, 2)
    Write-Host "  Firmware: $firmwareFile ($sizeKB KB)" -ForegroundColor Green
    $releaseFiles += $firmwareFile
} else {
    Write-Host "  Firmware file optional, not found" -ForegroundColor Yellow
}

if (-not $allFilesExist) {
    Write-Host ""
    Write-Host "Some required files are missing. Aborting." -ForegroundColor Red
    exit 1
}

# Step 7: Create GitHub Release
Write-Host ""
Write-Host "=" * 70 -ForegroundColor Cyan
Write-Host "Step 4: Creating GitHub Release" -ForegroundColor Cyan
Write-Host "=" * 70 -ForegroundColor Cyan
Write-Host ""

$ghArgs = @(
    "release", "create", "v$Version",
    "--repo", $GitHubRepo,
    "--title", "v$Version",
    "--notes", $releaseNotes
)

if ($Draft) {
    $ghArgs += "--draft"
    Write-Host "Creating DRAFT release..." -ForegroundColor Yellow
} else {
    Write-Host "Creating PUBLIC release..." -ForegroundColor Yellow
}

# Add all release files
$ghArgs += $releaseFiles

Write-Host ""
Write-Host "Executing: gh $($ghArgs -join ' ')" -ForegroundColor Cyan
Write-Host ""

gh @ghArgs

if ($LASTEXITCODE -ne 0) {
    Write-Host ""
    Write-Host "Failed to create GitHub release" -ForegroundColor Red
    Write-Host "  You may need to delete the tag and try again:" -ForegroundColor Yellow
    Write-Host "  git tag -d v$Version" -ForegroundColor Cyan
    Write-Host "  git push origin :refs/tags/v$Version" -ForegroundColor Cyan
    exit 1
}

# Success!
Write-Host ""
Write-Host "=" * 70 -ForegroundColor Green
Write-Host "Release Created Successfully!" -ForegroundColor Green
Write-Host "=" * 70 -ForegroundColor Green
Write-Host ""
Write-Host "Release URL: https://github.com/$GitHubRepo/releases/tag/v$Version" -ForegroundColor Cyan
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "  1. View release: gh release view v$Version --repo $GitHubRepo"
Write-Host "  2. Test update: From Pi hardware UI - Settings - Device - System Update"
Write-Host "  3. Verify manifest: https://github.com/$GitHubRepo/releases/download/v$Version/manifest.json"
Write-Host ""
Write-Host "Update Manager will check:" -ForegroundColor Yellow
$manifestUrl = "https://github.com/$GitHubRepo/releases/latest/download/manifest.json"
Write-Host "  $manifestUrl"
Write-Host ""

# Return to original directory
Pop-Location

