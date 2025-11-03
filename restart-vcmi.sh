#!/bin/bash
# Restart VCMI client
# This script kills the current VCMI process and supervisor will restart it

echo "Restarting VCMI..." >&2

# Find and kill VCMI process
pkill -f vcmiclient 2>/dev/null && {
    echo "✅ VCMI process terminated" >&2
    echo "VCMI will be automatically restarted by supervisor..." >&2
} || {
    echo "⚠️  No VCMI process found (may already be stopped)" >&2
}

# Alternative: Restart VNC session (which will restart VCMI)
# This is more aggressive but ensures a clean restart
echo "" >&2
echo "To fully restart VCMI, you can also:" >&2
echo "1. Restart the VNC session (supervisor will restart it)" >&2
echo "2. Or simply wait - supervisor will restart VCMI automatically" >&2

