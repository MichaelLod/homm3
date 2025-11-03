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

# Start VNC server with performance optimizations
# - Reduced to 1280x720 for better performance (VCMI will use this resolution)
# - CompressionLevel 1 = fastest (lower quality but better performance)
# - PreferredEncoding tight = better compression
/usr/bin/vncserver :1 \
    -geometry 1280x720 \
    -depth 24 \
    -localhost no \
    -SecurityTypes VncAuth \
    -CompressionLevel 1 \
    -PreferredEncoding tight \
    2>&1 | tee /tmp/vnc-startup.log | tee /dev/stderr || {
    echo "Failed to start VNC server. Output:" >&2
    cat /tmp/vnc-startup.log 2>/dev/null || true
    exit 1
}

# Wait and verify it started
sleep 3
# Check for Xtigervnc process (TigerVNC uses Xtigervnc, not Xvnc)
if ! pgrep -f "Xtigervnc.*:1" > /dev/null && ! pgrep -f "vncserver :1" > /dev/null; then
    echo "ERROR: VNC server process not found after startup" >&2
    echo "Startup log:" >&2
    cat /tmp/vnc-startup.log 2>/dev/null || true
    echo "Checking VNC server logs:" >&2
    cat /root/.vnc/*:1.log 2>/dev/null || echo "No VNC log files found" >&2
    echo "Current VNC processes:" >&2
    ps aux | grep -i vnc | grep -v grep >&2 || echo "None found" >&2
    exit 1
fi

echo "VNC server started successfully" >&2

# Monitor the VNC process (keep script running for supervisor)
while true; do
    # Check for both Xtigervnc and vncserver processes
    if ! pgrep -f "Xtigervnc.*:1" > /dev/null && ! pgrep -f "vncserver :1" > /dev/null; then
        echo "VNC server process ended unexpectedly" >&2
        exit 1
    fi
    sleep 5
done

