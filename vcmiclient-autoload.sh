#!/bin/bash
# Auto-load latest hotseat save game
# Check if auto-load should be skipped (for new games)
if [ -f "$HOME/.vcmi/skip-autoload" ]; then
    echo "Auto-load skipped (new game requested)"
    rm -f "$HOME/.vcmi/skip-autoload"
    DISPLAY=:1 vcmiclient &
    exit 0
fi

SAVE_DIR="$HOME/.vcmi/Saves"
LATEST_SAVE=$(find "$SAVE_DIR" -type f \( -name "*.vcg" -o -name "*.VCMI" -o -name "*.save" \) -printf "%T@ %p\n" 2>/dev/null | sort -n | tail -1 | cut -d" " -f2-)

if [ -n "$LATEST_SAVE" ] && [ -f "$LATEST_SAVE" ]; then
    echo "Latest save found: $(basename "$LATEST_SAVE")"
    # Start VCMI
    DISPLAY=:1 vcmiclient &
    VCMI_PID=$!
    # Wait for VCMI to start
    sleep 8
    # Auto-navigate menu: Load Game -> Hotseat -> Select latest
    export DISPLAY=:1
    # Press Escape to close any dialogs, then navigate to Load Game
    xdotool search --onlyvisible --name "VCMI" key --window %@ Escape 2>/dev/null || true
    sleep 1
    # Press L for Load Game (if main menu)
    xdotool search --onlyvisible --name "VCMI" key --window %@ l 2>/dev/null || true
    sleep 1
    # Press Down arrow to select Hotseat (usually first option)
    xdotool search --onlyvisible --name "VCMI" key --window %@ Down Return 2>/dev/null || true
    sleep 2
    # Press Home to go to first file, then navigate to last (newest)
    xdotool search --onlyvisible --name "VCMI" key --window %@ Home 2>/dev/null || true
    sleep 0.5
    # Scroll to bottom for latest save
    xdotool search --onlyvisible --name "VCMI" key --window %@ End 2>/dev/null || true
    sleep 0.5
    # Press Return to load
    xdotool search --onlyvisible --name "VCMI" key --window %@ Return 2>/dev/null || true
    echo "Attempted to auto-load save game"
else
    echo "No save game found, starting VCMI normally"
    DISPLAY=:1 vcmiclient &
fi

