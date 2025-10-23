#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

PORT=8765

echo "Master Controller Startup Script"
echo "================================"

if [ -f config.py ]; then
    CONFIG_PORT=$(grep -oP 'WEBSOCKET_PORT\s*=\s*\K\d+' config.py 2>/dev/null)
    if [ -n "$CONFIG_PORT" ]; then
        PORT=$CONFIG_PORT
    fi
fi

echo "Cleaning up WebSocket port $PORT..."

if command -v fuser &> /dev/null; then
    sudo fuser -k ${PORT}/tcp 2>/dev/null || true
    echo "Port cleanup complete"
elif command -v lsof &> /dev/null; then
    PIDS=$(lsof -t -i:${PORT} 2>/dev/null)
    if [ -n "$PIDS" ]; then
        echo "Killing processes: $PIDS"
        sudo kill -9 $PIDS 2>/dev/null || true
    fi
    echo "Port cleanup complete"
else
    echo "Warning: fuser and lsof not available, skipping port cleanup"
fi

sleep 0.5

echo "Starting Master Controller..."
echo ""

exec python3 main.py "$@"

