#!/bin/bash
unset SESSION_MANAGER
unset DBUS_SESSION_BUS_ADDRESS
[ -x /etc/vnc/xstartup ] && exec /etc/vnc/xstartup
[ -r $HOME/.Xresources ] && xrdb $HOME/.Xresources
fluxbox &
sleep 3

# Function to check and enable HOTA mod before starting VCMI
ensure_hota_enabled() {
    echo "Checking HOTA mod status..." >&2
    
    # Check if mods directory is accessible (don't block if /data isn't mounted)
    if [ ! -d "$HOME/.vcmi/Mods" ] 2>/dev/null; then
        echo "ℹ️  Mods directory not accessible yet, skipping HOTA check" >&2
        return 0  # Don't fail, just skip
    fi
    
    # Check if HOTA mod is installed
    if [ -d "$HOME/.vcmi/Mods/HotA" ] || [ -d "$HOME/.vcmi/Mods/hota" ]; then
        echo "✅ HOTA mod found in Mods directory" >&2
        
        # Check if HOTA is already enabled in VCMI config
        VCMI_CONFIG="$HOME/.config/vcmi/settings.json"
        if [ -f "$VCMI_CONFIG" ] 2>/dev/null; then
            # Check if HOTA is enabled in config (with timeout to prevent hanging)
            if timeout 5 python3 -c "
import json
import sys
try:
    with open('$VCMI_CONFIG', 'r') as f:
        config = json.load(f)
    mod_settings = config.get('modSettings', {})
    active_mods = config.get('activeMods', [])
    
    # Handle activeMods as both array and object (VCMI versions differ)
    if isinstance(active_mods, dict):
        active_mods_list = list(active_mods.keys())
    else:
        active_mods_list = active_mods if isinstance(active_mods, list) else []
    
    # Check lowercase "hota" first (VCMI standard), then case variations
    # Primary check: lowercase "hota" in modSettings
    hota_enabled = (
        mod_settings.get('hota', {}).get('enabled', False) or
        mod_settings.get('hota', {}).get('active', False) or
        'hota' in active_mods_list or
        # Fallback to case variations for compatibility
        mod_settings.get('HotA', {}).get('enabled', False) or
        mod_settings.get('HotA', {}).get('active', False) or
        'HotA' in active_mods_list
    )
    sys.exit(0 if hota_enabled else 1)
except:
    sys.exit(1)
" 2>/dev/null; then
                echo "✅ HOTA mod already enabled in VCMI config" >&2
                return 0
            else
                echo "⚠️  HOTA mod installed but not enabled, enabling now..." >&2
            fi
        else
            echo "⚠️  VCMI config not found, will enable HOTA mod..." >&2
        fi
        
        # Enable HOTA mod using the enable script (with timeout to prevent hanging)
        if [ -f /usr/local/bin/enable-hota-mod ]; then
            timeout 30 /usr/local/bin/enable-hota-mod >&2
            ENABLE_EXIT=$?
            if [ $ENABLE_EXIT -eq 0 ]; then
                echo "✅ HOTA mod enabled successfully" >&2
                # Small wait to ensure config file is fully written
                sleep 1
                return 0
            elif [ $ENABLE_EXIT -eq 124 ]; then
                echo "⚠️  HOTA mod enable script timed out (non-fatal)" >&2
                return 0  # Don't fail startup, just continue
            else
                echo "⚠️  Failed to enable HOTA mod automatically (non-fatal)" >&2
                return 0  # Don't fail startup, just continue
            fi
        else
            echo "⚠️  enable-hota-mod script not found (non-fatal)" >&2
            return 0  # Don't fail startup
        fi
    else
        echo "ℹ️  HOTA mod not found in Mods directory" >&2
        echo "   Install it using: /setup-hota-mod.sh or /install-hota.sh" >&2
        return 0  # Not an error if mod isn't installed
    fi
}

# Function to start VCMI
start_vcmi() {
    echo "Starting VCMI..." >&2
    # Wait a bit to ensure X server is fully ready
    sleep 2
    DISPLAY=:1 vcmiclient &
    VCMI_PID=$!
    echo "VCMI started with PID: $VCMI_PID" >&2
    return 0
}

# Function to force quit and restart VCMI
force_restart_vcmi() {
    echo "Force quitting VCMI to restart..." >&2
    # Kill all VCMI processes (force quit)
    pkill -9 -f vcmiclient 2>/dev/null || true
    sleep 2
    echo "Restarting VCMI..." >&2
    start_vcmi
}

# Ensure HOTA mod is enabled before starting VCMI
# Give it a moment for X server to be ready
sleep 5

# Wait a bit if HOTA installation is in progress (from background task in start.sh)
# Use timeout to prevent hanging if /data isn't mounted
if [ -d /data ] && [ -f /data/mods/.hota-install-queued ] 2>/dev/null; then
    echo "⏳ HOTA installation in progress, waiting up to 30 seconds..." >&2
    # Reduced wait time and use timeout to prevent blocking
    for i in {1..6}; do
        sleep 5
        if [ ! -f /data/mods/.hota-install-queued ] 2>/dev/null; then
            echo "✅ HOTA installation completed" >&2
            break
        fi
    done
    # Give it a moment for the enable script to run
    sleep 2
fi

# Check and enable HOTA mod before starting VCMI
# Don't block if /data isn't available or mod isn't installed
ensure_hota_enabled

# Verify and fix mod configuration if needed (non-blocking)
if [ -f /usr/local/bin/test-vcmi-mod-loading ]; then
    timeout 10 /usr/local/bin/test-vcmi-mod-loading >&2 || echo "⚠️  Mod loading test timed out or failed (non-fatal)" >&2
fi

# Start VCMI automatically (VCMI will automatically resume last game if available)
# HOTA mod should now be loaded automatically
start_vcmi

# Keep session alive and restart VCMI if it crashes or exits
while true; do
    # Wait a bit before checking
    sleep 5
    
    # Check if VCMI process is still running
    if ! kill -0 $VCMI_PID 2>/dev/null; then
        # Process has ended, wait for it to fully exit and get exit code
        wait $VCMI_PID 2>/dev/null || true
        EXIT_CODE=$?
        echo "VCMI process ended (exit code: $EXIT_CODE), restarting in 2 seconds..." >&2
        sleep 2
        start_vcmi
    fi
    
    # Check if VCMI is stuck or showing quit dialog (optional - could use xdotool to detect dialogs)
    # For now, just rely on the process check above
    
    # Sleep for a shorter period for more responsive restart
    sleep 5
done

