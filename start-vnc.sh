#!/bin/bash

# Kill any existing VNC server on :1 (ignore errors if not running)
/usr/bin/vncserver -kill :1 >/dev/null 2>&1 || true

# Clean up any stale lock files and X11 sockets
rm -f /tmp/.X1-lock /tmp/.X11-unix/X1 /tmp/.X*-lock /tmp/.X11-unix/X* 2>/dev/null || true

# Ensure directories exist
mkdir -p /tmp/.X11-unix
chmod 1777 /tmp/.X11-unix

# Wait a moment for cleanup
sleep 2

# Start VNC server (it runs in background) - capture output for debugging
/usr/bin/vncserver :1 -geometry 1920x1080 -depth 24 -localhost no -SecurityTypes VncAuth 2>&1 | tee /tmp/vnc-startup.log || {
    echo "Failed to start VNC server. Output:"
    cat /tmp/vnc-startup.log 2>/dev/null || true
    exit 1
}

# Wait and verify it started
sleep 3
if ! pgrep -f "Xvnc.*:1" > /dev/null; then
    echo "ERROR: VNC server process not found after startup"
    echo "Startup log:"
    cat /tmp/vnc-startup.log 2>/dev/null || true
    exit 1
fi

echo "VNC server started successfully"

# Monitor the VNC process (keep script running for supervisor)
while true; do
    if ! pgrep -f "Xvnc.*:1" > /dev/null; then
        echo "VNC server process ended unexpectedly"
        exit 1
    fi
    sleep 5
done

