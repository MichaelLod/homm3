#!/bin/bash
set -e

# Create VNC password file if it doesn't exist
if [ ! -f ~/.vnc/passwd ]; then
    mkdir -p ~/.vnc
    echo "${VNC_PASSWORD:-password}" | vncpasswd -f > ~/.vnc/passwd
    chmod 600 ~/.vnc/passwd
fi

# Ensure directories exist
mkdir -p /data /app/saves /app/config

# Set up VCMI directory structure
mkdir -p ~/.vcmi

# Link game data directory to persistent storage
# Users will upload game files to /data which persists across deployments
if [ ! -L ~/.vcmi/Data ]; then
    if [ -d ~/.vcmi/Data ] && [ ! -L ~/.vcmi/Data ]; then
        # If directory exists and isn't a link, move contents to /data
        mkdir -p /data/Data
        mv ~/.vcmi/Data/* /data/Data/ 2>/dev/null || true
        rmdir ~/.vcmi/Data
    fi
    # Link to persistent storage location
    mkdir -p /data/Data
    ln -sf /data/Data ~/.vcmi/Data
fi

# Link save directory to persistent storage
if [ ! -L ~/.vcmi/Saves ]; then
    mkdir -p /app/saves
    ln -sf /app/saves ~/.vcmi/Saves
fi

# Create VCMI config directory link
if [ ! -L ~/.config/vcmi ]; then
    mkdir -p ~/.config
    if [ -d ~/.config/vcmi ] && [ ! -L ~/.config/vcmi ]; then
        mv ~/.config/vcmi/* /app/config/ 2>/dev/null || true
        rmdir ~/.config/vcmi
    fi
    ln -sf /app/config ~/.config/vcmi
fi

# Create desktop launcher
/create-desktop.sh

# Ensure PORT is set (Railway provides this, default to 6080)
export PORT="${PORT:-6080}"

# Start supervisor (which will start VNC and noVNC)
exec /usr/bin/supervisord -c /etc/supervisor/conf.d/supervisord.conf

