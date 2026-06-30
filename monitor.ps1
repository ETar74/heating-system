# Monitor script - без эмодзи и кириллицы в строках
Write-Host "=== Database Monitor ===" -ForegroundColor Green

while ($true) {
    Clear-Host
    Write-Host "Time: $(Get-Date -Format 'HH:mm:ss')" -ForegroundColor Cyan
    Write-Host ""
    
    # Settings
    Write-Host "SETTINGS:" -ForegroundColor Yellow
    docker-compose exec postgres psql -U postgres -d heating_system -c "SELECT key, value FROM parameters WHERE key LIKE '%temp%' ORDER BY key;"
    
    Write-Host ""
    
    # Users
    Write-Host "USERS:" -ForegroundColor Yellow
    docker-compose exec postgres psql -U postgres -d heating_system -c "SELECT username, role_id FROM users;"
    
    Write-Host ""
    
    # Recent events
    Write-Host "RECENT EVENTS:" -ForegroundColor Yellow
    docker-compose exec postgres psql -U postgres -d heating_system -c "SELECT ""eventType"", message, ""createdAt"" FROM events ORDER BY ""createdAt"" DESC LIMIT 5;"
    
    Write-Host ""
    Write-Host "Refresh in 5 seconds..." -ForegroundColor Gray
    
    Start-Sleep -Seconds 5
}