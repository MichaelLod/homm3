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

# VCMI uses directory name as identifier if no identifier field in mod.json
# Since mod.json doesn't have identifier, we MUST use the directory name
if [ -z "$MOD_ID" ] || [ "$MOD_ID" = "NOT_FOUND" ] || [ "$MOD_ID" = "$HOTA_MOD_NAME" ]; then
    MOD_ID="$HOTA_MOD_NAME"
    echo "⚠️  No identifier in mod.json, using directory name: $MOD_ID" >&2
fi
echo "Using mod identifier: $MOD_ID" >&2
echo "⚠️  IMPORTANT: VCMI uses directory name as mod identifier when mod.json has no 'identifier' field" >&2

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

# Primary approach: Use modSettings with directory name (VCMI standard)
# VCMI uses the directory name as the identifier when mod.json has no identifier field
if "modSettings" not in config:
    config["modSettings"] = {}

# VCMI uses directory name as the key - this is the most important
config["modSettings"][mod_name] = {
    "active": True,
    "enabled": True
}
print(f"   Set modSettings['{mod_name}'] = enabled (using directory name)")

# Also try with mod_id if it's different from mod_name and not NOT_FOUND
if mod_id and mod_id != mod_name and mod_id != "NOT_FOUND":
    config["modSettings"][mod_id] = {
        "active": True,
        "enabled": True
    }
    print(f"   Set modSettings['{mod_id}'] = enabled (from mod.json)")

# Approach 2: activeMods array (VCMI uses this to list active mods)
if "activeMods" not in config:
    config["activeMods"] = []

# Add directory name to activeMods (most important - VCMI uses this)
if mod_name and mod_name not in config["activeMods"]:
    config["activeMods"].append(mod_name)
    print(f"   Added '{mod_name}' to activeMods (directory name)")

# Also add mod_id if it's different and valid
if mod_id and mod_id != mod_name and mod_id != "NOT_FOUND" and mod_id not in config["activeMods"]:
    config["activeMods"].append(mod_id)
    print(f"   Added '{mod_id}' to activeMods (from mod.json)")

# Approach 3: mods array (deprecated but some versions might use it)
if "mods" not in config:
    config["mods"] = []

# Add directory name to mods array (deprecated but some versions use it)
if mod_name and mod_name not in config["mods"]:
    config["mods"].append(mod_name)

# Also add mod_id if valid
if mod_id and mod_id != mod_name and mod_id != "NOT_FOUND" and mod_id not in config["mods"]:
    config["mods"].append(mod_id)

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


