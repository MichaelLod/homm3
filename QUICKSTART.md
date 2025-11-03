# Quick Start Guide

## 1. Deploy to Railway

1. Push this repository to GitHub
2. Go to [Railway Dashboard](https://railway.app/dashboard)
3. Click "New Project" → "Deploy from GitHub repo"
4. Select this repository
5. Wait for build to complete (may take 10-15 minutes)

## 2. Configure Storage

1. In Railway project → Service → Settings → Volumes
2. Add Volumes:
   - Name: `game-data`, Mount Path: `/data`, Size: 1GB (for HoMM 3 game files)
   - Name: `saves`, Mount Path: `/app/saves`, Size: 500MB (for save games)

## 3. Set VNC Password (Recommended)

1. Go to Variables tab
2. Add: `VNC_PASSWORD` = `your-secure-password`

## 4. Access Desktop

1. Open the public URL provided by Railway
2. Enter VNC password (default: `password` or your custom one)
3. You'll see the Fluxbox desktop

## 5. Upload HoMM 3 Game Files (Required)

⚠️ **You must upload your HoMM 3 game files on first start!**

1. Open terminal in desktop (right-click → Terminal or xterm)
2. Run the setup script:
   ```bash
   /setup-homm3-files.sh
   ```
3. Choose an option:
   - **Option 1**: Copy from path (if files accessible)
   - **Option 2**: Download from URL (recommended - host files online first)
   - **Option 3**: Use Railway CLI for SFTP/SCP

Files will be saved to `/data/Data/` (persistent storage) and automatically linked to `~/.vcmi/Data/`

**Required files**: Copy `Data/` directory with .lod, .snd, .vid files from your HoMM 3 installation.

## 6. Run VCMI

1. In desktop, right-click → VCMI Client
2. Or in terminal: `vcmiclient`

## Save Games

Save games are automatically saved to `/app/saves` which persists across deployments!

## Troubleshooting

- **Can't connect?** Check Railway service is running
- **VCMI won't start?** Verify HoMM 3 files are in `~/.vcmi/Data/`
- **Build failed?** Build should be fast (~2-5 minutes) using pre-built VCMI from PPA

## Notes

- Build should complete in 2-5 minutes using pre-built VCMI
- VCMI needs original HoMM 3 game files (Data/, Maps/, MP3/)
- Save games persist in `/app/saves` volume

