#!/bin/bash
# Start VCMI for new game (skip auto-load)
touch "$HOME/.vcmi/skip-autoload"
DISPLAY=:1 vcmiclient &

