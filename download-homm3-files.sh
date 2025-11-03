#!/bin/bash
# Download HoMM3 files from Google Drive if not present
set +e

# Check if files already exist
if [ -d /data/Data ] && ls /data/Data/*.{lod,snd,vid} >/dev/null 2>&1; then
    echo "✅ HoMM3 files already exist in /data/Data/"
    exit 0
fi

echo "HoMM3 files not found, downloading from Google Drive..."

# Ensure /data/Data exists
mkdir -p /data/Data || {
    echo "⚠️  Cannot create /data/Data - volume may not be mounted"
    exit 1
}

# Install gdown if needed
if ! command -v gdown &> /dev/null; then
    echo "Installing gdown..."
    pip3 install --user gdown --quiet || pip3 install gdown --quiet
fi

# Google Drive file ID
FILE_ID="1eKCXhcIiqvPONzXDBa0iEJmFLmBGaaMP"
URL="https://drive.google.com/uc?id=${FILE_ID}"

echo "Downloading HoMM3 files..."
cd /tmp
gdown "${URL}" -O homm3_files.zip || {
    echo "❌ Failed to download HoMM3 files"
    exit 1
}

echo "Extracting HoMM3 files..."
mkdir -p homm3_extract
cd homm3_extract
unzip -q ../homm3_files.zip || tar -xf ../homm3_files.zip || tar -xzf ../homm3_files.zip

# Find and copy Data files
echo "Copying files to /data/Data/..."
find . -type f \( -name "*.lod" -o -name "*.snd" -o -name "*.vid" \) -exec cp {} /data/Data/ \;

# Also try to find a Data directory
if find . -type d -name "Data" | head -1 | xargs -I {} sh -c 'cp -r {}/* /data/Data/ 2>/dev/null || true'; then
    echo "✅ Copied Data directory contents"
fi

# Cleanup
cd /
rm -rf /tmp/homm3_files.zip /tmp/homm3_extract

if ls /data/Data/*.{lod,snd,vid} >/dev/null 2>&1; then
    echo "✅ HoMM3 files downloaded and extracted to /data/Data/"
    ls -lh /data/Data/ | head -10
else
    echo "⚠️  Files extracted but not found in /data/Data/"
    exit 1
fi

