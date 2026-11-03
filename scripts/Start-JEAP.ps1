#Requires -Version 5.1
param(
    [switch]$Build,
    [switch]$NoBrowser
)

$ErrorActionPreference = 'Stop'
$Root = Split-Path -Parent $PSScriptRoot
$Url = 'https://jeap.store'
$LocalHealth = 'http://127.0.0.1:8080/up'
$TunnelName = 'jeap-laptop'
$TunnelId = 'd54dc686-4216-4ac5-8482-6f40efe25cac'
$TunnelConfig = Join-Path $env:USERPROFILE '.cloudflared\config.yml'
$EnvFile = Join-Path $Root '.env'
$LogDir = Join-Path $Root 'storage\logs'
$TunnelLog = Join-Path $LogDir 'cloudflared-jeap.log'
$ServeLog = Join-Path $LogDir 'artisan-serve.log'

Set-Location $Root
New-Item -ItemType Directory -Force -Path $LogDir | Out-Null

function Write-Step([string]$Message) {
    Write-Host $Message -ForegroundColor Cyan
}

function Invoke-Native {
    param(
        [Parameter(Mandatory)][string]$FilePath,
        [Parameter()][string[]]$ArgumentList = @()
    )
    $previous = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    $output = & $FilePath @ArgumentList 2>&1 | ForEach-Object { $_.ToString() }
    $code = $LASTEXITCODE
    $ErrorActionPreference = $previous
    if ($null -ne $output) {
        $output | ForEach-Object { Write-Host $_ }
    }
    return $code
}

function Resolve-Php {
    $candidates = @(
        'C:\xampp\php\php.exe',
        'C:\php\php.exe'
    )
    $fromPath = Get-Command php.exe -ErrorAction SilentlyContinue
    if ($fromPath) { $candidates += $fromPath.Source }
    foreach ($candidate in $candidates) {
        if ($candidate -and (Test-Path -LiteralPath $candidate)) {
            return $candidate
        }
    }
    throw 'PHP was not found. Install XAMPP PHP at C:\xampp\php\php.exe.'
}

function Resolve-Cloudflared {
    $candidates = @(
        'C:\Program Files (x86)\cloudflared\cloudflared.exe',
        'C:\Program Files\cloudflared\cloudflared.exe'
    )
    $fromPath = Get-Command cloudflared.exe -ErrorAction SilentlyContinue
    if ($fromPath) { $candidates += $fromPath.Source }
    foreach ($candidate in $candidates) {
        if ($candidate -and (Test-Path -LiteralPath $candidate)) {
            return $candidate
        }
    }
    throw 'cloudflared was not found. Install Cloudflare Tunnel at C:\Program Files (x86)\cloudflared\cloudflared.exe.'
}

function Get-HttpStatus([string]$TargetUrl, [int]$TimeoutSec = 8) {
    $previous = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    $code = & curl.exe -s -o "$env:TEMP\jeap-health-body.txt" -w '%{http_code}' --max-time $TimeoutSec $TargetUrl 2>$null
    $ErrorActionPreference = $previous
    $code = (($code | Out-String).Trim())
    if ($code -match '^\d{3}$') {
        return [int]$code
    }
    return 0
}

function Test-HttpUp([string]$TargetUrl, [int]$TimeoutSec = 8) {
    $code = Get-HttpStatus $TargetUrl $TimeoutSec
    return ($code -ge 200 -and $code -lt 400)
}

function Start-LoggedProcess([string]$FilePath, [string]$Arguments, [string]$WorkingDirectory, [string]$StdOut, [string]$StdErr) {
    $dir = Split-Path -Parent $StdOut
    if ($dir) {
        New-Item -ItemType Directory -Force -Path $dir | Out-Null
    }
    foreach ($log in @($StdOut, $StdErr)) {
        if ($log -and (Test-Path -LiteralPath $log)) {
            Remove-Item -LiteralPath $log -Force -ErrorAction SilentlyContinue
        }
    }
    return Start-Process -FilePath $FilePath -ArgumentList $Arguments -WorkingDirectory $WorkingDirectory -WindowStyle Hidden -RedirectStandardOutput $StdOut -RedirectStandardError $StdErr -PassThru
}

function Start-MinimizedProcess([string]$FilePath, [string]$Arguments, [string]$WorkingDirectory) {
    return Start-Process -FilePath $FilePath -ArgumentList $Arguments -WorkingDirectory $WorkingDirectory -WindowStyle Minimized -PassThru
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

function Start-MySqlIfNeeded {
    if (Get-Process -Name mysqld -ErrorAction SilentlyContinue) {
        Write-Step 'MySQL is already running.'
        return
    }

    $mysqlBat = 'C:\xampp\mysql_start.bat'
    if (-not (Test-Path -LiteralPath $mysqlBat)) {
        throw 'MySQL is not running and C:\xampp\mysql_start.bat was not found. Start MySQL in XAMPP, then run Start JEAP again.'
    }

    Write-Step 'Starting MySQL...'
    Start-Process -FilePath $mysqlBat -WindowStyle Minimized | Out-Null
    for ($i = 0; $i -lt 25; $i++) {
        Start-Sleep -Seconds 1
        if (Get-Process -Name mysqld -ErrorAction SilentlyContinue) {
            return
        }
    }
    throw 'MySQL did not start. Open XAMPP Control Panel, start MySQL, then run Start JEAP again.'
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

function Get-TunnelConnectorIds {
    $previous = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    $info = cmd.exe /c "`"$Cloudflared`" tunnel info $TunnelName 2>&1"
    $ErrorActionPreference = $previous
    return [regex]::Matches(($info | Out-String), '[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}') |
        ForEach-Object { $_.Value } |
        Select-Object -Unique
}

function Remove-StaleTunnelConnectors([string]$KeepId) {
    if (-not $KeepId) {
        Write-Host 'Skipping connector cleanup until this PC has a live Cloudflare connector.' -ForegroundColor Yellow
        return
    }
    foreach ($connectorId in Get-TunnelConnectorIds) {
        if ($connectorId -eq $KeepId -or $connectorId -eq $TunnelId) { continue }
        Write-Step "Disconnecting stale Cloudflare connector $connectorId ..."
        $null = Invoke-Native -FilePath $Cloudflared -ArgumentList @('tunnel', 'cleanup', '--connector-id', $connectorId, $TunnelName)
    }
}

if (-not (Test-Path $EnvFile)) {
    throw '.env is missing. Copy .env.example to .env first.'
}
if (-not (Test-Path $TunnelConfig)) {
    throw "Cloudflare config not found at $TunnelConfig"
}

$php = Resolve-Php
$Cloudflared = Resolve-Cloudflared

Start-MySqlIfNeeded

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
    if ((Invoke-Native -FilePath $npm -ArgumentList @('run', 'build')) -ne 0) {
        throw 'npm run build failed.'
    }
} else {
    Write-Step 'Frontend assets are already current.'
}

Write-Step 'Clearing Laravel config cache...'
if ((Invoke-Native -FilePath $php -ArgumentList @('artisan', 'config:clear')) -ne 0) {
    throw 'php artisan config:clear failed.'
}

Write-Step 'Clearing stale Cloudflare connections...'
$null = Invoke-Native -FilePath $Cloudflared -ArgumentList @('tunnel', 'cleanup', $TunnelName)

Write-Step 'Starting Laravel on 127.0.0.1:8080...'
$serveErr = Join-Path $LogDir 'artisan-serve.err.log'
Start-LoggedProcess -FilePath $php -Arguments 'artisan serve --host=127.0.0.1 --port=8080 --no-reload' -WorkingDirectory $Root -StdOut $ServeLog -StdErr $serveErr | Out-Null

$localReady = $false
for ($i = 0; $i -lt 30; $i++) {
    Start-Sleep -Seconds 1
    if (Test-HttpUp $LocalHealth 5) {
        $localReady = $true
        break
    }
}
if (-not $localReady) {
    Write-Host 'Laravel did not become ready on http://127.0.0.1:8080/up' -ForegroundColor Red
    if (Test-Path $ServeLog) { Get-Content $ServeLog -Tail 40 | Out-Host }
    if (Test-Path $serveErr) { Get-Content $serveErr -Tail 40 | Out-Host }
    throw 'Laravel did not start on http://127.0.0.1:8080. Check that port 8080 is free and MySQL is running.'
}

Write-Step 'Starting Cloudflare tunnel...'
if (Test-Path $TunnelLog) {
    Remove-Item $TunnelLog -Force -ErrorAction SilentlyContinue
}
$quotedConfig = '"' + $TunnelConfig + '"'
$quotedLog = '"' + $TunnelLog + '"'
$tunnelArgs = "tunnel --config $quotedConfig --protocol http2 --edge-ip-version 4 --logfile $quotedLog run $TunnelName"
# Hidden: a minimized console is too easy to close, which drops https://jeap.store.
Start-Process -FilePath $Cloudflared -ArgumentList $tunnelArgs -WorkingDirectory $Root -WindowStyle Hidden | Out-Null

$ourConnector = $null
for ($i = 0; $i -lt 20; $i++) {
    Start-Sleep -Seconds 1
    if (Test-Path $TunnelLog) {
        $registered = Select-String -LiteralPath $TunnelLog -Pattern 'Registered tunnel connection' -ErrorAction SilentlyContinue | Select-Object -Last 1
        $match = Select-String -LiteralPath $TunnelLog -Pattern 'Generated Connector ID: ([0-9a-f-]+)' -ErrorAction SilentlyContinue | Select-Object -Last 1
        if ($match) {
            $ourConnector = $match.Matches[0].Groups[1].Value
        }
        if ($registered) {
            break
        }
    }
}
Remove-StaleTunnelConnectors $ourConnector

Write-Step "Waiting for $Url ..."
$ready = $false
$okStreak = 0
for ($i = 0; $i -lt 40; $i++) {
    Start-Sleep -Seconds 2
    if (Test-HttpUp $Url 10) {
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
    Write-Host "Laravel is running locally at http://127.0.0.1:8080" -ForegroundColor Yellow
    Write-Host "$Url did not return a successful response yet. Leave the site starting; it often comes up within a minute." -ForegroundColor Yellow
    if (Test-Path $TunnelLog) {
        Write-Host "Tunnel log: $TunnelLog" -ForegroundColor Yellow
        Get-Content $TunnelLog -Tail 20 | Out-Host
    }
    exit 1
}

Write-Host "JEAP is live at $Url" -ForegroundColor Green
Write-Host 'Leave this PC awake. Use Stop JEAP when you are done.' -ForegroundColor Green
if (-not $NoBrowser) {
    Start-Process $Url
}
