Write-Host "Running Scripts/go.ps1..."
Write-Host "docker-compose down -v"
docker-compose down -v
Write-Host "docker-compose build --no-cache"
docker-compose build --no-cache
Write-Host "docker-compose up -d"
docker-compose up -d