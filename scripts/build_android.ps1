param(
    [string]$Preset = "Android_Debug",
    [int]$TestTimeout = 30
)

$ErrorActionPreference = "Continue"
$Godot = "D:\Projects\CWG\godot_bin\Godot_v4.2.2-stable_win64_console.exe"
$Project = "D:\Projects\BOMZHHAMMER"
$Adb = "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe"
$ApkDir = "$Project\export\android"
$ApkName = "BomzhHammer-debug.apk"
$ApkPath = "$ApkDir\$ApkName"
$Emulator = "$env:LOCALAPPDATA\Android\Sdk\emulator\emulator.exe"
$AvdName = "Test_API34"
$Env:JAVA_HOME = "D:\Program Files\Android\Android Studio\jbr"

function Write-Step($msg) { Write-Host "`n=== $msg ===" -ForegroundColor Cyan }
function Write-OK($msg) { Write-Host "  OK: $msg" -ForegroundColor Green }
function Write-Fail($msg) { Write-Host "  FAIL: $msg" -ForegroundColor Red }
function Write-Info($msg) { Write-Host "  $msg" -ForegroundColor Gray }

Write-Host "BOMZHHAMMER Android Build & Test" -ForegroundColor Yellow
Write-Host "Preset: $Preset" -ForegroundColor Gray

# Step 1: Run tests
Write-Step "1. Running tests"
$testOutput = & $Godot --headless --path $Project --script tests/test_runner.gd 2>&1 | Out-String
$testResult = $testOutput | Select-String "ALL \d+ TESTS PASSED"
$testFailed = $testOutput | Select-String "FAILED.*TESTS"
if ($testResult) {
    Write-OK $testResult.ToString().Trim()
} else {
    Write-Fail "Tests failed!"
    Write-Host $testOutput | Select-Object -Last 20
    exit 1
}

# Step 2: Export APK
Write-Step "2. Exporting APK ($Preset)"
Remove-Item $ApkPath -Force -ErrorAction SilentlyContinue
$env:JAVA_HOME = $Env:JAVA_HOME
$exportOutput = & $Godot --headless --path $Project --export-debug $Preset $ApkPath 2>&1 | Out-String
$signed = $exportOutput | Select-String "Signed"
$exportFailed = $exportOutput | Select-String "Project export.*failed"
if ($signed -and -not $exportFailed) {
    $apkSize = [math]::Round((Get-Item $ApkPath).Length / 1MB, 1)
    Write-OK "APK built: $ApkName ($apkSize MB)"
} else {
    Write-Fail "Export failed!"
    Write-Host ($exportOutput | Select-String "ERROR|failed|Error" | Select-Object -Last 10)
    exit 1
}

# Step 3: Ensure emulator running
Write-Step "3. Checking emulator"
& $Adb start-server 2>&1 | Out-Null
Start-Sleep -Seconds 2
$devices = & $Adb devices 2>&1 | Out-String
$online = $devices -match "device\s*$"

if (-not $online) {
    Write-Info "Starting emulator..."
    Get-Process emulator -ErrorAction SilentlyContinue | Stop-Process -Force
    Get-Process qemu* -ErrorAction SilentlyContinue | Stop-Process -Force
    Start-Sleep -Seconds 3
    Start-Process $Emulator -ArgumentList "-avd",$AvdName,"-no-snapshot-load","-gpu","swiftshader_indirect","-memory","4096" -WindowStyle Minimized
    $waited = 0
    while ($waited -lt 120) {
        Start-Sleep -Seconds 5
        $waited += 5
        $d = & $Adb devices 2>&1 | Out-String
        if ($d -match "device\s*$") {
            Write-OK "Emulator ready (${waited}s)"
            break
        }
        Write-Info "Waiting... (${waited}s)"
    }
    if ($waited -ge 120) {
        Write-Fail "Emulator failed to start"
        exit 1
    }
} else {
    Write-OK "Emulator already online"
}

# Step 4: Install APK
Write-Step "4. Installing APK"
$installOutput = & $Adb install -r $ApkPath 2>&1 | Out-String
if ($installOutput -match "Success") {
    Write-OK "APK installed"
} else {
    Write-Fail "Install failed: $installOutput"
    & $Adb reconnect 2>&1 | Out-Null
    Start-Sleep -Seconds 5
    $installOutput2 = & $Adb install -r $ApkPath 2>&1 | Out-String
    if ($installOutput2 -match "Success") {
        Write-OK "APK installed (retry)"
    } else {
        Write-Fail "Install failed on retry"
        exit 1
    }
}

# Step 5: Launch and collect logs
Write-Step "5. Launching app"
& $Adb logcat -c 2>&1 | Out-Null
& $Adb shell am start -n ru.bomzhhammer.game/com.godot.game.GodotApp 2>&1 | Out-Null
Write-Info "App started, waiting for splash..."

# Wait for splash then skip it
Start-Sleep -Seconds 20
Write-Info "Skipping splash..."
& $Adb shell input tap 540 960 2>&1 | Out-Null
Start-Sleep -Seconds 8
Write-Info "Starting new game..."
& $Adb shell input tap 540 950 2>&1 | Out-Null

# Step 6: Collect logs
Write-Step "6. Collecting logs (${TestTimeout}s)"
Start-Sleep -Seconds $TestTimeout
$logs = & $Adb logcat -d -s "godot" 2>&1 | Out-String

# Analyze
$errors = $logs | Select-String "USER ERROR|SCRIPT ERROR|Parse Error"
$warnings = $logs | Select-String "USER WARNING"
$gameStarted = $logs | Select-String "Game started"
$mapBuilt = $logs | Select-String "Grid map built"
$cityMap = $logs | Select-String "City map reloaded"
$scene = $logs | Select-String "scene=\[(\w+)\]" | Select-Object -Last 1

Write-Step "7. Results"
if ($gameStarted) { Write-OK "Game started" } else { Write-Fail "Game NOT started" }
if ($mapBuilt) { Write-OK "Map built: $($mapBuilt.ToString().Trim())" } else { Write-Fail "Map NOT built" }
if ($cityMap) { Write-OK "City map loaded: $($cityMap.ToString().Trim())" }
if ($scene) { Write-Info "Final scene: $($scene.ToString().Trim())" }

if ($errors) {
    Write-Host "`n  ERRORS found:" -ForegroundColor Red
    $errors | ForEach-Object { Write-Host "    $($_.ToString().Trim())" -ForegroundColor Red }
} else {
    Write-OK "Zero errors!"
}

Write-Host "`n  Warnings: $($warnings.Count)" -ForegroundColor Yellow
$warnings | Select-Object -First 5 | ForEach-Object { Write-Info $_.ToString().Trim() }

Write-Host "`n  Last 15 log lines:" -ForegroundColor Gray
($logs -split "`n") | Select-Object -Last 15 | ForEach-Object { Write-Host "    $_" }

# Save full log
$logFile = "$Project\export\android\android_test_log.txt"
$logs | Out-File $logFile -Encoding UTF8
Write-Info "Full log saved to $logFile"

if ($errors.Count -gt 0) {
    Write-Host "`nRESULT: FAIL ($($errors.Count) errors)" -ForegroundColor Red
    exit 1
} else {
    Write-Host "`nRESULT: PASS" -ForegroundColor Green
    exit 0
}
