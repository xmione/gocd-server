<#
.SYNOPSIS
    Builds and pushes the SolVPN build base image to ghcr.io.

.DESCRIPTION
    This script tags the existing gocd-agent-3 image as the SolVPN build base
    image and pushes it to GitHub Container Registry (ghcr.io).
    
    Run this script once after cloning the gocd-server repo, before running
    npm run menu option 1.6 for the first time. After this, option 1.6 will
    pull the pre-built base image instead of compiling OpenSSL from scratch.

.EXAMPLE
    .\Scripts\setup-base-image.ps1

.NOTES
    File Name    : setup-base-image.ps1
    Purpose      : One-time setup to push the SolVPN build base image to ghcr.io
    Author       : Solomio S. Sisante
    Created      : April 24, 2026

    Requirements:
        - Docker must be running
        - GITHUB_TOKEN must be set in .env.docker
        - GITHUB_TOKEN must have write:packages scope

    To run:
        From the gocd-server root folder:
            .\Scripts\setup-base-image.ps1
#>

# Enable TLS12 for secure downloads
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12

# Log file path
$logFileName = "setup-base-image_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"
Start-Transcript -Path $logFileName -Append

function LogMessage {
    param ([string]$message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Host "$timestamp - $message"
}

function ExitWithError {
    param ([string]$message)
    LogMessage "ERROR: $message"
    Stop-Transcript
    exit 1
}

LogMessage "========================================================"
LogMessage "SolVPN Build Base Image Setup"
LogMessage "========================================================"

# --- STEP 1: Load GITHUB_TOKEN from .env.docker ---
$envFile = Join-Path $PSScriptRoot "..\\.env.docker"
if (-not (Test-Path $envFile)) {
    ExitWithError ".env.docker not found. Please create it first."
}

LogMessage "Loading environment variables from .env.docker..."
$githubToken = $null
$githubUsername = $null

Get-Content $envFile | ForEach-Object {
    if ($_ -match "^GITHUB_TOKEN=(.+)$") {
        $script:githubToken = $matches[1].Trim()
    }
    if ($_ -match "^GIT_REPO_USERNAME=(.+)$") {
        $script:githubUsername = $matches[1].Trim()
    }
}

if ([string]::IsNullOrWhiteSpace($githubToken)) {
    ExitWithError "GITHUB_TOKEN not found in .env.docker."
}
if ([string]::IsNullOrWhiteSpace($githubUsername)) {
    ExitWithError "GIT_REPO_USERNAME not found in .env.docker."
}

LogMessage "GitHub username: $githubUsername"

# --- STEP 2: Check Docker is running ---
LogMessage "Checking Docker is running..."
try {
    docker info | Out-Null
    LogMessage "Docker is running."
} catch {
    ExitWithError "Docker is not running. Please start Docker Desktop first."
}

# --- STEP 3: Build the base image if it doesn't exist locally ---
$baseImageName = "gocd-server-gocd-agent-3"
$targetImage = "ghcr.io/$githubUsername/solvpn-build-base:latest"

LogMessage "Checking for existing local image: $baseImageName..."
$existingImage = docker images $baseImageName --format "{{.Repository}}" 2>$null

if ([string]::IsNullOrWhiteSpace($existingImage)) {
    LogMessage "Local image not found. Building from Dockerfile.agent.solvpn.base..."
    $dockerfilePath = Join-Path $PSScriptRoot "..\Dockerfile.agent.solvpn.base"
    
    if (-not (Test-Path $dockerfilePath)) {
        ExitWithError "Dockerfile.agent.solvpn.base not found at $dockerfilePath"
    }

    $buildContext = Join-Path $PSScriptRoot ".."
    docker build -t $baseImageName -f $dockerfilePath $buildContext
    
    if ($LASTEXITCODE -ne 0) {
        ExitWithError "Docker build failed."
    }
    LogMessage "Base image built successfully."
} else {
    LogMessage "Found existing local image: $baseImageName"
}

# --- STEP 4: Tag the image ---
LogMessage "Tagging image as: $targetImage"
docker tag $baseImageName $targetImage

if ($LASTEXITCODE -ne 0) {
    ExitWithError "Failed to tag image."
}
LogMessage "Image tagged successfully."

# --- STEP 5: Login to ghcr.io ---
LogMessage "Logging in to ghcr.io..."
$githubToken | docker login ghcr.io -u $githubUsername --password-stdin

if ($LASTEXITCODE -ne 0) {
    ExitWithError "Failed to login to ghcr.io. Check your GITHUB_TOKEN has write:packages scope."
}
LogMessage "Logged in to ghcr.io successfully."

# --- STEP 6: Push the image ---
LogMessage "Pushing image to ghcr.io: $targetImage"
docker push $targetImage

if ($LASTEXITCODE -ne 0) {
    ExitWithError "Failed to push image to ghcr.io."
}

LogMessage "========================================================"
LogMessage "Base image pushed successfully!"
LogMessage "Image: $targetImage"
LogMessage ""
LogMessage "You can now run npm run menu option 1.6."
LogMessage "gocd-agent-3 will pull this pre-built image instead"
LogMessage "of compiling OpenSSL from scratch every time."
LogMessage "========================================================"

Stop-Transcript