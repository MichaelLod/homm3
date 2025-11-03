#!/bin/bash
# Download and extract HotA mod from Google Drive
set +e  # Don't fail on errors

echo "=========================================" >&2
echo "HotA Installation Script" >&2
echo "=========================================" >&2

# Check if already installed
if [ -d /data/mods/HotA ] || [ -d /data/mods/hota ]; then
    echo "✅ HotA mod already installed" >&2
    exit 0
fi

# Ensure /data/mods exists
echo "Creating /data/mods directory..." >&2
mkdir -p /data/mods || {
    echo "❌ Cannot create /data/mods - volume may not be mounted" >&2
    exit 1
}

echo "✅ /data/mods directory exists" >&2
echo "Downloading HotA installer from Google Drive..." >&2
cd /data/mods || {
    echo "❌ Cannot access /data/mods" >&2
    exit 1
}

FILE_ID="1U6pLo7mtAQYUrfYXxWPGZXnvXG6nAxA2"
URL="https://drive.google.com/uc?id=${FILE_ID}"

# Install gdown if needed
if ! command -v gdown &> /dev/null; then
    echo "Installing gdown..." >&2
    pip3 install --user gdown --quiet || pip3 install gdown --quiet || {
        echo "❌ Failed to install gdown" >&2
        exit 1
    }
fi

echo "✅ gdown is available" >&2
echo "Downloading HotA installer (this may take a few minutes)..." >&2
echo "URL: ${URL}" >&2

# Download HotA installer
gdown "${URL}" -O hota_installer.exe 2>&1 || {
    echo "❌ Failed to download HotA installer" >&2
    echo "   Trying alternative download method..." >&2
    # Try with wget as fallback
    wget "${URL}" -O hota_installer.exe 2>&1 || {
        echo "❌ Failed to download with wget as well" >&2
        exit 1
    }
}

if [ ! -f hota_installer.exe ]; then
    echo "❌ Failed to download HotA installer" >&2
    exit 1
fi

FILE_SIZE=$(stat -c%s hota_installer.exe 2>/dev/null || stat -f%z hota_installer.exe 2>/dev/null || echo "unknown")
echo "✅ Downloaded HotA installer (size: ${FILE_SIZE} bytes)" >&2
echo "Attempting to extract..." >&2

# Try to extract - many .exe installers are ZIP archives
echo "Creating temp_extract directory..." >&2
mkdir -p temp_extract
cd temp_extract

echo "Extracting hota_installer.exe..." >&2
# Try multiple extraction methods
EXTRACTION_SUCCESS=false

# Method 1: Try unzip (most .exe installers are self-extracting ZIPs)
echo "Trying unzip..." >&2
if unzip -o ../hota_installer.exe 2>&1 | tee /tmp/hota-unzip.log; then
    if [ "$(ls -A . 2>/dev/null | wc -l)" -gt 2 ]; then
        echo "✅ Successfully extracted with unzip" >&2
        EXTRACTION_SUCCESS=true
    else
        echo "⚠️  unzip succeeded but extracted directory is empty" >&2
    fi
fi

# Method 2: Try 7z (supports more archive formats)
if [ "$EXTRACTION_SUCCESS" = "false" ]; then
    echo "Trying 7z..." >&2
    if command -v 7z &> /dev/null; then
        if 7z x ../hota_installer.exe -o. 2>&1 | tee /tmp/hota-7z.log; then
            if [ "$(ls -A . 2>/dev/null | wc -l)" -gt 2 ]; then
                echo "✅ Successfully extracted with 7z" >&2
                EXTRACTION_SUCCESS=true
            else
                echo "⚠️  7z succeeded but extracted directory is empty" >&2
            fi
        fi
    else
        echo "⚠️  7z not available" >&2
    fi
fi

if [ "$EXTRACTION_SUCCESS" = "true" ]; then
    echo "Extracted contents:" >&2
    ls -la | head -20 >&2
    
    # Look for HotA mod files
    # HotA usually has a "Mods" folder or "HotA" folder
    # VCMI expects mods in ~/.vcmi/Mods/ (which is symlinked to /data/mods/)
    MOD_FOUND=false
    
    if [ -d "Mods" ]; then
        echo "Found Mods directory!" >&2
        ls -la Mods/ | head -10 >&2
        # Try to find HotA inside Mods
        if [ -d "Mods/HotA" ]; then
            echo "Found Mods/HotA, copying to /data/mods/..." >&2
            cp -r Mods/HotA /data/mods/ 2>&1 || {
                echo "❌ Failed to copy Mods/HotA" >&2
            }
            MOD_FOUND=true
        elif [ -d "Mods/hota" ]; then
            echo "Found Mods/hota, copying to /data/mods/..." >&2
            cp -r Mods/hota /data/mods/ 2>&1 || {
                echo "❌ Failed to copy Mods/hota" >&2
            }
            MOD_FOUND=true
        else
            echo "Mods directory found but no HotA/hota inside. Copying all mods..." >&2
            cp -r Mods/* /data/mods/ 2>&1 || {
                echo "❌ Failed to copy Mods/*" >&2
            }
            MOD_FOUND=true
        fi
    elif [ -d "HotA" ]; then
        echo "Found HotA directory, copying to /data/mods/..." >&2
        cp -r HotA /data/mods/ 2>&1 || {
            echo "❌ Failed to copy HotA" >&2
            exit 1
        }
        MOD_FOUND=true
    elif [ -d "hota" ]; then
        echo "Found hota directory, copying to /data/mods/..." >&2
        cp -r hota /data/mods/ 2>&1 || {
            echo "❌ Failed to copy hota" >&2
            exit 1
        }
        MOD_FOUND=true
    fi
    
    if [ "$MOD_FOUND" = "false" ]; then
        echo "⚠️  Extracted but mod structure unclear. Full contents:" >&2
        find . -type d -maxdepth 2 | head -20 >&2
        echo "" >&2
        echo "Listing all files and directories:" >&2
        find . -type f -o -type d | head -30 >&2
        echo "" >&2
        echo "Please check /data/mods/temp_extract/ and manually copy the HotA mod folder" >&2
        exit 1
    fi
else
    echo "❌ Failed to extract hota_installer.exe with any method" >&2
    echo "The .exe file is likely a Windows installer that requires Windows to run." >&2
    echo "" >&2
    echo "Options:" >&2
    echo "1. Extract the .exe on Windows using 7-Zip or WinRAR" >&2
    echo "2. Upload the extracted 'Mods' or 'HotA' folder directly to /data/mods/" >&2
    echo "3. Use a different HotA download that is VCMI-compatible" >&2
    exit 1
fi
    
    cd /data/mods
    
    # Verify HotA was copied successfully before cleaning up
    if [ -d "/data/mods/HotA" ] || [ -d "/data/mods/hota" ]; then
        echo "✅ HotA mod successfully copied to /data/mods/" >&2
        echo "Cleaning up temporary files..." >&2
        rm -rf temp_extract hota_installer.exe 2>&1 || {
            echo "⚠️  Could not remove all temp files, but mod is installed" >&2
        }
    else
        echo "❌ HotA mod directory not found after extraction!" >&2
        echo "Keeping temp_extract for debugging. Contents:" >&2
        ls -la temp_extract/ 2>&1 | head -20 >&2
        exit 1
    fi
    
    # Enable HotA mod in VCMI configuration
    if [ -f /usr/local/bin/enable-hota-mod ]; then
        echo "Enabling HotA mod in VCMI configuration..."
        /usr/local/bin/enable-hota-mod || echo "⚠️  Could not enable mod automatically, enable manually in VCMI Mod Manager"
    fi
    
    # Verify HotA mod is installed correctly
    if [ -d "/data/mods/HotA" ] || [ -d "/data/mods/hota" ]; then
        echo "✅ HotA mod installed to /data/mods/"
        echo "Mod structure:"
        ls -la /data/mods/ | head -10
        if [ -d "/data/mods/HotA" ]; then
            echo "HotA mod contents:"
            ls -la /data/mods/HotA/ | head -10
        fi
    else
        echo "⚠️  HotA mod directory not found after installation"
        echo "Available in /data/mods/:"
        ls -la /data/mods/
    fi
    
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

