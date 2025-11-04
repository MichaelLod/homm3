#!/bin/bash
# Show logs - useful for Railway debugging
# This script displays logs that might not be visible in Railway's default view

echo "========================================="
echo "VCMI Server Logs Viewer"
echo "========================================="
echo ""
echo "This script shows logs from various sources."
echo "Note: Railway deployment logs show stdout/stderr from the main process."
echo ""

# Supervisor logs
echo "1. SUPERVISOR LOGS (Recent)"
echo "============================"
if [ -f /var/log/supervisor/supervisord.log ]; then
    echo "Last 50 lines of supervisord.log:"
    tail -50 /var/log/supervisor/supervisord.log
else
    echo "⚠️  supervisord.log not found"
fi
echo ""

# VNC logs
echo "2. VNC SERVER LOGS (Recent)"
echo "============================"
if [ -f /var/log/supervisor/vnc.log ]; then
    echo "Last 50 lines of vnc.log:"
    tail -50 /var/log/supervisor/vnc.log
else
    echo "⚠️  vnc.log not found"
fi
echo ""

# noVNC logs
echo "3. NOVNC LOGS (Recent)"
echo "======================"
if [ -f /var/log/supervisor/novnc.log ]; then
    echo "Last 50 lines of novnc.log:"
    tail -50 /var/log/supervisor/novnc.log
else
    echo "⚠️  novnc.log not found"
fi
echo ""

# VCMI logs
echo "4. VCMI CLIENT LOGS"
echo "==================="
VCMI_LOG_DIR="$HOME/.local/share/vcmi"
if [ -d "$VCMI_LOG_DIR" ]; then
    echo "VCMI log files:"
    ls -lah "$VCMI_LOG_DIR"/*.log 2>/dev/null | head -10 || echo "No .log files found"
    echo ""
    echo "Recent VCMI log entries (mod-related):"
    find "$VCMI_LOG_DIR" -name "*.log" -type f -exec tail -20 {} \; 2>/dev/null | grep -i "mod\|hota\|error\|warning" | head -20 || echo "No mod-related entries found"
else
    echo "⚠️  VCMI log directory not found at $VCMI_LOG_DIR"
fi
echo ""

# Application logs
echo "5. APPLICATION LOGS (HotA, etc.)"
echo "================================="
if [ -f /tmp/hota-install.log ]; then
    echo "HotA installation log (last 30 lines):"
    tail -30 /tmp/hota-install.log
    echo ""
fi
if [ -f /tmp/hota-enable.log ]; then
    echo "HotA enable log (last 30 lines):"
    tail -30 /tmp/hota-enable.log
    echo ""
fi
if [ -f /tmp/vnc-startup.log ]; then
    echo "VNC startup log:"
    cat /tmp/vnc-startup.log
    echo ""
fi

echo "========================================="
echo "Log locations for Railway CLI/SSH access:"
echo "========================================="
echo "Supervisor logs: /var/log/supervisor/"
echo "  - supervisord.log - Main supervisor log"
echo "  - vnc.log - VNC server log"
echo "  - novnc.log - noVNC web server log"
echo ""
echo "VCMI logs: ~/.local/share/vcmi/*.log"
echo "Application logs: /tmp/*.log"
echo ""
echo "To view logs via Railway CLI:"
echo "  railway connect"
echo "  Then run: /usr/local/bin/show-logs"
echo ""

