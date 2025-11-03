#!/bin/bash
set -e

# Create VNC password file if it doesn't exist
if [ ! -f ~/.vnc/passwd ]; then
    mkdir -p ~/.vnc
    echo "${VNC_PASSWORD:-password}" | vncpasswd -f > ~/.vnc/passwd
    chmod 600 ~/.vnc/passwd
fi

# Ensure directories exist
mkdir -p /data

# Set up VCMI directory structure
mkdir -p ~/.vcmi

# All data in one volume: /data with subdirectories
# Structure: /data/Data (game files), /data/mods (mods), /data/saves (savegames), /data/config (config)

# Link game data directory to persistent storage
# Users will upload game files to /data/Data which persists across deployments
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

# Copy game files to VCMI standard location (/usr/share/games/vcmi/Data)
# VCMI checks standard system paths before ~/.vcmi/Data
mkdir -p /usr/share/games/vcmi/Data
if [ -d /data/Data ] && ls /data/Data/*.{lod,snd,vid} >/dev/null 2>&1; then
    # Copy game files if they exist in persistent storage
    cp -u /data/Data/*.lod /data/Data/*.snd /data/Data/*.vid /usr/share/games/vcmi/Data/ 2>/dev/null || true
fi

# Link save directory to persistent storage (in /data volume)
if [ ! -L ~/.vcmi/Saves ]; then
    mkdir -p /data/saves
    if [ -d ~/.vcmi/Saves ] && [ ! -L ~/.vcmi/Saves ]; then
        mv ~/.vcmi/Saves/* /data/saves/ 2>/dev/null || true
        rmdir ~/.vcmi/Saves
    fi
    ln -sf /data/saves ~/.vcmi/Saves
fi

# Link mods directory to persistent storage (in /data volume)
if [ ! -L ~/.vcmi/Mods ]; then
    mkdir -p /data/mods
    if [ -d ~/.vcmi/Mods ] && [ ! -L ~/.vcmi/Mods ]; then
        mv ~/.vcmi/Mods/* /data/mods/ 2>/dev/null || true
        rmdir ~/.vcmi/Mods
    fi
    ln -sf /data/mods ~/.vcmi/Mods
fi

# Create VCMI config directory link (also in /data volume)
if [ ! -L ~/.config/vcmi ]; then
    mkdir -p ~/.config /data/config
    if [ -d ~/.config/vcmi ] && [ ! -L ~/.config/vcmi ]; then
        mv ~/.config/vcmi/* /data/config/ 2>/dev/null || true
        rmdir ~/.config/vcmi
    fi
    ln -sf /data/config ~/.config/vcmi
fi

# Set up VCMI to run in fullscreen mode by default
mkdir -p ~/.config/vcmi
if [ ! -f ~/.config/vcmi/settings.json ] || ! grep -q '"fullscreen"' ~/.config/vcmi/settings.json 2>/dev/null; then
    # Create or update settings.json to enable fullscreen
    if [ -f ~/.config/vcmi/settings.json ]; then
        # Update existing config using jq if available, or create a new one
        cat > /tmp/vcmi_settings.json << 'EOFJSON'
{
    "video": {
      "fullscreen": true,
      "realFullscreen": false,
      "resolution": {
        "width": 1920,
        "height": 1080
      }
    }
}
EOFJSON
        # Merge with existing config if it has content, otherwise use new one
        if [ -s ~/.config/vcmi/settings.json ]; then
            # Try to merge (simple approach - just ensure fullscreen is set)
            python3 << 'PYEOF'
import json
import sys
try:
    with open("/root/.config/vcmi/settings.json", "r") as f:
        config = json.load(f)
except:
    config = {}
if "video" not in config:
    config["video"] = {}
config["video"]["fullscreen"] = True
config["video"]["realFullscreen"] = False
if "resolution" not in config["video"]:
    config["video"]["resolution"] = {"width": 1920, "height": 1080}
with open("/root/.config/vcmi/settings.json", "w") as f:
    json.dump(config, f, indent=2)
PYEOF
        else
            cp /tmp/vcmi_settings.json ~/.config/vcmi/settings.json
        fi
    else
        cat > ~/.config/vcmi/settings.json << 'EOFJSON'
{
    "video": {
      "fullscreen": true,
      "realFullscreen": false,
      "resolution": {
        "width": 1920,
        "height": 1080
      }
    }
}
EOFJSON
    fi
fi

# Create desktop launcher
/create-desktop.sh

# Ensure PORT is set (Railway provides this, default to 6080)
export PORT="${PORT:-6080}"

# Start supervisor (which will start VNC and noVNC)
exec /usr/bin/supervisord -c /etc/supervisor/conf.d/supervisord.conf

