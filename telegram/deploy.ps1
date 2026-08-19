<#
 .SYNOPSIS
  Deploy BomzhHammer Telegram Mini App to server

 .DESCRIPTION
  1. Exports Godot Web build
  2. Patches index.html with Telegram Web App API
  3. Copies everything to server via scp
  4. Builds Docker image and runs it on server
  5. Installs Caddy for HTTPS (if needed)

 .EXAMPLE
  .\deploy.ps1
  .\deploy.ps1 -SkipExport
#>

param(
    [switch]$SkipExport = $false
)

$SSH_KEY = "C:\Users\Admin\.ssh\id_ed25519_new"
$SSH_HOST = "root@45.32.187.32"
$REMOTE_DIR = "/root/bomzhhammer"
$PROJECT_DIR = "D:\Projects\ГОТОВЫЕ_ПРОЕКТЫ\BOMZHHAMMER"
$GODOT = "D:\Projects\CWG\godot_bin\Godot_v4.2.2-stable_win64_console.exe"

function SSH($cmd) {
    ssh -i $SSH_KEY -o ConnectTimeout=10 $SSH_HOST $cmd
}

function SCP($src, $dst) {
    scp -i $SSH_KEY -o ConnectTimeout=10 $src "${SSH_HOST}:${dst}"
}

Write-Host "=== BomzhHammer Telegram Mini App Deploy ===" -ForegroundColor Cyan

if (-not $SkipExport) {
    Write-Host "[1/5] Exporting Web build..." -ForegroundColor Yellow
    Get-Process Godot* -ErrorAction SilentlyContinue | Stop-Process -Force
    & $GODOT --headless --path $PROJECT_DIR --export-release "Web" "$PROJECT_DIR\build_web\index.html" 2>&1 | Select-Object -Last 3
    Write-Host "[OK] Web build exported" -ForegroundColor Green
} else {
    Write-Host "[1/5] Skipping export (use existing build)" -ForegroundColor Gray
}

Write-Host "[2/5] Patching index.html..." -ForegroundColor Yellow
python "$PROJECT_DIR\telegram\sync_build.py"
Write-Host "[OK] Patched" -ForegroundColor Green

Write-Host "[3/5] Copying to server..." -ForegroundColor Yellow
SSH "mkdir -p $REMOTE_DIR/static"

$tempDir = "$env:TEMP\bomzhhammer_deploy"
if (Test-Path $tempDir) { Remove-Item $tempDir -Recurse -Force }
New-Item -ItemType Directory -Path $tempDir -Force | Out-Null

Copy-Item "$PROJECT_DIR\telegram\tg_server.py" $tempDir
Copy-Item "$PROJECT_DIR\telegram\Dockerfile" $tempDir
Copy-Item "$PROJECT_DIR\telegram\.env" $tempDir

scp -i $SSH_KEY -r "$tempDir\*" "${SSH_HOST}:${REMOTE_DIR}/" 2>&1 | Select-Object -Last 2
scp -i $SSH_KEY -r "$PROJECT_DIR\telegram\static\*" "${SSH_HOST}:${REMOTE_DIR}/static/" 2>&1 | Select-Object -Last 2

Remove-Item $tempDir -Recurse -Force
Write-Host "[OK] Copied" -ForegroundColor Green

Write-Host "[4/5] Building Docker image on server..." -ForegroundColor Yellow
SSH "cd $REMOTE_DIR && docker build -t bomzhhammer . 2>&1 | tail -5"
Write-Host "[OK] Docker image built" -ForegroundColor Green

Write-Host "[5/5] Starting container..." -ForegroundColor Yellow
SSH "docker stop bomzhhammer 2>/dev/null; docker rm bomzhhammer 2>/dev/null"
SSH "docker run -d --name bomzhhammer --restart unless-stopped -p 8080:8080 -e TELEGRAM_BOT_TOKEN=TG-TOKEN-REVOKED bomzhhammer"
Write-Host "[OK] Container started" -ForegroundColor Green

Write-Host ""
Write-Host "=== Checking ===" -ForegroundColor Cyan
SSH "docker logs bomzhhammer 2>&1 | tail -10"

Write-Host ""
Write-Host "=== DONE ===" -ForegroundColor Green
Write-Host "Game:      http://45.32.187.32:8080"
Write-Host "Bot:       @BomzhUnlimBot in Telegram -> /play"
Write-Host "Note: For Telegram Mini App you need HTTPS domain!"
Write-Host "      Install Caddy or use DuckDNS for free domain"
