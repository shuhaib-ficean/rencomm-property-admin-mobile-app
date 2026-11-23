# Ensure Flutter is available in the current session PATH
$userPath = [System.Environment]::GetEnvironmentVariable("Path", "User")
$machinePath = [System.Environment]::GetEnvironmentVariable("Path", "Machine")
$env:Path = "$userPath;$machinePath;$env:Path"

if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) {
    Write-Host "Locating Flutter SDK on your computer..." -ForegroundColor Yellow
    
    # 1. Direct check for C:\src\flutter\flutter\bin or C:\src\flutter\bin
    $knownLocations = @(
        "C:\src\flutter\flutter\bin",
        "C:\src\flutter\bin",
        "C:\flutter\bin"
    )
    foreach ($loc in $knownLocations) {
        if (Test-Path "$loc\flutter.bat") {
            $env:Path = "$loc;" + $env:Path
            Write-Host "Found Flutter SDK at: $loc" -ForegroundColor Green
            break
        }
    }
}

if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) {
    # 2. Check all entries in User/Machine PATH containing 'flutter'
    $pathEntries = ($userPath -split ";") + ($machinePath -split ";")
    foreach ($entry in $pathEntries) {
        $trimmed = $entry.Trim().TrimEnd('\')
        if ($trimmed -like "*flutter*") {
            if (Test-Path "$trimmed\flutter.bat") {
                $env:Path = "$trimmed;" + $env:Path
                Write-Host "Found Flutter from PATH config: $trimmed" -ForegroundColor Green
                break
            } elseif (Test-Path "$trimmed\bin\flutter.bat") {
                $env:Path = "$trimmed\bin;" + $env:Path
                Write-Host "Found Flutter from PATH config: $trimmed\bin" -ForegroundColor Green
                break
            }
        }
    }
}

if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) {
    # 3. Search C:\src and Downloads recursively for flutter.bat
    $candidate = Get-ChildItem -Path "C:\src" -Filter "flutter.bat" -Recurse -Depth 4 -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($candidate) {
        $flutterDir = $candidate.Directory.FullName
        Write-Host "Found Flutter SDK at: $flutterDir" -ForegroundColor Green
        $env:Path = "$flutterDir;" + $env:Path
    }
}

if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) {
    Write-Host "ERROR: Could not locate 'flutter.bat' on your system." -ForegroundColor Red
    exit 1
}

Write-Host "Setting up direct USB tunnel..." -ForegroundColor Yellow
$adbPath = "C:\Users\BEST\AppData\Local\Android\Sdk\platform-tools\adb.exe"
if (-not (Test-Path $adbPath)) {
    $adbPath = "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe"
}
if (-not (Test-Path $adbPath)) {
    $adbPath = "adb"
}

try {
    & $adbPath start-server
    & $adbPath reverse tcp:5001 tcp:5001
    Write-Host "USB Reverse tunnel established for port 5001 (fallback to local Wi-Fi active if disconnected)." -ForegroundColor Green
} catch {
    Write-Host "ADB reverse failed; app will automatically use Wi-Fi fallback (192.168.1.6:5001)." -ForegroundColor Yellow
}

Write-Host "Starting Property Admin Mobile App on connected device..." -ForegroundColor Cyan
flutter run
