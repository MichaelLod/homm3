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

echo "Checking HotA mod structure..."
if [ -d "$MODS_DIR/HotA" ]; then
    echo "HotA mod directory found:"
    ls -la "$MODS_DIR/HotA" | head -10
    if [ -f "$MODS_DIR/HotA/mod.json" ]; then
        echo "✅ mod.json found in HotA directory"
        # Try to get mod identifier from mod.json
        MOD_ID=$(python3 -c "import json; f=open('$MODS_DIR/HotA/mod.json'); d=json.load(f); print(d.get('identifier', '$HOTA_MOD_NAME'))" 2>/dev/null || echo "$HOTA_MOD_NAME")
        echo "Mod identifier: $MOD_ID"
    else
        MOD_ID="$HOTA_MOD_NAME"
        echo "⚠️  mod.json not found, using directory name: $MOD_ID"
    fi
elif [ -d "$MODS_DIR/hota" ]; then
    echo "hota mod directory found:"
    ls -la "$MODS_DIR/hota" | head -10
    if [ -f "$MODS_DIR/hota/mod.json" ]; then
        echo "✅ mod.json found in hota directory"
        MOD_ID=$(python3 -c "import json; f=open('$MODS_DIR/hota/mod.json'); d=json.load(f); print(d.get('identifier', '$HOTA_MOD_NAME'))" 2>/dev/null || echo "$HOTA_MOD_NAME")
        echo "Mod identifier: $MOD_ID"
    else
        MOD_ID="$HOTA_MOD_NAME"
        echo "⚠️  mod.json not found, using directory name: $MOD_ID"
    fi
fi

echo ""
echo "Enabling HotA mod in VCMI configuration..."

# Create or update settings.json to enable HotA mod
python3 << PYEOF
import json
import os

config_file = "$VCMI_CONFIG"
mod_name = "$HOTA_MOD_NAME"
mod_id = "$MOD_ID"

# Create config directory if it doesn't exist
os.makedirs(os.path.dirname(config_file), exist_ok=True)

# Load existing config or create new one
try:
    with open(config_file, "r") as f:
        config = json.load(f)
except:
    config = {}

# VCMI uses different formats depending on version
# Try multiple approaches to enable the mod

# Approach 1: modSettings dictionary
if "modSettings" not in config:
    config["modSettings"] = {}

# Try with both the directory name and the mod identifier
for mod_key in [mod_name, mod_id, "HotA", "hota"]:
    config["modSettings"][mod_key] = {
        "active": True,
        "enabled": True
    }

# Approach 2: mods array/list
if "mods" not in config:
    config["mods"] = []

for mod_key in [mod_name, mod_id, "HotA", "hota"]:
    if mod_key not in config["mods"]:
        config["mods"].append(mod_key)

# Approach 3: activeMods array (some VCMI versions)
if "activeMods" not in config:
    config["activeMods"] = []

for mod_key in [mod_name, mod_id, "HotA", "hota"]:
    if mod_key not in config["activeMods"]:
        config["activeMods"].append(mod_key)

# Save config
with open(config_file, "w") as f:
    json.dump(config, f, indent=2)

print(f"✅ HotA mod enabled in VCMI configuration")
print(f"   Used identifiers: {mod_name}, {mod_id}")
print(f"   Config saved to: {config_file}")
PYEOF

echo ""
echo "Current VCMI config:"
if [ -f "$VCMI_CONFIG" ]; then
    cat "$VCMI_CONFIG" | python3 -m json.tool 2>/dev/null || cat "$VCMI_CONFIG"
else
    echo "⚠️  Config file not found"
fi

echo ""
echo "⚠️  VCMI must be restarted for the mod to take effect!"
echo "   The mod will be active after VCMI restarts."

