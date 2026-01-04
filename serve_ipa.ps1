# Simple HTTP Server to serve IPA file over WiFi
# Run this script to serve the .ipa file to your iPhone

Write-Host "======================================" -ForegroundColor Cyan
Write-Host "  FutureProof WiFi Installer Server" -ForegroundColor Cyan
Write-Host "======================================" -ForegroundColor Cyan
Write-Host ""

$ipaPath = "build\FutureProof.ipa"

# Check if IPA exists
if (-not (Test-Path $ipaPath)) {
    Write-Host "❌ Error: $ipaPath not found!" -ForegroundColor Red
    Write-Host ""
    Write-Host "Please build the app first:" -ForegroundColor Yellow
    Write-Host "1. Push code to GitHub" -ForegroundColor White
    Write-Host "2. Go to GitHub Actions" -ForegroundColor White
    Write-Host "3. Download the .ipa file" -ForegroundColor White
    Write-Host "4. Place it in: $ipaPath" -ForegroundColor White
    Write-Host ""
    pause
    exit 1
}

Write-Host "✅ Found IPA file: $ipaPath" -ForegroundColor Green
Write-Host ""

# Get local IP address
$ipAddress = (Get-NetIPAddress -AddressFamily IPv4 |
    Where-Object { $_.IPAddress -notlike "127.*" -and $_.IPAddress -notlike "169.254.*" } |
    Select-Object -First 1 -ExpandProperty IPAddress)

if (-not $ipAddress) {
    Write-Host "❌ Error: Could not detect local IP address!" -ForegroundColor Red
    pause
    exit 1
}

$port = 8000
Write-Host "🌐 Starting server on: http://$ipAddress:$port" -ForegroundColor Cyan
Write-Host ""
Write-Host "================================================" -ForegroundColor Yellow
Write-Host "  INSTRUCTIONS FOR YOUR IPHONE:" -ForegroundColor Yellow
Write-Host "================================================" -ForegroundColor Yellow
Write-Host ""
Write-Host "1. Make sure iPhone is on the same WiFi network" -ForegroundColor White
Write-Host "2. Open Safari on your iPhone" -ForegroundColor White
Write-Host "3. Go to: http://$ipAddress:$port" -ForegroundColor Cyan
Write-Host "4. Download and install the .ipa file using AltStore" -ForegroundColor White
Write-Host ""
Write-Host "Press Ctrl+C to stop the server" -ForegroundColor Red
Write-Host "================================================" -ForegroundColor Yellow
Write-Host ""

# Start Python HTTP server
try {
    $currentDir = Get-Location
    Set-Location (Split-Path -Parent $MyInvocation.MyCommand.Path)

    # Check if Python is available
    $pythonCmd = $null
    if (Get-Command python -ErrorAction SilentlyContinue) {
        $pythonCmd = "python"
    } elseif (Get-Command python3 -ErrorAction SilentlyContinue) {
        $pythonCmd = "python3"
    } else {
        Write-Host "❌ Error: Python not found!" -ForegroundColor Red
        Write-Host "Please install Python from: https://www.python.org/downloads/" -ForegroundColor Yellow
        pause
        exit 1
    }

    # Start server
    & $pythonCmd -m http.server $port
}
catch {
    Write-Host "❌ Error starting server: $_" -ForegroundColor Red
    pause
}
finally {
    Set-Location $currentDir
}
