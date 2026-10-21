#Requires -Version 5.1
$ErrorActionPreference = 'SilentlyContinue'

Write-Host 'Stopping JEAP...' -ForegroundColor Cyan

Get-NetTCPConnection -LocalPort 8080 -State Listen |
    ForEach-Object { Stop-Process -Id $_.OwningProcess -Force }

Get-CimInstance Win32_Process -Filter "Name='cloudflared.exe'" |
    Where-Object { $_.CommandLine -match 'jeap\.store' } |
    ForEach-Object { Stop-Process -Id $_.ProcessId -Force }

Write-Host 'JEAP local server and tunnel stopped. https://jeap.store will be down until you start it again.' -ForegroundColor Green
