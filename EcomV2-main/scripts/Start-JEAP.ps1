#Requires -Version 5.1
param(
    [switch]$Build,
    [switch]$NoBrowser
)

$ErrorActionPreference = 'Stop'
$Root = Split-Path -Parent $PSScriptRoot
$Url = 'https://jeap.store'
$Cloudflared = 'C:\Program Files (x86)\cloudflared\cloudflared.exe'
$TunnelConfig = Join-Path $env:USERPROFILE '.cloudflared\config.yml'
$EnvFile = Join-Path $Root '.env'

Set-Location $Root

function Write-Step([string]$Message) {
    Write-Host $Message -ForegroundColor Cyan
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
    Get-NetTCPConnection -LocalPort 8080 -State Listen -ErrorAction SilentlyContinue |
        ForEach-Object { Stop-Process -Id $_.OwningProcess -Force -ErrorAction SilentlyContinue }

    Get-CimInstance Win32_Process -Filter "Name='cloudflared.exe'" -ErrorAction SilentlyContinue |
        Where-Object { $_.CommandLine -match 'jeap\.store' } |
        ForEach-Object { Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue }

    Start-Sleep -Seconds 1
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
if (-not (Get-Command php -ErrorAction SilentlyContinue)) {
    throw 'php is not on PATH.'
}
if (-not (Test-Path $Cloudflared)) {
    throw "cloudflared not found at $Cloudflared"
}

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
    npm run build
} else {
    Write-Step 'Frontend assets are already current.'
}

Write-Step 'Clearing Laravel config cache...'
php artisan config:clear | Out-Host

if (Test-Path $Cloudflared) {
    Write-Step 'Clearing stale Cloudflare connections...'
    & $Cloudflared tunnel cleanup jeap.store | Out-Host
}

Write-Step 'Starting Laravel on 127.0.0.1:8080...'
Start-Process -FilePath (Get-Command php).Source -ArgumentList @('artisan', 'serve', '--host=127.0.0.1', '--port=8080', '--no-reload') -WorkingDirectory $Root -WindowStyle Minimized

Write-Step 'Starting Cloudflare tunnel...'
Start-Process -FilePath $Cloudflared -ArgumentList @('tunnel', '--config', $TunnelConfig, '--protocol', 'http2', 'run', 'jeap.store') -WorkingDirectory $Root -WindowStyle Minimized

Write-Step "Waiting for $Url ..."
$ready = $false
for ($i = 0; $i -lt 24; $i++) {
    Start-Sleep -Seconds 2
    try {
        $response = Invoke-WebRequest -Uri $Url -UseBasicParsing -TimeoutSec 8
        if ($response.StatusCode -eq 200) {
            $ready = $true
            break
        }
    } catch {
        # keep waiting
    }
}

if (-not $ready) {
    Write-Host "Started locally, but $Url did not return 200 yet. Leave this laptop awake and try again in a few seconds." -ForegroundColor Yellow
    exit 1
}

Write-Host "JEAP is live at $Url" -ForegroundColor Green
if (-not $NoBrowser) {
    Start-Process $Url
}
