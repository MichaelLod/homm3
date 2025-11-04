#!/bin/bash
# Commands to run via Railway CLI to debug HotA mod
# Usage: railway connect, then run these commands

echo "========================================="
echo "Railway CLI Debug Commands"
echo "========================================="
echo ""
echo "Run these commands after: railway connect"
echo ""

cat << 'EOF'
# 1. Check VCMI configuration
echo "=== VCMI Configuration ==="
cat ~/.config/vcmi/settings.json | python3 -m json.tool

# 2. Check mod directory
echo ""
echo "=== Mod Directory ==="
ls -la ~/.vcmi/Mods/
ls -la ~/.vcmi/Mods/hota/ | head -20

# 3. Check mod.json
echo ""
echo "=== Mod.json ==="
cat ~/.vcmi/Mods/hota/mod.json | python3 -m json.tool | head -30

# 4. Check if mod is in config
echo ""
echo "=== Mod Settings Check ==="
python3 << 'PYEOF'
import json
try:
    with open('/root/.config/vcmi/settings.json', 'r') as f:
        config = json.load(f)
    print("modSettings:")
    print(json.dumps(config.get('modSettings', {}), indent=2))
    print("\nactiveMods:")
    print(json.dumps(config.get('activeMods', []), indent=2))
    
    # Check specifically for hota
    mod_settings = config.get('modSettings', {})
    if 'hota' in mod_settings:
        print("\n✅ 'hota' found in modSettings")
        print(f"   Value: {mod_settings['hota']}")
    else:
        print("\n❌ 'hota' NOT found in modSettings")
        print(f"   Available keys: {list(mod_settings.keys())}")
    
    active_mods = config.get('activeMods', [])
    if 'hota' in active_mods:
        print("\n✅ 'hota' found in activeMods")
    else:
        print("\n❌ 'hota' NOT found in activeMods")
        print(f"   Available: {active_mods}")
except Exception as e:
    print(f"Error: {e}")
PYEOF

# 5. Check VCMI logs
echo ""
echo "=== VCMI Logs (mod-related) ==="
find ~/.local/share/vcmi -name "*.log" -type f 2>/dev/null | head -5
find ~/.local/share/vcmi -name "*.log" -type f -exec grep -i "mod\|hota\|error" {} \; 2>/dev/null | head -20

# 6. Check VCMI process
echo ""
echo "=== VCMI Process ==="
ps aux | grep vcmiclient | grep -v grep

# 7. Re-enable mod with correct format
echo ""
echo "=== Re-enabling HotA mod ==="
/usr/local/bin/enable-hota-mod

# 8. Run comprehensive debug
echo ""
echo "=== Comprehensive Debug ==="
/usr/local/bin/debug-hota

EOF

echo ""
echo "========================================="
echo "Or run the automated script:"
echo "/usr/local/bin/test-vcmi-mod-loading"
echo "========================================="

