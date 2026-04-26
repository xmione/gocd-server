<#
.SYNOPSIS
    Sync the master branch to be an exact copy of a feature branch, in a single commit.
.DESCRIPTION
    This script performs a destructive but controlled sync of 'master' to match a feature branch.
    It follows the procedure described in the accompanying Markdown document.
    All steps require explicit user confirmation before execution.
.PARAMETER FeatureBranch
    The name of the feature branch that will become the new state of 'master'.
    This parameter is mandatory.
.EXAMPLE
    .\master-feature-git-sync.ps1 -FeatureBranch "my-feature"
#>

param(
    [string]$FeatureBranch
)

# ---- Mandatory parameter check ----
if ([string]::IsNullOrWhiteSpace($FeatureBranch)) {
    Write-Host "ERROR: FeatureBranch parameter is required." -ForegroundColor Red
    Write-Host "Usage: .\master-feature-git-sync.ps1 -FeatureBranch <branch-name>" -ForegroundColor Yellow
    exit 1
}

# ---- Helper functions ----
function Write-Step {
    param([string]$Title, [string]$Content)
    Write-Host "`n=== $Title ===" -ForegroundColor Cyan
    Write-Host $Content -ForegroundColor White
}

function Confirm-Action {
    param([string]$Prompt, [switch]$Critical)
    $default = if ($Critical) { "n" } else { "y" }
    $choice = Read-Host "$Prompt (y/n, default=$default)"
    if ([string]::IsNullOrWhiteSpace($choice)) { $choice = $default }
    return ($choice -eq 'y' -or $choice -eq 'Y')
}

# ---- Prerequisites ----
Write-Step "PREREQUISITES" @"
- You have a feature branch named '$FeatureBranch' pushed to the remote.
- You have the latest changes locally.
Running this script will perform the following on your local repository.
"@

if (-not (Confirm-Action "Do you want to continue?")) { exit }

# Check Git availability
try { git --version | Out-Null }
catch { Write-Host "Git is not installed or not in PATH." -ForegroundColor Red; exit 1 }

# Fetch latest from remote
Write-Host "Fetching latest changes from origin..." -ForegroundColor Gray
git fetch origin

# ---- Step 1: Switch to master ----
Write-Step "STEP 1: SWITCH TO MASTER" "Ensure you are on the master branch."
if (-not (Confirm-Action "Switch to master now?")) { exit }
git checkout master
if ($LASTEXITCODE -ne 0) { Write-Host "Failed to switch to master." -ForegroundColor Red; exit }

# ---- Step 2 (Optional): Clean up previous commits ----
Write-Step "STEP 2 (OPTIONAL): CLEAN UP MASTER" @"
If you have incorrect commits on master (e.g., from a failed merge), you may reset them.
WARNING: This is destructive and permanent.
Example: resetting the last 2 commits.
"@
if (Confirm-Action "Do you want to perform a hard reset on master? (See note above)") {
    $count = Read-Host "How many commits to remove (e.g., 2)? (0 to skip)"
    if ($count -match '^\d+$' -and [int]$count -gt 0) {
        if (Confirm-Action "Reset --hard HEAD~$count ? This discards commits and changes." -Critical) {
            git reset --hard "HEAD~$count"
        }
    }
}

# ---- Step 3: Stage the feature branch tree ----
Write-Step "STEP 3: STAGE FEATURE BRANCH CONTENTS" @"
Replaces the staging area and working directory with the exact file tree from '$FeatureBranch'.
No commit is created yet.
Command: git read-tree -u --reset $FeatureBranch
"@
if (-not (Confirm-Action "Proceed with git read-tree?")) { exit }
git read-tree -u --reset $FeatureBranch
if ($LASTEXITCODE -ne 0) { Write-Host "read-tree failed." -ForegroundColor Red; exit }

# ---- Step 4: Commit the changes ----
Write-Step "STEP 4: COMMIT ON MASTER" "Create a commit that makes master exactly match the feature branch."
$commitMsg = Read-Host "Commit message" "Sync master with $FeatureBranch branch"
if ([string]::IsNullOrWhiteSpace($commitMsg)) { $commitMsg = "Sync master with $FeatureBranch branch" }
git commit -m $commitMsg
if ($LASTEXITCODE -ne 0) { Write-Host "Commit failed." -ForegroundColor Red; exit }

# ---- Step 5: Force push ----
Write-Step "STEP 5: FORCE PUSH WITH --FORCE-WITH-LEASE" @"
Because local master history now diverges from remote, a normal push is rejected.
Using '--force-with-lease' is safer than '--force'.
"@
if (-not (Confirm-Action "Force push to origin master?" -Critical)) { exit }
git push origin master --force-with-lease
if ($LASTEXITCODE -ne 0) { Write-Host "Force push failed." -ForegroundColor Red; exit }

# ---- Verification ----
Write-Step "VERIFICATION" "Check that master and $FeatureBranch are now identical."
git diff --name-status "master..$FeatureBranch"
if ($LASTEXITCODE -eq 0) {
    Write-Host "No differences found – sync successful." -ForegroundColor Green
} else {
    Write-Host "Differences exist – verify manually." -ForegroundColor Yellow
}