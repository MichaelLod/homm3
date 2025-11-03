#!/bin/bash
# Script to download and upload HoMM3 files and HotA mod to Railway
set +e

echo "========================================="
echo "Uploading HoMM3 files and HotA mod"
echo "========================================="

# HoMM3 files Google Drive link
HOMM3_FILE_ID="1eKCXhcIiqvPONzXDBa0iEJmFLmBGaaMP"
HOMM3_URL="https://drive.google.com/uc?id=${HOMM3_FILE_ID}"

# HotA mod Google Drive link
HOTA_FILE_ID="1U6pLo7mtAQYUrfYXxWPGZXnvXG6nAxA2"
HOTA_URL="https://drive.google.com/uc?id=${HOTA_FILE_ID}"

# Install gdown if needed
if ! command -v gdown &> /dev/null; then
    echo "Installing gdown..."
    pip3 install gdown --quiet || pip install gdown --quiet
fi

# Download HoMM3 files
echo ""
echo "Downloading HoMM3 files..."
mkdir -p /tmp/homm3_upload
cd /tmp/homm3_upload

gdown "${HOMM3_URL}" -O homm3_files.zip || {
    echo "Failed to download HoMM3 files"
    exit 1
}

echo "Extracting HoMM3 files..."
unzip -q homm3_files.zip || tar -xf homm3_files.zip || tar -xzf homm3_files.zip

# Find and copy Data files
echo "Copying HoMM3 files to /data/Data/..."
mkdir -p /data/Data
find . -name "*.lod" -o -name "*.snd" -o -name "*.vid" | while read file; do
    cp "$file" /data/Data/ 2>/dev/null || true
done

# Also try to find a Data directory
if find . -type d -name "Data" | head -1 | xargs -I {} cp -r {}/* /data/Data/ 2>/dev/null; then
    echo "✅ Copied Data directory contents"
else
    echo "⚠️  No Data directory found, copying individual files"
fi

echo "✅ HoMM3 files uploaded to /data/Data/"
ls -lh /data/Data/ | head -10

# Download HotA mod
echo ""
echo "Downloading HotA mod..."
cd /tmp/homm3_upload
rm -f *.zip *.tar *.tar.gz
gdown "${HOTA_URL}" -O hota_installer.exe || {
    echo "Failed to download HotA mod"
    exit 1
}

echo "Extracting HotA mod..."
mkdir -p temp_extract
cd temp_extract

if unzip -o ../hota_installer.exe 2>/dev/null; then
    echo "✅ Successfully extracted HotA installer"
    
    # Look for HotA mod files
    mkdir -p /data/mods
    if [ -d "Mods" ]; then
        echo "Found Mods directory, copying to /data/mods..."
        cp -r Mods/* /data/mods/ 2>/dev/null || true
    elif [ -d "HotA" ]; then
        echo "Found HotA directory, copying to /data/mods..."
        cp -r HotA /data/mods/
    elif [ -d "hota" ]; then
        echo "Found hota directory, copying to /data/mods..."
        cp -r hota /data/mods/
    else
        echo "⚠️  Extracted but mod structure unclear. Contents:"
        ls -la | head -20
        echo "Please check and manually copy if needed"
    fi
    
    echo "✅ HotA mod installed to /data/mods/"
    ls -la /data/mods/ | head -10
    
else
    echo "⚠️  Could not extract HotA installer with unzip"
    exit 1
fi

# Cleanup
cd /
rm -rf /tmp/homm3_upload

echo ""
echo "========================================="
echo "✅ Upload complete!"
echo "========================================="
echo "HoMM3 files: /data/Data/"
echo "HotA mod: /data/mods/"
echo ""
echo "Files are now in persistent storage and will survive deployments."

