#!/bin/bash
unset SESSION_MANAGER
unset DBUS_SESSION_BUS_ADDRESS
[ -x /etc/vnc/xstartup ] && exec /etc/vnc/xstartup
[ -r $HOME/.Xresources ] && xrdb $HOME/.Xresources
fluxbox &
sleep 3
# Start VCMI automatically (VCMI will automatically resume last game if available)
DISPLAY=:1 vcmiclient &
# Keep session alive
while true; do sleep 3600; done

