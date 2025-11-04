Write-Host "Running Scripts/geterror.ps1..."
Write-Host 'docker logs gocd-server 2>&1 | Select-String -Pattern "(ERROR|Exception|failed|STDERR)" -CaseSensitive:$false -Context 3,5'
docker logs gocd-server 2>&1 | Select-String -Pattern "(ERROR|Exception|failed|STDERR)" -CaseSensitive:$false -Context 3,5