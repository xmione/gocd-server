# Scripts/go.ps1

Write-Host "Running Scripts/go.ps1..."
Write-Host "Stopping and removing containers..."
docker-compose down

Write-Host "Forcefully removing the corrupted Docker volume by name..."
docker volume rm gocd-server_gocd_data

Write-Host "Rebuilding the image from scratch..."
docker-compose build --no-cache

Write-Host "Starting the container with a clean state..."
docker-compose up -d