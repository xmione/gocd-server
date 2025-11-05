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

# --- AUTOMATED VALIDATION BLOCK ---

Write-Host "Waiting for GoCD server to be ready..."
 $serverUrl = "http://localhost:8153/go/api/v1/health"
 $retryInterval = 10
 $i = 1

while ($true) {
    try {
        $response = Invoke-WebRequest -Uri $serverUrl -UseBasicParsing -TimeoutSec 5
        if ($response.StatusCode -eq 200) {
            Write-Host "GoCD server is ready!"
            break
        }
    } catch {
        # Server is not up yet, ignore and retry
    }
    
    Write-Host "Attempt $($i): Server not ready, waiting $($retryInterval)s..."
    Start-Sleep -Seconds $retryInterval
    $i++
}

# --- INTELLIGENT AGENT WAIT BLOCK ---
Write-Host "Waiting for GoCD agent to register and be enabled..."
 $agentHostname = "agent-1"
 $agentRetryInterval = 10
 $i = 1

while ($true) {
    # Use docker exec with an environment variable to avoid quoting issues
    $agentState = docker exec -e AGENT_HOSTNAME="$agentHostname" gocd-server /bin/bash -c 'curl -s "http://localhost:8154/go/api/agents" | jq -r ".agents[] | select(.hostname==\"\$AGENT_HOSTNAME\") | .agent_config_state"'
    
    if ($agentState -eq "Enabled") {
        Write-Host "Agent '$($agentHostname)' is registered and enabled!"
        break
    }
    
    $displayState = if ($agentState) { $agentState } else { "Not Found" }
    Write-Host "Attempt $($i): Agent not ready (State: $($displayState)), waiting $($agentRetryInterval)s..."
    Start-Sleep -Seconds $agentRetryInterval
    $i++
}
# --- END OF INTELLIGENT AGENT WAIT BLOCK ---

Write-Host "Running validation script..."
Write-Host "====================================================================================" -ForegroundColor Yellow
docker exec gocd-server /bin/bash /usr/local/bin/validate.sh
Write-Host "====================================================================================" -ForegroundColor Yellow

# Check the exit code of the validation script
if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ SUCCESS: GoCD environment is up and validated." -ForegroundColor Green
} else {
    Write-Host "❌ FAILURE: GoCD environment validation failed. Check the logs above." -ForegroundColor Red
}

# Exit with the same code as the validation script
exit $LASTEXITCODE