#!/bin/bash
# Helper script to install Horn of the Abyss (HotA) mod for VCMI

echo "========================================="
echo "Horn of the Abyss (HotA) Mod Setup"
echo "========================================="
echo ""
echo "This script will help you install the HotA mod for VCMI."
echo ""
echo "Prerequisites:"
echo "  - You need to download the HotA mod files"
echo "  - HotA is a community mod, download from: https://www.hotacampaign.com/"
echo "  - Or use the Heroes Launcher which includes HotA"
echo ""
echo "Target directory: ~/.vcmi/Mods/ (linked to /data/mods in persistent storage)"
echo ""

read -p "Do you have the HotA mod files ready? (y/n): " has_files

if [ "$has_files" != "y" ] && [ "$has_files" != "Y" ]; then
    echo ""
    echo "Please download HotA from: https://www.hotacampaign.com/"
    echo "Or use the Heroes Launcher: https://heroescommunity.com/viewforum.php?f=27"
    echo ""
    echo "After downloading, extract the mod files and run this script again."
    exit 0
fi

echo ""
echo "Options:"
echo "1. Copy from local path (if you have files on the server)"
echo "2. Download from URL (if you have a direct download link)"
echo "3. Instructions for manual installation"
echo "4. Upload .exe file and try to extract (Windows installer)"
echo "5. Exit"
echo ""
read -p "Choose an option (1-5): " choice

case $choice in
    1)
        read -p "Enter path to HotA mod directory: " hota_path
        if [ -d "$hota_path" ]; then
            mkdir -p ~/.vcmi/Mods
            cp -r "$hota_path"/* ~/.vcmi/Mods/ 2>/dev/null || {
                echo "Error: Could not copy files from $hota_path"
                exit 1
            }
            echo "✅ HotA mod files copied to ~/.vcmi/Mods/"
            echo "You may need to restart VCMI and enable the mod in the mod manager."
        else
            echo "Error: Directory not found: $hota_path"
            exit 1
        fi
        ;;
    2)
        read -p "Enter download URL for HotA mod: " download_url
        mkdir -p ~/.vcmi/Mods
        cd ~/.vcmi/Mods
        echo "Downloading HotA mod..."
        wget -O hota.zip "$download_url" 2>/dev/null || curl -L -o hota.zip "$download_url" || {
            echo "Error: Could not download from URL"
            exit 1
        }
        unzip -o hota.zip
        rm -f hota.zip
        echo "✅ HotA mod downloaded and extracted"
        echo "You may need to restart VCMI and enable the mod in the mod manager."
        ;;
    5)
        echo "Upload HotA .exe file and extract it"
        echo "Note: HotA .exe is a Windows installer. We'll try to extract it."
        echo ""
        read -p "Enter path to HotA .exe file on server: " exe_path
        if [ -f "$exe_path" ]; then
            mkdir -p ~/.vcmi/Mods/temp_extract
            cd ~/.vcmi/Mods/temp_extract
            echo "Attempting to extract .exe file..."
            # Try to extract - many .exe installers are actually ZIP archives
            unzip -o "$exe_path" 2>/dev/null || {
                echo "⚠️  Could not extract .exe directly"
                echo "HotA .exe is a Windows installer. You have two options:"
                echo ""
                echo "Option A: Extract locally on Windows:"
                echo "  1. Install 7-Zip or WinRAR on Windows"
                echo "  2. Right-click HotA .exe → Extract"
                echo "  3. Find the 'Mods' or 'HotA' folder inside"
                echo "  4. Upload that folder to /data/mods/"
                echo ""
                echo "Option B: Use Heroes Launcher (recommended):"
                echo "  Download from: https://heroescommunity.com/viewforum.php?f=27"
                echo "  This provides VCMI-compatible mod files"
                exit 1
            }
            # Find HotA mod directory
            if [ -d "Mods" ]; then
                cp -r Mods/* ~/.vcmi/Mods/
            elif [ -d "HotA" ]; then
                cp -r HotA ~/.vcmi/Mods/
            else
                echo "Found extracted files, but mod structure unclear. Please check ~/.vcmi/Mods/temp_extract/"
            fi
            rm -rf ~/.vcmi/Mods/temp_extract
            echo "✅ HotA mod extracted (if successful)"
        else
            echo "Error: File not found: $exe_path"
            exit 1
        fi
        ;;
    3)
        echo ""
        echo "Manual Installation Instructions:"
        echo "================================"
        echo ""
        echo "1. Download HotA from: https://www.hotacampaign.com/"
        echo "   Or use Heroes Launcher: https://heroescommunity.com/viewforum.php?f=27"
        echo ""
        echo "2. Extract the HotA mod files"
        echo ""
        echo "3. Copy the mod directory to: ~/.vcmi/Mods/"
        echo "   Example: cp -r /path/to/hota ~/.vcmi/Mods/"
        echo ""
        echo "4. Restart VCMI"
        echo ""
        echo "5. In VCMI, go to Mod Manager and enable HotA"
        echo ""
        echo "Note: Mods directory is linked to persistent storage, so it persists across deployments."
        ;;
    4)
        echo "Upload HotA .exe file and extract it"
        echo "Note: HotA .exe is a Windows installer. We'll try to extract it."
        echo ""
        read -p "Enter path to HotA .exe file on server: " exe_path
        if [ -f "$exe_path" ]; then
            mkdir -p ~/.vcmi/Mods/temp_extract
            cd ~/.vcmi/Mods/temp_extract
            echo "Attempting to extract .exe file..."
            # Try to extract - many .exe installers are actually ZIP archives
            unzip -o "$exe_path" 2>/dev/null || {
                echo "⚠️  Could not extract .exe directly"
                echo "HotA .exe is a Windows installer. You have two options:"
                echo ""
                echo "Option A: Extract locally on Windows:"
                echo "  1. Install 7-Zip or WinRAR on Windows"
                echo "  2. Right-click HotA .exe → Extract"
                echo "  3. Find the 'Mods' or 'HotA' folder inside"
                echo "  4. Upload that folder to /data/mods/"
                echo ""
                echo "Option B: Use Heroes Launcher (recommended):"
                echo "  Download from: https://heroescommunity.com/viewforum.php?f=27"
                echo "  This provides VCMI-compatible mod files"
                exit 1
            }
            # Find HotA mod directory
            if [ -d "Mods" ]; then
                cp -r Mods/* ~/.vcmi/Mods/
            elif [ -d "HotA" ]; then
                cp -r HotA ~/.vcmi/Mods/
            else
                echo "Found extracted files, but mod structure unclear. Please check ~/.vcmi/Mods/temp_extract/"
            fi
            rm -rf ~/.vcmi/Mods/temp_extract
            echo "✅ HotA mod extracted (if successful)"
        else
            echo "Error: File not found: $exe_path"
            exit 1
        fi
        ;;
    5)
        exit 0
        ;;
    *)
        echo "Invalid option"
        exit 1
        ;;
esac

echo ""
echo "Next steps:"
echo "1. Restart VCMI"
echo "2. Open Mod Manager in VCMI"
echo "3. Enable the HotA mod"
echo "4. Start a new game - HotA features should be available!"

