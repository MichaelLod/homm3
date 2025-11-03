#!/bin/bash
unset SESSION_MANAGER
unset DBUS_SESSION_BUS_ADDRESS
[ -x /etc/vnc/xstartup ] && exec /etc/vnc/xstartup
[ -r $HOME/.Xresources ] && xrdb $HOME/.Xresources
fluxbox &
sleep 3

# Function to start VCMI
start_vcmi() {
    echo "Starting VCMI..." >&2
    DISPLAY=:1 vcmiclient &
    VCMI_PID=$!
    echo "VCMI started with PID: $VCMI_PID" >&2
}

# Start VCMI automatically (VCMI will automatically resume last game if available)
start_vcmi

# Keep session alive and restart VCMI if it crashes
while true; do
    # Wait a bit before checking
    sleep 5
    
    # Check if VCMI is still running
    if ! kill -0 $VCMI_PID 2>/dev/null; then
        echo "VCMI process ended, restarting..." >&2
        start_vcmi
    fi
    
    # Sleep for a longer period
    sleep 3600
done

