#!/bin/bash
# Test and verify VCMI mod loading
set +e

echo "========================================="
echo "VCMI Mod Loading Test"
echo "========================================="
echo ""

# Check if VCMI can see the mod
echo "1. Checking if VCMI can detect the mod..."
MODS_DIR="$HOME/.vcmi/Mods"
VCMI_CONFIG="$HOME/.config/vcmi/settings.json"

if [ ! -d "$MODS_DIR/hota" ] && [ ! -d "$MODS_DIR/HotA" ]; then
    echo "❌ HotA mod not found in $MODS_DIR"
    exit 1
fi

echo "✅ Mod directory exists"
echo ""

# Verify config format
echo "2. Verifying configuration format..."
if [ -f "$VCMI_CONFIG" ]; then
    # Check if modSettings has the right format
    python3 << 'PYEOF'
import json
import sys

try:
    with open('$VCMI_CONFIG', 'r') as f:
        config = json.load(f)
    
    mod_settings = config.get('modSettings', {})
    active_mods = config.get('activeMods', [])
    
    # Check for lowercase hota
    hota_config = mod_settings.get('hota', {})
    if hota_config:
        print(f"✅ Found 'hota' in modSettings: {hota_config}")
        if hota_config.get('active') or hota_config.get('enabled'):
            print("   ✅ Mod is marked as active/enabled")
        else:
            print("   ❌ Mod is NOT marked as active/enabled!")
            print("   Fixing...")
            hota_config['active'] = True
            hota_config['enabled'] = True
            mod_settings['hota'] = hota_config
            config['modSettings'] = mod_settings
            with open('$VCMI_CONFIG', 'w') as f:
                json.dump(config, f, indent=2)
            print("   ✅ Fixed configuration")
    else:
        print("❌ 'hota' not found in modSettings")
        print("   Adding it...")
        if 'modSettings' not in config:
            config['modSettings'] = {}
        config['modSettings']['hota'] = {
            'active': True,
            'enabled': True
        }
        with open('$VCMI_CONFIG', 'w') as f:
            json.dump(config, f, indent=2)
        print("   ✅ Added 'hota' to modSettings")
    
    # Check activeMods
    if isinstance(active_mods, list):
        if 'hota' not in active_mods:
            print("❌ 'hota' not in activeMods array")
            print("   Adding it...")
            active_mods.append('hota')
            config['activeMods'] = active_mods
            with open('$VCMI_CONFIG', 'w') as f:
                json.dump(config, f, indent=2)
            print("   ✅ Added 'hota' to activeMods")
        else:
            print("✅ 'hota' found in activeMods")
    else:
        print("⚠️  activeMods is not an array, converting...")
        config['activeMods'] = ['hota']
        with open('$VCMI_CONFIG', 'w') as f:
            json.dump(config, f, indent=2)
        print("   ✅ Created activeMods array with 'hota'")
        
except Exception as e:
    print(f"❌ Error: {e}")
    sys.exit(1)
PYEOF
else
    echo "⚠️  Config file doesn't exist, creating..."
    mkdir -p "$(dirname "$VCMI_CONFIG")"
    cat > "$VCMI_CONFIG" << 'EOF'
{
  "modSettings": {
    "hota": {
      "active": true,
      "enabled": true
    }
  },
  "activeMods": [
    "hota"
  ]
}
EOF
    echo "✅ Created config file with HotA enabled"
fi
echo ""

# Check mod.json for required fields
echo "3. Verifying mod.json structure..."
if [ -f "$MODS_DIR/hota/mod.json" ]; then
    python3 << 'PYEOF'
import json
import sys

try:
    with open('$MODS_DIR/hota/mod.json', 'r') as f:
        mod = json.load(f)
    
    print(f"   Name: {mod.get('name')}")
    print(f"   Version: {mod.get('version')}")
    print(f"   ModType: {mod.get('modType')}")
    
    if mod.get('modType') != 'Expansion':
        print("   ⚠️  Warning: modType is not 'Expansion'")
    
    # Check if mod has required structure
    if 'name' in mod and 'version' in mod:
        print("   ✅ mod.json has required fields")
    else:
        print("   ❌ mod.json missing required fields")
        
except Exception as e:
    print(f"   ❌ Error reading mod.json: {e}")
    sys.exit(1)
PYEOF
fi
echo ""

# Final verification
echo "4. Final configuration check..."
echo "   Current settings.json modSettings:"
python3 << 'PYEOF'
import json
try:
    with open('$VCMI_CONFIG', 'r') as f:
        config = json.load(f)
    print(json.dumps(config.get('modSettings', {}), indent=2))
    print("\n   activeMods:")
    print(json.dumps(config.get('activeMods', []), indent=2))
except Exception as e:
    print(f"Error: {e}")
PYEOF

echo ""
echo "========================================="
echo "Next steps:"
echo "1. Restart VCMI (kill and let it restart)"
echo "2. Start a NEW game (not load existing)"
echo "3. Check if Cove town is available"
echo "4. Run: /usr/local/bin/debug-hota for detailed diagnostics"
echo "========================================="

