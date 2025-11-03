#!/bin/bash
# Download HotA mod from GitHub (VCMI-compatible version)
set +e  # Don't fail on errors

echo "=========================================" >&2
echo "HotA Installation Script (VCMI version)" >&2
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

# GitHub repository URL
GITHUB_REPO="https://github.com/vcmi-mods/horn-of-the-abyss.git"
GITHUB_BRANCH="vcmi-1.7"  # Use the vcmi-1.7 branch
TEMP_DIR="/tmp/hota-install"

echo "Downloading HotA mod from GitHub..." >&2
echo "Repository: ${GITHUB_REPO}" >&2
echo "Branch: ${GITHUB_BRANCH}" >&2

# Clean up any previous temp directory
rm -rf "$TEMP_DIR" 2>/dev/null || true
mkdir -p "$TEMP_DIR"

# Clone the repository (shallow clone to save time and space)
cd "$TEMP_DIR" || {
    echo "❌ Cannot create temp directory" >&2
    exit 1
}

echo "Cloning repository (this may take a minute)..." >&2
if git clone --depth 1 --branch "$GITHUB_BRANCH" "$GITHUB_REPO" . 2>&1; then
    echo "✅ Repository cloned successfully" >&2
else
    echo "⚠️  Failed to clone with branch, trying default branch..." >&2
    git clone --depth 1 "$GITHUB_REPO" . 2>&1 || {
        echo "❌ Failed to clone repository" >&2
        exit 1
    }
fi

# Check if hota directory exists in the repository
if [ -d "hota" ]; then
    echo "✅ Found 'hota' directory in repository" >&2
    echo "Copying to /data/mods/..." >&2
    cp -r hota /data/mods/ 2>&1 || {
        echo "❌ Failed to copy hota directory" >&2
        exit 1
    }
    echo "✅ HotA mod copied successfully" >&2
elif [ -d "HotA" ]; then
    echo "✅ Found 'HotA' directory in repository" >&2
    echo "Copying to /data/mods/..." >&2
    cp -r HotA /data/mods/ 2>&1 || {
        echo "❌ Failed to copy HotA directory" >&2
        exit 1
    }
    echo "✅ HotA mod copied successfully" >&2
else
    echo "⚠️  Repository structure unclear. Contents:" >&2
    ls -la | head -20 >&2
    echo "" >&2
    echo "Trying to find mod directory..." >&2
    find . -type d -name "hota" -o -name "HotA" | head -5 >&2
    exit 1
fi

# Clean up temp directory
cd /
rm -rf "$TEMP_DIR" 2>/dev/null || true
    
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

