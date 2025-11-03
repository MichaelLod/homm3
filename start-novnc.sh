#!/bin/bash
set -e

PORT="${PORT:-6080}"
echo "Starting noVNC on port ${PORT}"

# Wait for VNC server to be ready
echo "Waiting for VNC server to start..."
for i in {1..30}; do
    if netstat -ln 2>/dev/null | grep -q ":5901 " || ss -ln 2>/dev/null | grep -q ":5901 "; then
        echo "VNC server is ready!"
        break
    fi
    sleep 1
done

cd /opt/novnc/utils/websockify

# Try different ways to run websockify
if [ -f "run" ]; then
    echo "Using websockify run script"
    exec ./run --web=/opt/novnc 0.0.0.0:${PORT} localhost:5901
elif [ -f "websockify/websocketproxy.py" ]; then
    echo "Using websocketproxy.py directly"
    exec python3 websockify/websocketproxy.py --web=/opt/novnc 0.0.0.0:${PORT} localhost:5901
elif python3 -m websockify --help >/dev/null 2>&1; then
    echo "Using websockify as module"
    exec python3 -m websockify --web=/opt/novnc 0.0.0.0:${PORT} localhost:5901
else
    echo "ERROR: Could not find websockify"
    exit 1
fi

