#!/bin/bash
set -e

# Kill any existing VNC server on :1 (ignore errors if not running)
/usr/bin/vncserver -kill :1 >/dev/null 2>&1 || true

# Clean up any stale lock files
rm -f /tmp/.X1-lock /tmp/.X11-unix/X1 2>/dev/null || true

# Wait a moment for cleanup
sleep 1

# Start VNC server in foreground mode (so supervisor can manage it)
exec /usr/bin/vncserver :1 -geometry 1920x1080 -depth 24 -fg

