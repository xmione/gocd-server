# GoCD Management Menu Script
# This script provides a menu-driven interface for managing GoCD server and agent containers.
# It allows users to start, stop, and manage the GoCD environment.
# Ensure you have Docker and Docker Compose installed and running before using this script.
# Usage: Run this script in PowerShell to display the GoCD management menu.

do {
    Clear-Host
    Write-Host "GoCD Management Menu" -ForegroundColor Green
    Write-Host "====================" -ForegroundColor Green
    Write-Host ""
    Write-Host "1. CONTAINER MANAGEMENT" -ForegroundColor Cyan
    Write-Host "   1.1. Recreate Docker containers" -ForegroundColor White
    Write-Host "   1.2. Get Docker container errors" -ForegroundColor White
    Write-Host "   1.3. Validate GoCD environment" -ForegroundColor White
    Write-Host "   1.4. View container logs" -ForegroundColor White
    Write-Host "   1.5. Stop all containers" -ForegroundColor White
    Write-Host ""
    Write-Host "2. PIPELINE MANAGEMENT" -ForegroundColor Cyan
    Write-Host "   2.1. Trigger badminton_court pipeline" -ForegroundColor White
    Write-Host "   2.2. View pipeline history" -ForegroundColor White
    Write-Host "   2.3. Unlock pipeline" -ForegroundColor White
    Write-Host ""
    Write-Host "3. AGENT MANAGEMENT" -ForegroundColor Cyan
    Write-Host "   3.1. View agent status" -ForegroundColor White
    Write-Host "   3.2. Enable agent" -ForegroundColor White
    Write-Host "   3.3. Disable agent" -ForegroundColor White
    Write-Host ""
    Write-Host "4. SYSTEM UTILITIES" -ForegroundColor Cyan
    Write-Host "   4.1. Open GoCD web interface" -ForegroundColor White
    Write-Host "   4.2. View system resources" -ForegroundColor White
    Write-Host "   4.3. Clean up Docker resources" -ForegroundColor White
    Write-Host ""
    Write-Host "5. Exit" -ForegroundColor Red
    Write-Host ""

    $choice = Read-Host "Select an option (e.g., 1.1, 2.3, or 5)"

    switch ($choice) {
        # Container Management
        "1.1" { 
            npm run go
            Write-Host "Press Enter to continue..." -ForegroundColor Yellow
            Read-Host
        }
        "1.2" { 
            npm run geterror
            Write-Host "Press Enter to continue..." -ForegroundColor Yellow
            Read-Host
        }
        "1.3" { 
            npm run validate
            Write-Host "Press Enter to continue..." -ForegroundColor Yellow
            Read-Host
        }
        "1.4" { 
            $container = Read-Host "Enter container name (gocd-server/gocd-agent)"
            if ($container -eq "gocd-server" -or $container -eq "gocd-agent") {
                docker logs -f $container
            } else {
                Write-Host "Invalid container name. Please use 'gocd-server' or 'gocd-agent'." -ForegroundColor Red
            }
            Write-Host "Press Enter to continue..." -ForegroundColor Yellow
            Read-Host
        }
        "1.5" { 
            Write-Host "Stopping all GoCD containers..." -ForegroundColor Yellow
            docker-compose down
            Write-Host "All containers stopped." -ForegroundColor Green
            Write-Host "Press Enter to continue..." -ForegroundColor Yellow
            Read-Host
        }
        
        # Pipeline Management
        "2.1" { 
            $pipeline = Read-Host "Enter pipeline name (default: badminton_court)"
            if ([string]::IsNullOrWhiteSpace($pipeline)) {
                $pipeline = "badminton_court"
            }
            Write-Host "Triggering pipeline: $pipeline" -ForegroundColor Yellow
            try {
                $response = Invoke-WebRequest -Uri "http://localhost:8153/go/api/pipelines/$pipeline/schedule" -Method POST -Headers @{"Confirm"="true"} -ErrorAction Stop
                Write-Host "Pipeline triggered successfully." -ForegroundColor Green
            } catch {
                Write-Host "Failed to trigger pipeline: $_" -ForegroundColor Red
            }
            Write-Host "Press Enter to continue..." -ForegroundColor Yellow
            Read-Host
        }
        "2.2" { 
            $pipeline = Read-Host "Enter pipeline name (default: badminton_court)"
            if ([string]::IsNullOrWhiteSpace($pipeline)) {
                $pipeline = "badminton_court"
            }
            Write-Host "Opening pipeline history for: $pipeline" -ForegroundColor Yellow
            Start-Process "http://localhost:8153/go/pipelines/$pipeline"
            Write-Host "Press Enter to continue..." -ForegroundColor Yellow
            Read-Host
        }
        "2.3" { 
            $pipeline = Read-Host "Enter pipeline name (default: badminton_court)"
            if ([string]::IsNullOrWhiteSpace($pipeline)) {
                $pipeline = "badminton_court"
            }
            Write-Host "Unlocking pipeline: $pipeline" -ForegroundColor Yellow
            try {
                $response = Invoke-WebRequest -Uri "http://localhost:8153/go/api/pipelines/$pipeline/unlock" -Method POST -Headers @{"Confirm"="true"} -ErrorAction Stop
                Write-Host "Pipeline unlocked successfully." -ForegroundColor Green
            } catch {
                Write-Host "Failed to unlock pipeline: $_" -ForegroundColor Red
            }
            Write-Host "Press Enter to continue..." -ForegroundColor Yellow
            Read-Host
        }
        
        # Agent Management
        "3.1" { 
            Write-Host "Agent status:" -ForegroundColor Yellow
            try {
                $response = Invoke-WebRequest -Uri "http://localhost:8153/go/api/agents" -UseBasicParsing | ConvertFrom-Json
                $response | Select-Object hostname, agent_state, build_state | Format-Table
            } catch {
                Write-Host "Failed to get agent status: $_" -ForegroundColor Red
            }
            Write-Host "Press Enter to continue..." -ForegroundColor Yellow
            Read-Host
        }
        "3.2" { 
            $agent = Read-Host "Enter agent UUID (leave blank for agent-1)"
            if ([string]::IsNullOrWhiteSpace($agent)) {
                $agent = "agent-1"
            }
            Write-Host "Enabling agent: $agent" -ForegroundColor Yellow
            try {
                $body = '{"agent_state":"Enabled"}' | ConvertTo-Json
                $response = Invoke-WebRequest -Uri "http://localhost:8153/go/api/agents/$agent" -Method PATCH -Body $body -ContentType "application/json" -Headers @{"Accept"="application/vnd.go.cd.v1+json"} -ErrorAction Stop
                Write-Host "Agent enabled successfully." -ForegroundColor Green
            } catch {
                Write-Host "Failed to enable agent: $_" -ForegroundColor Red
            }
            Write-Host "Press Enter to continue..." -ForegroundColor Yellow
            Read-Host
        }
        "3.3" { 
            $agent = Read-Host "Enter agent UUID (leave blank for agent-1)"
            if ([string]::IsNullOrWhiteSpace($agent)) {
                $agent = "agent-1"
            }
            Write-Host "Disabling agent: $agent" -ForegroundColor Yellow
            try {
                $body = '{"agent_state":"Disabled"}' | ConvertTo-Json
                $response = Invoke-WebRequest -Uri "http://localhost:8153/go/api/agents/$agent" -Method PATCH -Body $body -ContentType "application/json" -Headers @{"Accept"="application/vnd.go.cd.v1+json"} -ErrorAction Stop
                Write-Host "Agent disabled successfully." -ForegroundColor Green
            } catch {
                Write-Host "Failed to disable agent: $_" -ForegroundColor Red
            }
            Write-Host "Press Enter to continue..." -ForegroundColor Yellow
            Read-Host
        }
        
        # System Utilities
        "4.1" { 
            Write-Host "Opening GoCD web interface..." -ForegroundColor Yellow
            Start-Process "http://localhost:8153/go"
            Write-Host "Press Enter to continue..." -ForegroundColor Yellow
            Read-Host
        }
        "4.2" { 
            Write-Host "System resources:" -ForegroundColor Yellow
            docker stats --no-stream
            Write-Host "Press Enter to continue..." -ForegroundColor Yellow
            Read-Host
        }
        "4.3" { 
            Write-Host "Cleaning up Docker resources..." -ForegroundColor Yellow
            docker system prune -f
            Write-Host "Cleanup completed." -ForegroundColor Green
            Write-Host "Press Enter to continue..." -ForegroundColor Yellow
            Read-Host
        }
        
        "5" { 
            Write-Host "Exiting..." -ForegroundColor Green
            exit
        }
        default { 
            Write-Host "Invalid option. Press Enter to continue..." -ForegroundColor Red
            Read-Host
        }
    }
} while ($choice -ne "5")