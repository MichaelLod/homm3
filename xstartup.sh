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
    # Wait a bit to ensure X server is fully ready
    sleep 2
    DISPLAY=:1 vcmiclient &
    VCMI_PID=$!
    echo "VCMI started with PID: $VCMI_PID" >&2
    return 0
}

# Start VCMI automatically (VCMI will automatically resume last game if available)
# Give it a moment for X server to be ready
sleep 5
start_vcmi

# Keep session alive and restart VCMI if it crashes or exits
while true; do
    # Wait a bit before checking
    sleep 5
    
    # Check if VCMI process is still running
    # Use wait instead of kill -0 to catch the exit status
    if ! kill -0 $VCMI_PID 2>/dev/null; then
        # Process has ended, wait for it to fully exit and get exit code
        wait $VCMI_PID 2>/dev/null
        EXIT_CODE=$?
        echo "VCMI process ended (exit code: $EXIT_CODE), restarting in 3 seconds..." >&2
        sleep 3
        start_vcmi
    fi
    
    # Sleep for a shorter period for more responsive restart
    sleep 5
done

