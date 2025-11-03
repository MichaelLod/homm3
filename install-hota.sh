#!/bin/bash
# Download and extract HotA mod from Google Drive

# Check if already installed
if [ -d /data/mods/HotA ] || [ -d /data/mods/hota ]; then
    echo "✅ HotA mod already installed"
    exit 0
fi

echo "Downloading HotA installer from Google Drive..."
cd /data/mods

FILE_ID="1U6pLo7mtAQYUrfYXxWPGZXnvXG6nAxA2"

# Install gdown if needed
if ! command -v gdown &> /dev/null; then
    pip3 install gdown --quiet
fi

# Download HotA installer
gdown "https://drive.google.com/uc?id=${FILE_ID}" -O hota_installer.exe

if [ ! -f hota_installer.exe ]; then
    echo "❌ Failed to download HotA installer"
    exit 1
fi

echo "✅ Downloaded HotA installer"
echo "Attempting to extract..."

# Try to extract - many .exe installers are ZIP archives
mkdir -p temp_extract
cd temp_extract

# Try unzip first (most .exe installers are self-extracting ZIPs)
if unzip -o ../hota_installer.exe 2>/dev/null; then
    echo "✅ Successfully extracted with unzip"
    
    # Look for HotA mod files
    # HotA usually has a "Mods" folder or "HotA" folder
    if [ -d "Mods" ]; then
        echo "Found Mods directory, copying to /data/mods..."
        cp -r Mods/* /data/mods/ 2>/dev/null || true
        cp -r Mods /data/mods/ 2>/dev/null || true
    elif [ -d "HotA" ]; then
        echo "Found HotA directory, copying to /data/mods..."
        cp -r HotA /data/mods/
    elif [ -d "hota" ]; then
        echo "Found hota directory, copying to /data/mods..."
        cp -r hota /data/mods/
    else
        echo "⚠️  Extracted but mod structure unclear. Contents:"
        ls -la | head -20
        echo ""
        echo "Please check /data/mods/temp_extract/ and manually copy the HotA mod folder"
        exit 0
    fi
    
    cd /data/mods
    rm -rf temp_extract hota_installer.exe
    echo "✅ HotA mod installed to /data/mods/"
    ls -la /data/mods/
    
else
    echo "⚠️  Could not extract with unzip. The .exe might need to be run on Windows."
    echo ""
    echo "Alternative: Extract the .exe on Windows/Mac and upload the extracted 'Mods' folder"
    echo "You can use 7-Zip or WinRAR to extract the .exe file"
    exit 1
fi

echo ""
echo "✅ Installation complete!"
echo "Next steps:"
echo "1. Restart VCMI"
echo "2. Open Mod Manager in VCMI"
echo "3. Enable the HotA mod"

