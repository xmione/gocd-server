Write-Host "Running Scripts/go.ps1..."

# --- KEYSTORE GENERATION BLOCK ---
Write-Host "Generating PKCS12 keystore for GoCD server..."
 $certsDir = Join-Path $PSScriptRoot "..\certs"
 $keystorePath = Join-Path $certsDir "keystore.p12"

# Use openssl on the host machine to create the keystore
& openssl pkcs12 -export `
    -in "$certsDir\server.crt" `
    -inkey "$certsDir\server.key" `
    -out "$keystorePath" `
    -name gocd-server `
    -password pass:changeit

Write-Host "✅ Keystore generated at $keystorePath"
# --- END OF KEYSTORE GENERATION BLOCK ---

if (-Not (Test-Path "./certs/ca.crt")) {
    Write-Host "Certificates not found. Generating..."
    Scripts/generate-certs.ps1
}

Write-Host "Stopping and removing containers and volumes..."
docker-compose down -v

# --- IMAGE REMOVAL BLOCK ---
Write-Host "Force removing all containers..."
docker container rm -f $(docker container ls -aq) 2>$null

# Specifically target the mail-test container if it still exists
 $mailTestContainer = docker container ls -q -f name=mail-test 2>$null
if ($mailTestContainer) {
    Write-Host "Force removing mail-test container..."
    docker container rm -f $mailTestContainer 2>$null
}

Write-Host "Force removing all images..."
docker image rm -f $(docker image ls -aq) 2>$null

# Specifically target the analogic/poste.io image if it still exists
 $posteImage = docker image ls -q analogic/poste.io 2>$null
if ($posteImage) {
    Write-Host "Force removing analogic/poste.io image..."
    docker image rm -f $posteImage 2>$null
}

Write-Host "Removing all volumes..."
docker volume rm -f $(docker volume ls -q) 2>$null

Write-Host "Performing complete system cleanup..."
docker system prune -a --volumes -f
# --- END OF IMAGE REMOVAL BLOCK ---

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

Write-Host "✅ SUCCESS: GoCD environment is up. Agent is connected." -ForegroundColor Green
exit 0