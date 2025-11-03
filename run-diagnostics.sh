#!/bin/bash
# Run diagnostics and save to file
OUTPUT_FILE="/tmp/vcmi-diagnostics.txt"

echo "=========================================" > "$OUTPUT_FILE"
echo "VCMI Mod Diagnostics - $(date)" >> "$OUTPUT_FILE"
echo "=========================================" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

echo "1. Checking /data volume..." >> "$OUTPUT_FILE"
ls -la /data 2>&1 >> "$OUTPUT_FILE" || echo "/data does not exist" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

echo "2. Checking /data/mods..." >> "$OUTPUT_FILE"
ls -la /data/mods/ 2>&1 >> "$OUTPUT_FILE" || echo "/data/mods does not exist" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

echo "3. Checking HotA mod..." >> "$OUTPUT_FILE"
if [ -d /data/mods/hota ]; then
    echo "HotA mod found!" >> "$OUTPUT_FILE"
    ls -la /data/mods/hota/ | head -10 >> "$OUTPUT_FILE"
    echo "" >> "$OUTPUT_FILE"
    if [ -f /data/mods/hota/mod.json ]; then
        echo "mod.json content:" >> "$OUTPUT_FILE"
        cat /data/mods/hota/mod.json >> "$OUTPUT_FILE"
    fi
else
    echo "HotA mod NOT found" >> "$OUTPUT_FILE"
fi
echo "" >> "$OUTPUT_FILE"

echo "4. Checking ~/.vcmi/Mods symlink..." >> "$OUTPUT_FILE"
ls -la /root/.vcmi/Mods 2>&1 >> "$OUTPUT_FILE" || echo "Symlink not found" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

echo "5. Checking VCMI config..." >> "$OUTPUT_FILE"
if [ -f /root/.config/vcmi/settings.json ]; then
    echo "Config file exists" >> "$OUTPUT_FILE"
    cat /root/.config/vcmi/settings.json | python3 -m json.tool 2>&1 >> "$OUTPUT_FILE"
else
    echo "Config file NOT found" >> "$OUTPUT_FILE"
fi
echo "" >> "$OUTPUT_FILE"

echo "6. Checking VCMI process..." >> "$OUTPUT_FILE"
ps aux | grep vcmiclient | grep -v grep >> "$OUTPUT_FILE" || echo "VCMI not running" >> "$OUTPUT_FILE"

echo "" >> "$OUTPUT_FILE"
echo "Diagnostics saved to: $OUTPUT_FILE" >> "$OUTPUT_FILE"
cat "$OUTPUT_FILE"

