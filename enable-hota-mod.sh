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
MOD_ID=""
if [ -d "$MODS_DIR/HotA" ]; then
    echo "HotA mod directory found:"
    ls -la "$MODS_DIR/HotA" | head -10
    if [ -f "$MODS_DIR/HotA/mod.json" ]; then
        echo "✅ mod.json found in HotA directory"
        echo "Reading mod.json..." >&2
        cat "$MODS_DIR/HotA/mod.json" | head -20 >&2
        # Try to get mod identifier from mod.json (check both 'identifier' and 'id' fields)
        MOD_ID=$(python3 -c "
import json
import sys
try:
    with open('$MODS_DIR/HotA/mod.json', 'r') as f:
        d = json.load(f)
    # Try identifier first, then id, then fallback to directory name
    mod_id = d.get('identifier') or d.get('id') or d.get('name') or '$HOTA_MOD_NAME'
    print(mod_id)
except Exception as e:
    print('$HOTA_MOD_NAME', file=sys.stderr)
" 2>/dev/null || echo "$HOTA_MOD_NAME")
        echo "Mod identifier from mod.json: $MOD_ID" >&2
    else
        MOD_ID="$HOTA_MOD_NAME"
        echo "⚠️  mod.json not found, using directory name: $MOD_ID" >&2
    fi
elif [ -d "$MODS_DIR/hota" ]; then
    echo "hota mod directory found:"
    ls -la "$MODS_DIR/hota" | head -10
    if [ -f "$MODS_DIR/hota/mod.json" ]; then
        echo "✅ mod.json found in hota directory"
        echo "Reading mod.json..." >&2
        cat "$MODS_DIR/hota/mod.json" | head -20 >&2
        # Try to get mod identifier from mod.json
        MOD_ID=$(python3 -c "
import json
import sys
try:
    with open('$MODS_DIR/hota/mod.json', 'r') as f:
        d = json.load(f)
    # Try identifier first, then id, then fallback to directory name
    mod_id = d.get('identifier') or d.get('id') or d.get('name') or '$HOTA_MOD_NAME'
    print(mod_id)
except Exception as e:
    print('$HOTA_MOD_NAME', file=sys.stderr)
" 2>/dev/null || echo "$HOTA_MOD_NAME")
        echo "Mod identifier from mod.json: $MOD_ID" >&2
    else
        MOD_ID="$HOTA_MOD_NAME"
        echo "⚠️  mod.json not found, using directory name: $MOD_ID" >&2
    fi
fi

# Use the identifier from mod.json if found, otherwise use directory name
if [ -z "$MOD_ID" ] || [ "$MOD_ID" = "$HOTA_MOD_NAME" ]; then
    MOD_ID="$HOTA_MOD_NAME"
fi
echo "Using mod identifier: $MOD_ID" >&2

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

# VCMI configuration format based on research
# VCMI uses modSettings with the mod identifier from mod.json
# The key should match the 'identifier' field in mod.json

# Primary approach: Use modSettings with the actual identifier from mod.json
if "modSettings" not in config:
    config["modSettings"] = {}

# Use the identifier from mod.json as the primary key (most important)
if mod_id:
    config["modSettings"][mod_id] = {
        "active": True,
        "enabled": True
    }
    print(f"   Set modSettings['{mod_id}'] = enabled")

# Also set using directory name as fallback
config["modSettings"][mod_name] = {
    "active": True,
    "enabled": True
}
print(f"   Set modSettings['{mod_name}'] = enabled")

# Approach 2: activeMods array (VCMI uses this to list active mods)
if "activeMods" not in config:
    config["activeMods"] = []

# Add both identifier and directory name to activeMods
for mod_key in [mod_id, mod_name]:
    if mod_key and mod_key not in config["activeMods"]:
        config["activeMods"].append(mod_key)
        print(f"   Added '{mod_key}' to activeMods")

# Approach 3: mods array (deprecated but some versions might use it)
if "mods" not in config:
    config["mods"] = []

for mod_key in [mod_id, mod_name]:
    if mod_key and mod_key not in config["mods"]:
        config["mods"].append(mod_key)

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


