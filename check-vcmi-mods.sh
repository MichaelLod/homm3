#!/bin/bash
# Diagnostic script to check VCMI mod configuration
set +e

echo "========================================="
echo "VCMI Mod Configuration Diagnostic"
echo "========================================="
echo ""

VCMI_CONFIG="$HOME/.config/vcmi/settings.json"
MODS_DIR="$HOME/.vcmi/Mods"

echo "1. Checking mod directory structure..."
echo "   Mods directory: $MODS_DIR"
if [ -d "$MODS_DIR" ]; then
    echo "   ✅ Mods directory exists"
    echo "   Contents:"
    ls -la "$MODS_DIR" | head -10
else
    echo "   ❌ Mods directory not found!"
fi

echo ""
echo "2. Checking for HotA mod..."
if [ -d "$MODS_DIR/hota" ]; then
    echo "   ✅ HotA mod found at: $MODS_DIR/hota"
    echo "   Structure:"
    ls -la "$MODS_DIR/hota" | head -10
    
    if [ -f "$MODS_DIR/hota/mod.json" ]; then
        echo "   ✅ mod.json found"
        echo "   mod.json content:"
        cat "$MODS_DIR/hota/mod.json" | head -30
        
        # Extract identifier
        MOD_ID=$(python3 -c "import json; f=open('$MODS_DIR/hota/mod.json'); d=json.load(f); print(d.get('identifier', 'NOT_FOUND'))" 2>/dev/null)
        echo ""
        echo "   Mod identifier from mod.json: $MOD_ID"
    else
        echo "   ❌ mod.json not found!"
    fi
elif [ -d "$MODS_DIR/HotA" ]; then
    echo "   ✅ HotA mod found at: $MODS_DIR/HotA"
    if [ -f "$MODS_DIR/HotA/mod.json" ]; then
        echo "   ✅ mod.json found"
        MOD_ID=$(python3 -c "import json; f=open('$MODS_DIR/HotA/mod.json'); d=json.load(f); print(d.get('identifier', 'NOT_FOUND'))" 2>/dev/null)
        echo "   Mod identifier from mod.json: $MOD_ID"
    fi
else
    echo "   ❌ HotA mod not found!"
fi

echo ""
echo "3. Checking VCMI configuration..."
if [ -f "$VCMI_CONFIG" ]; then
    echo "   ✅ Configuration file exists: $VCMI_CONFIG"
    echo "   Configuration content:"
    cat "$VCMI_CONFIG" | python3 -m json.tool 2>/dev/null || cat "$VCMI_CONFIG"
    
    # Check if modSettings exists
    if python3 -c "import json; f=open('$VCMI_CONFIG'); d=json.load(f); print('modSettings' in d)" 2>/dev/null | grep -q True; then
        echo ""
        echo "   ✅ modSettings found in config"
        echo "   modSettings content:"
        python3 -c "import json; f=open('$VCMI_CONFIG'); d=json.load(f); print(json.dumps(d.get('modSettings', {}), indent=2))" 2>/dev/null
    else
        echo "   ❌ modSettings not found in config!"
    fi
    
    # Check if activeMods exists
    if python3 -c "import json; f=open('$VCMI_CONFIG'); d=json.load(f); print('activeMods' in d)" 2>/dev/null | grep -q True; then
        echo ""
        echo "   ✅ activeMods found in config"
        echo "   activeMods content:"
        python3 -c "import json; f=open('$VCMI_CONFIG'); d=json.load(f); print(json.dumps(d.get('activeMods', []), indent=2))" 2>/dev/null
    else
        echo "   ❌ activeMods not found in config!"
    fi
else
    echo "   ❌ Configuration file not found!"
fi

echo ""
echo "4. Checking VCMI process..."
if pgrep -f vcmiclient > /dev/null; then
    echo "   ✅ VCMI is running"
    ps aux | grep vcmiclient | grep -v grep
else
    echo "   ⚠️  VCMI is not running"
fi

echo ""
echo "========================================="
echo "Diagnostic complete"
echo "========================================="

