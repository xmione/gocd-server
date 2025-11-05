Write-Host "Running Scripts/geterror.ps1..."
Write-Host "gocd-server container errors:"
docker logs gocd-server 2>&1 | Select-String -Pattern "(ERROR|Exception|failed|STDERR)" -CaseSensitive:$false -Context 3,5

Write-Host "gocd-agent container errors:"
docker logs gocd-agent 2>&1 | Select-String -Pattern "(ERROR|Exception|failed|STDERR)" -CaseSensitive:$false -Context 3,5