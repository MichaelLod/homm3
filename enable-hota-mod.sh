#!/bin/bash
# Enable HotA mod in VCMI configuration
set +e

VCMI_CONFIG="$HOME/.config/vcmi/settings.json"
MODS_DIR="$HOME/.vcmi/Mods"

# Check if HotA mod is installed
if [ ! -d "$MODS_DIR/HotA" ] && [ ! -d "$MODS_DIR/hota" ]; then
    echo "⚠️  HotA mod not found in $MODS_DIR"
    exit 0
fi

# Determine HotA mod name
if [ -d "$MODS_DIR/HotA" ]; then
    HOTA_MOD_NAME="HotA"
elif [ -d "$MODS_DIR/hota" ]; then
    HOTA_MOD_NAME="hota"
else
    echo "⚠️  Could not determine HotA mod name"
    exit 0
fi

echo "Enabling HotA mod in VCMI configuration..."

# Create or update settings.json to enable HotA mod
python3 << PYEOF
import json
import os

config_file = "$VCMI_CONFIG"
mod_name = "$HOTA_MOD_NAME"

# Create config directory if it doesn't exist
os.makedirs(os.path.dirname(config_file), exist_ok=True)

# Load existing config or create new one
try:
    with open(config_file, "r") as f:
        config = json.load(f)
except:
    config = {}

# Initialize modSettings if not present
if "modSettings" not in config:
    config["modSettings"] = {}

# Enable HotA mod
config["modSettings"][mod_name] = {
    "active": True,
    "enabled": True
}

# Also check for mods array/list format (some VCMI versions use this)
if "mods" not in config:
    config["mods"] = []

if mod_name not in config["mods"]:
    config["mods"].append(mod_name)

# Save config
with open(config_file, "w") as f:
    json.dump(config, f, indent=2)

print(f"✅ HotA mod ({mod_name}) enabled in VCMI configuration")
PYEOF

echo ""
echo "Note: You may need to restart VCMI for the mod to take effect."

