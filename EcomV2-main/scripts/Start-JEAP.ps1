#Requires -Version 5.1
param(
    [switch]$Build,
    [switch]$NoBrowser
)

$ErrorActionPreference = 'Stop'
$Root = Split-Path -Parent $PSScriptRoot
$Url = 'https://jeap.store'
$TunnelId = 'ec09becc-02ed-4c35-a948-c9046a6a2de1'
$Cloudflared = 'C:\Program Files (x86)\cloudflared\cloudflared.exe'
$TunnelConfig = Join-Path $env:USERPROFILE '.cloudflared\config.yml'
$EnvFile = Join-Path $Root '.env'
$LogDir = Join-Path $Root 'storage\logs'
$TunnelLog = Join-Path $LogDir 'cloudflared-jeap.log'

Set-Location $Root
New-Item -ItemType Directory -Force -Path $LogDir | Out-Null

function Write-Step([string]$Message) {
    Write-Host $Message -ForegroundColor Cyan
}

function Resolve-Php {
    $candidates = @()
    $fromPath = Get-Command php -ErrorAction SilentlyContinue
    if ($fromPath) { $candidates += $fromPath.Source }
    $candidates += 'C:\xampp\php\php.exe'
    $candidates += 'C:\php\php.exe'
    foreach ($candidate in $candidates) {
        if ($candidate -and (Test-Path -LiteralPath $candidate)) {
            return $candidate
        }
    }
    throw 'php is not on PATH. Install PHP or add C:\xampp\php to PATH.'
}

function Get-HttpStatus([string]$TargetUrl, [int]$TimeoutSec = 8) {
    $curl = Get-Command curl.exe -ErrorAction SilentlyContinue
    if ($curl) {
        $code = & $curl.Source -s -o NUL -w '%{http_code}' --max-time $TimeoutSec $TargetUrl 2>$null
        if ($code -match '^\d{3}$') {
            return [int]$code
        }
        return 0
    }

    try {
        $response = Invoke-WebRequest -Uri $TargetUrl -UseBasicParsing -TimeoutSec $TimeoutSec
        return [int]$response.StatusCode
    } catch {
        return 0
    }
}

function Start-DetachedProcess([string]$FilePath, [string]$Arguments, [string]$WorkingDirectory) {
    $info = New-Object System.Diagnostics.ProcessStartInfo
    $info.FileName = $FilePath
    $info.Arguments = $Arguments
    $info.WorkingDirectory = $WorkingDirectory
    $info.UseShellExecute = $true
    $info.WindowStyle = [System.Diagnostics.ProcessWindowStyle]::Minimized
    $process = New-Object System.Diagnostics.Process
    $process.StartInfo = $info
    if (-not $process.Start()) {
        throw "Failed to start $FilePath"
    }
    return $process
}

function Set-EnvValue([string]$Key, [string]$Value) {
    $text = [System.IO.File]::ReadAllText($EnvFile)
    $pattern = "(?m)^$Key=.*$"
    if ([regex]::IsMatch($text, $pattern)) {
        $updated = [regex]::Replace($text, $pattern, "$Key=$Value", 1)
    } else {
        $suffix = if ($text.EndsWith("`n")) { "$Key=$Value`r`n" } else { "`r`n$Key=$Value`r`n" }
        $updated = $text + $suffix
    }
    if ($updated -ne $text) {
        $utf8NoBom = New-Object System.Text.UTF8Encoding $false
        [System.IO.File]::WriteAllText($EnvFile, $updated, $utf8NoBom)
    }
}

function Stop-JeapProcesses {
    try {
        Get-NetTCPConnection -LocalPort 8080 -State Listen -ErrorAction SilentlyContinue |
            ForEach-Object { Stop-Process -Id $_.OwningProcess -Force -ErrorAction SilentlyContinue }
    } catch {
        # Accessing TCP connections can fail without admin rights.
    }

    Get-CimInstance Win32_Process -Filter "Name='php.exe'" -ErrorAction SilentlyContinue |
        Where-Object { $_.CommandLine -match 'artisan serve|--port=8080|-S 127\.0\.0\.1:8080' } |
        ForEach-Object { Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue }

    Get-CimInstance Win32_Process -Filter "Name='cloudflared.exe'" -ErrorAction SilentlyContinue |
        ForEach-Object { Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue }

    Start-Sleep -Seconds 2
}

function Test-AssetsNeedBuild {
    $manifest = Join-Path $Root 'public\build\manifest.json'
    if (-not (Test-Path $manifest)) {
        return $true
    }

    $manifestTime = (Get-Item $manifest).LastWriteTime
    $sources = @()
    $sources += Get-ChildItem -LiteralPath (Join-Path $Root 'resources') -Recurse -Include *.css,*.js,*.ts -File -ErrorAction SilentlyContinue
    $sources += Get-Item -LiteralPath (Join-Path $Root 'vite.config.js') -ErrorAction SilentlyContinue
    return [bool]($sources | Where-Object { $_.LastWriteTime -gt $manifestTime })
}

if (-not (Test-Path $EnvFile)) {
    throw '.env is missing. Copy .env.example to .env first.'
}
if (-not (Test-Path $Cloudflared)) {
    throw "cloudflared not found at $Cloudflared"
}
if (-not (Test-Path $TunnelConfig)) {
    throw "Cloudflare config not found at $TunnelConfig"
}

$php = Resolve-Php

Write-Step 'Stopping any previous JEAP server and tunnel...'
Stop-JeapProcesses

if (Test-Path (Join-Path $Root 'public\hot')) {
    Remove-Item (Join-Path $Root 'public\hot') -Force
}

Write-Step 'Setting HTTPS tunnel URLs...'
Set-EnvValue 'APP_URL' $Url
Set-EnvValue 'SESSION_SECURE_COOKIE' 'true'

if ($Build -or (Test-AssetsNeedBuild)) {
    Write-Step 'Building frontend assets...'
    $npm = Join-Path $env:ProgramFiles 'nodejs\npm.cmd'
    if (-not (Test-Path $npm)) {
        $npmCmd = Get-Command npm.cmd -ErrorAction SilentlyContinue
        if (-not $npmCmd) { throw 'npm is not installed.' }
        $npm = $npmCmd.Source
    }
    & $npm run build
    if ($LASTEXITCODE -ne 0) {
        throw 'npm run build failed.'
    }
} else {
    Write-Step 'Frontend assets are already current.'
}

Write-Step 'Clearing Laravel config cache...'
& $php artisan config:clear | Out-Host

Write-Step 'Clearing stale Cloudflare connections...'
& $Cloudflared tunnel cleanup jeap.store | Out-Host

Write-Step 'Starting Laravel on 127.0.0.1:8080...'
Start-DetachedProcess -FilePath $php -Arguments 'artisan serve --host=127.0.0.1 --port=8080 --no-reload' -WorkingDirectory $Root | Out-Null

$localReady = $false
for ($i = 0; $i -lt 15; $i++) {
    Start-Sleep -Seconds 1
    if ((Get-HttpStatus 'http://127.0.0.1:8080/' 4) -eq 200) {
        $localReady = $true
        break
    }
}
if (-not $localReady) {
    throw 'Laravel did not start on http://127.0.0.1:8080. Check that port 8080 is free and PHP can run artisan serve.'
}

function Get-TunnelConnectorIds {
    $previous = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    $info = cmd.exe /c "`"$Cloudflared`" tunnel info jeap.store 2>&1"
    $ErrorActionPreference = $previous
    return [regex]::Matches(($info | Out-String), '[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}') |
        ForEach-Object { $_.Value } |
        Select-Object -Unique
}

function Remove-StaleTunnelConnectors([string]$KeepId) {
    if (-not $KeepId) { return }
    foreach ($connectorId in Get-TunnelConnectorIds) {
        if ($connectorId -eq $KeepId -or $connectorId -eq $TunnelId) { continue }
        Write-Step "Disconnecting stale Cloudflare connector $connectorId ..."
        $previous = $ErrorActionPreference
        $ErrorActionPreference = 'Continue'
        cmd.exe /c "`"$Cloudflared`" tunnel cleanup --connector-id $connectorId jeap.store"
        $ErrorActionPreference = $previous
    }
}

Write-Step 'Starting Cloudflare tunnel...'
if (Test-Path $TunnelLog) {
    Remove-Item $TunnelLog -Force -ErrorAction SilentlyContinue
}
$tunnelArgs = "tunnel --config `"$TunnelConfig`" --protocol http2 --logfile `"$TunnelLog`" run jeap.store"
Start-DetachedProcess -FilePath $Cloudflared -Arguments $tunnelArgs -WorkingDirectory $Root | Out-Null

$ourConnector = $null
for ($i = 0; $i -lt 15; $i++) {
    Start-Sleep -Seconds 1
    if (Test-Path $TunnelLog) {
        $match = Select-String -LiteralPath $TunnelLog -Pattern 'Generated Connector ID: ([0-9a-f-]+)' | Select-Object -Last 1
        if ($match) {
            $ourConnector = $match.Matches[0].Groups[1].Value
            break
        }
    }
}
if ($ourConnector) {
    Remove-StaleTunnelConnectors $ourConnector
}

Write-Step "Waiting for $Url ..."
$ready = $false
$okStreak = 0
for ($i = 0; $i -lt 30; $i++) {
    Start-Sleep -Seconds 2
    if ((Get-HttpStatus $Url 10) -eq 200) {
        $okStreak++
        if ($okStreak -ge 2) {
            $ready = $true
            break
        }
    } else {
        $okStreak = 0
    }
}

if (-not $ready) {
    Write-Host "Laravel is running locally, but $Url did not return 200 yet." -ForegroundColor Yellow
    if (Test-Path $TunnelLog) {
        Write-Host "Tunnel log: $TunnelLog" -ForegroundColor Yellow
        Get-Content $TunnelLog -Tail 20 | Out-Host
    }
    exit 1
}

Write-Host "JEAP is live at $Url" -ForegroundColor Green
if (-not $NoBrowser) {
    Start-Process $Url
}
