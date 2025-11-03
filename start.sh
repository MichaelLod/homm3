#!/bin/bash
# Don't use set -e - we want to continue even if some operations fail
set +e

# Create VNC password file if it doesn't exist
if [ ! -f ~/.vnc/passwd ]; then
    mkdir -p ~/.vnc
    echo "${VNC_PASSWORD:-password}" | vncpasswd -f > ~/.vnc/passwd
    chmod 600 ~/.vnc/passwd
fi

# Ensure directories exist
mkdir -p /data || true

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

# Auto-download HoMM3 files if not present (run in background after supervisor starts)
if [ ! -d /data/Data ] || ! ls /data/Data/*.{lod,snd,vid} >/dev/null 2>&1; then
    echo "HoMM3 files not found, will attempt automatic download after startup..."
    touch /data/.homm3-download-queued 2>/dev/null || true
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

# Auto-install HotA mod if not already installed (only once)
# Run in background to not block startup, and don't fail if it errors
# Note: This runs AFTER supervisor starts, so it won't block container startup
if [ ! -d /data/mods/HotA ] && [ ! -d /data/mods/hota ] && [ ! -f /data/mods/.hota-installed ]; then
    echo "HotA mod not found, will attempt automatic installation after startup..."
    # Mark as attempted so we don't try multiple times
    touch /data/mods/.hota-install-queued 2>/dev/null || true
elif [ -d /data/mods/HotA ] || [ -d /data/mods/hota ]; then
    # HotA is already installed, but ensure it's enabled in VCMI config
    if [ ! -f /data/mods/.hota-enabled ]; then
        echo "HotA mod found, will enable it in VCMI configuration after startup..."
        touch /data/mods/.hota-enable-queued 2>/dev/null || true
    fi
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

# Start file downloads in background if queued (after supervisor starts)
if [ -f /data/.homm3-download-queued ] || [ -f /data/mods/.hota-install-queued ] || [ -f /data/mods/.hota-enable-queued ]; then
    (
        sleep 10  # Wait for supervisor to be ready
        
        # Download HoMM3 files if queued
        if [ -f /data/.homm3-download-queued ]; then
            echo "Starting HoMM3 files download..." >&2
            /usr/local/bin/download-homm3-files 2>&1 | tee /tmp/homm3-download.log || echo "HoMM3 download failed, check /tmp/homm3-download.log" >&2
            rm -f /data/.homm3-download-queued 2>/dev/null || true
            
            # Note: download-homm3-files.sh already copies to VCMI standard location
            # This is just a fallback in case the copy in the script failed
            if [ -d /data/Data ] && ls /data/Data/*.{lod,snd,vid} >/dev/null 2>&1; then
                mkdir -p /usr/share/games/vcmi/Data
                cp -u /data/Data/*.lod /data/Data/*.snd /data/Data/*.vid /usr/share/games/vcmi/Data/ 2>/dev/null || true
                echo "✅ HoMM3 files available at /usr/share/games/vcmi/Data/ (VCMI standard location)" >&2
            fi
        fi
        
        # Install HotA mod if queued
        if [ -f /data/mods/.hota-install-queued ]; then
            echo "Starting HotA installation..." >&2
            /install-hota.sh 2>&1 | tee /tmp/hota-install.log || echo "HotA installation failed, check /tmp/hota-install.log" >&2
            rm -f /data/mods/.hota-install-queued 2>/dev/null || true
            touch /data/mods/.hota-installed 2>/dev/null || true
            
            # Try to enable HotA mod if it was successfully installed
            if [ -d /data/mods/HotA ] || [ -d /data/mods/hota ]; then
                echo "Attempting to enable HotA mod in VCMI configuration..." >&2
                /usr/local/bin/enable-hota-mod 2>&1 | tee /tmp/hota-enable.log || echo "Could not enable HotA mod automatically" >&2
                touch /data/mods/.hota-enabled 2>/dev/null || true
            fi
        fi
        
        # Enable HotA mod if queued (for already installed mods)
        if [ -f /data/mods/.hota-enable-queued ]; then
            echo "Enabling already installed HotA mod in VCMI configuration..." >&2
            /usr/local/bin/enable-hota-mod 2>&1 | tee /tmp/hota-enable.log || echo "Could not enable HotA mod automatically" >&2
            rm -f /data/mods/.hota-enable-queued 2>/dev/null || true
            touch /data/mods/.hota-enabled 2>/dev/null || true
        fi
    ) &
fi

# Start supervisor (which will start VNC and noVNC)
echo "Starting supervisor..." >&2
if [ ! -f /usr/bin/supervisord ]; then
    echo "ERROR: supervisord not found at /usr/bin/supervisord" >&2
    exit 1
fi
if [ ! -f /etc/supervisor/conf.d/supervisord.conf ]; then
    echo "ERROR: supervisord.conf not found" >&2
    exit 1
fi

# Start supervisor in foreground (this is the main process)
exec /usr/bin/supervisord -c /etc/supervisor/conf.d/supervisord.conf -n

