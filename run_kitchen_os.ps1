# run_kitchen_os.ps1

Write-Host "KitchenOS Start Script" -ForegroundColor Cyan
Write-Host "======================" -ForegroundColor Cyan

# 1. Kill any process listening on port 8888
$port = 8888
Write-Host "Checking for processes on port $port..." -ForegroundColor Yellow
$process = Get-NetTCPConnection -LocalPort $port -ErrorAction SilentlyContinue | Select-Object -ExpandProperty OwningProcess -Unique

if ($process) {
    Write-Host "Killing process on port $port (PID: $process)..." -ForegroundColor Red
    Stop-Process -Id $process -Force -ErrorAction SilentlyContinue
} else {
    Write-Host "No process found on port $port." -ForegroundColor Green
}

# 2. Kill any lingering dart.exe instances started by flutter run (optional but recommended to be clean)
# Be careful not to kill other dart processes if you have other dev tools running, but for this project scope it's likely fine.
# We will filter by command line arguments if possible, but powershell Get-Process doesn't show args easily.
# Let's skip aggressive dart killing to be safe, relying on port kill is usually enough.

# 3. Clean build (optional)
# Write-Host "Cleaning build..." -ForegroundColor Yellow
# cd kitchen_os
# flutter clean
# flutter pub get
# cd ..

# 4. Start Flutter Web Server
Write-Host "Starting KitchenOS on port $port..." -ForegroundColor Green
# Set-Location "kitchen_os"
Start-Process -FilePath "flutter" -ArgumentList "run -d web-server --web-port $port --web-hostname 0.0.0.0" -NoNewWindow -PassThru

Write-Host "KitchenOS is starting... Logs will appear in the console window if attached, or check flutter_run.log if redirected." -ForegroundColor Cyan
Write-Host "Access the app at http://localhost:$port" -ForegroundColor Cyan
