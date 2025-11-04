Write-Host "Running Scripts/go.ps1..."

if (-Not (Test-Path "./certs/ca.crt")) {
    Write-Host "Certificates not found. Generating..."
    Scripts/generate-certs.ps1
}

Write-Host "Stopping and removing containers and volumes..."
docker-compose down -v

Write-Host "Rebuilding the image from scratch..."
docker-compose build --no-cache

Write-Host "Starting the container with a clean state..."
docker-compose up -d
