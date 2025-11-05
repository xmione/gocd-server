Write-Host "Running Scripts/validate.ps1..."
Write-Host "Executing validation script inside the gocd-server container..."

docker exec gocd-server /bin/bash /usr/local/bin/validate.sh