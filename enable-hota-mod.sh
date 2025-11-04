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
# VCMI typically uses lowercase directory names as identifiers
if [ -d "$MODS_DIR/hota" ]; then
    HOTA_MOD_NAME="hota"
elif [ -d "$MODS_DIR/HotA" ]; then
    HOTA_MOD_NAME="HotA"
else
    echo "⚠️  Could not determine HotA mod name"
    exit 0
fi

# Always use lowercase for VCMI mod identifier (VCMI is case-sensitive but prefers lowercase)
# This ensures consistency with VCMI's mod loading system
HOTA_MOD_IDENTIFIER="hota"

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
# Use lowercase "hota" as the identifier (VCMI prefers lowercase for mod identifiers)
if [ -z "$MOD_ID" ] || [ "$MOD_ID" = "NOT_FOUND" ]; then
    MOD_ID="$HOTA_MOD_IDENTIFIER"
    echo "⚠️  No identifier in mod.json, using lowercase 'hota' as identifier: $MOD_ID" >&2
else
    # If mod.json has an identifier, use it but also ensure lowercase version is set
    MOD_ID="$HOTA_MOD_IDENTIFIER"
    echo "Using mod identifier: $MOD_ID (lowercase for VCMI compatibility)" >&2
fi
echo "Using mod identifier: $MOD_ID" >&2
echo "⚠️  IMPORTANT: VCMI uses lowercase directory name as mod identifier" >&2

echo ""
echo "Enabling HotA mod in VCMI configuration..."

# Create or update settings.json to enable HotA mod
python3 << PYEOF
import json
import os

config_file = "$VCMI_CONFIG"
mod_name = "$HOTA_MOD_NAME"
mod_id = "$MOD_ID"
# Always use lowercase "hota" as the primary identifier for VCMI
hota_identifier = "hota"

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

# VCMI uses lowercase "hota" as the identifier - this is the most important
# Set it with lowercase first (primary)
config["modSettings"][hota_identifier] = {
    "active": True,
    "enabled": True
}
print(f"   Set modSettings['{hota_identifier}'] = enabled (lowercase identifier)")

# Also set with directory name if different (for compatibility)
if mod_name and mod_name.lower() != hota_identifier:
    config["modSettings"][mod_name] = {
        "active": True,
        "enabled": True
    }
    print(f"   Set modSettings['{mod_name}'] = enabled (directory name)")

# Approach 2: activeMods array (VCMI uses this to list active mods)
if "activeMods" not in config:
    config["activeMods"] = []

# Add lowercase "hota" to activeMods (most important - VCMI uses this)
if hota_identifier not in config["activeMods"]:
    config["activeMods"].append(hota_identifier)
    print(f"   Added '{hota_identifier}' to activeMods (lowercase identifier)")

# Also add directory name if different (for compatibility)
if mod_name and mod_name.lower() != hota_identifier and mod_name not in config["activeMods"]:
    config["activeMods"].append(mod_name)
    print(f"   Added '{mod_name}' to activeMods (directory name)")

# Approach 3: mods array (deprecated but some versions might use it)
if "mods" not in config:
    config["mods"] = []

# Add lowercase "hota" to mods array (deprecated but some versions use it)
if hota_identifier not in config["mods"]:
    config["mods"].append(hota_identifier)

# Also add directory name if different (for compatibility)
if mod_name and mod_name.lower() != hota_identifier and mod_name not in config["mods"]:
    config["mods"].append(mod_name)

# Save config
with open(config_file, "w") as f:
    json.dump(config, f, indent=2)

print(f"✅ HotA mod enabled in VCMI configuration")
print(f"   Primary identifier: {hota_identifier} (lowercase)")
print(f"   Directory name: {mod_name}")
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


