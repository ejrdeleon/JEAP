#Requires -Version 5.1
$ErrorActionPreference = 'SilentlyContinue'

Write-Host 'Stopping JEAP...' -ForegroundColor Cyan

try {
    Get-NetTCPConnection -LocalPort 8080 -State Listen |
        ForEach-Object { Stop-Process -Id $_.OwningProcess -Force }
} catch {}

Get-CimInstance Win32_Process -Filter "Name='php.exe'" |
    Where-Object { $_.CommandLine -match 'artisan serve|--port=8080|-S 127\.0\.0\.1:8080' } |
    ForEach-Object { Stop-Process -Id $_.ProcessId -Force }

Get-CimInstance Win32_Process -Filter "Name='cloudflared.exe'" |
    ForEach-Object { Stop-Process -Id $_.ProcessId -Force }

Write-Host 'JEAP local server and tunnel stopped. https://jeap.store will be down until you start it again.' -ForegroundColor Green
