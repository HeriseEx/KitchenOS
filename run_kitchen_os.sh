#!/bin/bash

# run_kitchen_os.sh - Ubuntu version

echo -e "\033[36mKitchenOS Start Script\033[0m"
echo -e "\033[36m======================\033[0m"

# Port to use
PORT=8888

# 1. Kill any process listening on port 8888
echo -e "\033[33mChecking for processes on port $PORT...\033[0m"
PID=$(lsof -ti :$PORT 2>/dev/null)

if [ -n "$PID" ]; then
    echo -e "\033[31mKilling process on port $PORT (PID: $PID)...\033[0m"
    kill -9 $PID 2>/dev/null
else
    echo -e "\033[32mNo process found on port $PORT.\033[0m"
fi

# 2. Change to the script's directory (kitchen_os folder)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo -e "\033[33mWorking directory: $(pwd)\033[0m"

# 3. Optional: Clean build
# echo -e "\033[33mCleaning build...\033[0m"
# flutter clean
# flutter pub get

# 4. Start Flutter Web Server
echo -e "\033[32mStarting KitchenOS on port $PORT...\033[0m"
flutter run -d web-server --web-port $PORT --web-hostname 0.0.0.0

echo -e "\033[36mKitchenOS server stopped.\033[0m"
