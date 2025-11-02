#!/bin/bash
# Helper script to guide users through setting up HoMM 3 game files

echo "========================================="
echo "HoMM 3 Game Files Setup"
echo "========================================="
echo ""
echo "This script will help you set up your HoMM 3 game files."
echo ""
echo "Required files from HoMM 3 installation:"
echo "  - Data/      (Game data files - .lod, .snd, .vid files)"
echo "  - Maps/      (Game maps - optional)"
echo "  - MP3/       (Music files - optional)"
echo ""
echo "Target directory: /data/Data/ (persistent storage)"
echo "Files will be automatically linked to ~/.vcmi/Data/"
echo ""
echo "Options:"
echo "1. Copy from local directory"
echo "2. Download from URL"
echo "3. Use SFTP/SCP (you'll need to run manually)"
echo "4. Exit"
echo ""
read -p "Choose an option (1-4): " choice

case $choice in
    1)
        read -p "Enter path to HoMM 3 installation: " homm_path
        if [ -d "$homm_path" ]; then
            mkdir -p /data/Data /data/Maps /data/MP3
            echo "Copying Data files..."
            cp -r "$homm_path/Data"/* /data/Data/ 2>/dev/null || true
            echo "Copying Maps..."
            [ -d "$homm_path/Maps" ] && cp -r "$homm_path/Maps" /data/ 2>/dev/null || true
            echo "Copying MP3..."
            [ -d "$homm_path/MP3" ] && cp -r "$homm_path/MP3" /data/ 2>/dev/null || true
            echo "Files copied successfully to /data/ (persistent storage)!"
            echo "Files will be available at ~/.vcmi/Data/ (linked automatically)"
        else
            echo "Error: Directory not found!"
        fi
        ;;
    2)
        read -p "Enter URL to download HoMM 3 files (zip/tar): " url
        mkdir -p /tmp/homm3_setup /data/Data
        cd /tmp/homm3_setup
        echo "Downloading..."
        wget -O homm3.zip "$url" 2>/dev/null || curl -L -o homm3.zip "$url"
        echo "Extracting..."
        unzip -q homm3.zip || tar -xf homm3.zip || tar -xzf homm3.zip
        echo "Copying files to /data/..."
        find . -name "Data" -type d -exec cp -r {}/* /data/Data/ \; 2>/dev/null || true
        find . -name "Maps" -type d -exec cp -r {} /data/ \; 2>/dev/null || true
        find . -name "MP3" -type d -exec cp -r {} /data/ \; 2>/dev/null || true
        cd ~
        rm -rf /tmp/homm3_setup
        echo "Files downloaded and extracted to /data/ (persistent storage)!"
        echo "Files will be available at ~/.vcmi/Data/ (linked automatically)"
        ;;
    3)
        echo "To use SFTP/SCP, connect to this Railway instance and run:"
        echo "  scp -r /path/to/homm3/Data/* user@railway-instance:/data/Data/"
        echo ""
        echo "Or use Railway CLI:"
        echo "  railway connect"
        echo "  # Then use scp or rsync to transfer files to /data/Data/"
        ;;
    4)
        exit 0
        ;;
    *)
        echo "Invalid option!"
        ;;
esac

echo ""
echo "Setup complete! You can now run VCMI."

