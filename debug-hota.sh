#!/bin/bash
# Comprehensive HotA mod debugging script
set +e

echo "========================================="
echo "HotA Mod Deep Debug - $(date)"
echo "========================================="
echo ""

# Check mod installation
echo "1. MOD INSTALLATION CHECK"
echo "=========================="
MODS_DIR="$HOME/.vcmi/Mods"
if [ -d "$MODS_DIR/hota" ]; then
    echo "✅ HotA mod directory found: $MODS_DIR/hota"
    echo "   Contents:"
    ls -la "$MODS_DIR/hota" | head -15
    echo ""
    
    if [ -f "$MODS_DIR/hota/mod.json" ]; then
        echo "✅ mod.json found"
        echo "   Key fields:"
        python3 << 'PYEOF'
import json
try:
    with open('$MODS_DIR/hota/mod.json', 'r') as f:
        mod = json.load(f)
    print(f"   Name: {mod.get('name', 'NOT FOUND')}")
    print(f"   Identifier: {mod.get('identifier', 'NOT FOUND')}")
    print(f"   Version: {mod.get('version', 'NOT FOUND')}")
    print(f"   ModType: {mod.get('modType', 'NOT FOUND')}")
except Exception as e:
    print(f"   Error reading mod.json: {e}")
PYEOF
    else
        echo "❌ mod.json NOT found!"
    fi
else
    echo "❌ HotA mod directory NOT found at $MODS_DIR/hota"
fi
echo ""

# Check VCMI configuration
echo "2. VCMI CONFIGURATION CHECK"
echo "============================"
VCMI_CONFIG="$HOME/.config/vcmi/settings.json"
if [ -f "$VCMI_CONFIG" ]; then
    echo "✅ Configuration file exists: $VCMI_CONFIG"
    echo ""
    echo "   Full config:"
    python3 -m json.tool "$VCMI_CONFIG" 2>/dev/null || cat "$VCMI_CONFIG"
    echo ""
    
    echo "   ModSettings section:"
    python3 << 'PYEOF'
import json
try:
    with open('$VCMI_CONFIG', 'r') as f:
        config = json.load(f)
    mod_settings = config.get('modSettings', {})
    if mod_settings:
        print(json.dumps(mod_settings, indent=2))
    else:
        print("   ❌ modSettings is empty or missing!")
        
    # Check specifically for hota
    hota_lower = mod_settings.get('hota', {})
    hota_upper = mod_settings.get('HotA', {})
    if hota_lower:
        print(f"\n   ✅ 'hota' found in modSettings: {hota_lower}")
    elif hota_upper:
        print(f"\n   ✅ 'HotA' found in modSettings: {hota_upper}")
    else:
        print("\n   ❌ Neither 'hota' nor 'HotA' found in modSettings!")
except Exception as e:
    print(f"   Error: {e}")
PYEOF
    echo ""
    
    echo "   activeMods section:"
    python3 << 'PYEOF'
import json
try:
    with open('$VCMI_CONFIG', 'r') as f:
        config = json.load(f)
    active_mods = config.get('activeMods', [])
    if isinstance(active_mods, list):
        if active_mods:
            print(f"   activeMods (array): {active_mods}")
            if 'hota' in active_mods:
                print("   ✅ 'hota' found in activeMods array")
            elif 'HotA' in active_mods:
                print("   ✅ 'HotA' found in activeMods array")
            else:
                print("   ❌ Neither 'hota' nor 'HotA' in activeMods array")
        else:
            print("   ❌ activeMods array is empty!")
    elif isinstance(active_mods, dict):
        print(f"   activeMods (object): {active_mods}")
        if 'hota' in active_mods or 'HotA' in active_mods:
            print("   ✅ HotA found in activeMods object")
        else:
            print("   ❌ HotA not found in activeMods object")
    else:
        print(f"   ⚠️  activeMods is neither array nor object: {type(active_mods)}")
except Exception as e:
    print(f"   Error: {e}")
PYEOF
else
    echo "❌ Configuration file NOT found at $VCMI_CONFIG"
fi
echo ""

# Check VCMI logs
echo "3. VCMI LOGS CHECK"
echo "=================="
VCMI_LOG_DIR="$HOME/.local/share/vcmi"
if [ -d "$VCMI_LOG_DIR" ]; then
    echo "✅ VCMI log directory found: $VCMI_LOG_DIR"
    echo "   Log files:"
    ls -lah "$VCMI_LOG_DIR"/*.log 2>/dev/null | head -5 || echo "   No .log files found"
    echo ""
    
    # Check for mod-related errors in logs
    echo "   Searching for mod-related messages in logs:"
    find "$VCMI_LOG_DIR" -name "*.log" -type f -exec grep -i "mod\|hota\|cove" {} \; 2>/dev/null | head -20 || echo "   No mod-related messages found"
else
    echo "⚠️  VCMI log directory not found at $VCMI_LOG_DIR"
    echo "   Checking alternative locations..."
    ls -la ~/.vcmi/*.log 2>/dev/null | head -5 || echo "   No log files in ~/.vcmi"
fi
echo ""

# Check VCMI process
echo "4. VCMI PROCESS CHECK"
echo "====================="
if pgrep -f vcmiclient > /dev/null; then
    echo "✅ VCMI is running"
    ps aux | grep vcmiclient | grep -v grep
    echo ""
    
    # Check if VCMI has mod-related environment or config
    VCMI_PID=$(pgrep -f vcmiclient | head -1)
    if [ -n "$VCMI_PID" ]; then
        echo "   VCMI PID: $VCMI_PID"
        echo "   Process info:"
        ps -fp $VCMI_PID 2>/dev/null || true
    fi
else
    echo "⚠️  VCMI is not running"
fi
echo ""

# Check mod files structure
echo "5. MOD FILES STRUCTURE CHECK"
echo "============================="
if [ -d "$MODS_DIR/hota" ]; then
    echo "Checking critical HotA files..."
    
    # Check for town files (Cove town)
    if find "$MODS_DIR/hota" -type f -name "*cove*" -o -name "*town*" | head -5 | grep -q .; then
        echo "✅ Found town-related files:"
        find "$MODS_DIR/hota" -type f \( -name "*cove*" -o -name "*town*" \) | head -10
    else
        echo "⚠️  No obvious town files found (might be in subdirectories)"
    fi
    echo ""
    
    # Check mod structure
    echo "Mod directory structure:"
    find "$MODS_DIR/hota" -maxdepth 3 -type d | head -20
    echo ""
    
    # Check for mod.json validation
    echo "Mod.json validation:"
    python3 << 'PYEOF'
import json
import sys
try:
    with open('$MODS_DIR/hota/mod.json', 'r') as f:
        mod = json.load(f)
    
    required_fields = ['name', 'version', 'modType']
    missing = [f for f in required_fields if f not in mod]
    if missing:
        print(f"   ⚠️  Missing required fields: {missing}")
    else:
        print("   ✅ All required fields present")
    
    # Check modType
    if mod.get('modType') == 'Expansion':
        print("   ✅ ModType is 'Expansion' (correct for HotA)")
    else:
        print(f"   ⚠️  ModType is '{mod.get('modType')}' (expected 'Expansion')")
        
except Exception as e:
    print(f"   ❌ Error validating mod.json: {e}")
    sys.exit(1)
PYEOF
fi
echo ""

# Recommendations
echo "6. RECOMMENDATIONS"
echo "=================="
echo "1. Verify mod is enabled in VCMI config (check modSettings and activeMods above)"
echo "2. Restart VCMI after enabling mod (kill and restart)"
echo "3. Start a NEW game (not load existing) - HotA features appear in new games"
echo "4. Use a map that supports HotA/Cove town (not all maps do)"
echo "5. Check VCMI version compatibility with HotA mod version"
echo "6. Try manually enabling in VCMI launcher if available"
echo ""

echo "========================================="
echo "Debug complete"
echo "========================================="

