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

# Verify HotA was copied successfully
if [ -d "/data/mods/HotA" ] || [ -d "/data/mods/hota" ]; then
    echo "✅ HotA mod successfully copied to /data/mods/" >&2
    echo "Mod structure:" >&2
    ls -la /data/mods/ | head -10 >&2
    if [ -d "/data/mods/hota" ]; then
        echo "HotA mod contents:" >&2
        ls -la /data/mods/hota/ | head -10 >&2
    elif [ -d "/data/mods/HotA" ]; then
        echo "HotA mod contents:" >&2
        ls -la /data/mods/HotA/ | head -10 >&2
    fi
else
    echo "❌ HotA mod directory not found after installation!" >&2
    echo "Available in /data/mods/:" >&2
    ls -la /data/mods/ 2>&1 | head -10 >&2
    exit 1
fi

# Clean up temp directory
cd /
rm -rf "$TEMP_DIR" 2>/dev/null || true

# Enable HotA mod in VCMI configuration
if [ -f /usr/local/bin/enable-hota-mod ]; then
    echo "Enabling HotA mod in VCMI configuration..." >&2
    /usr/local/bin/enable-hota-mod 2>&1 || echo "⚠️  Could not enable mod automatically, enable manually in VCMI Mod Manager" >&2
fi

echo "" >&2
echo "✅ Installation complete!" >&2
echo "Next steps:" >&2
echo "1. Restart VCMI (if it's running)" >&2
echo "2. The mod should be automatically enabled in VCMI configuration" >&2

