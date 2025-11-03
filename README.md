# HoMM 3 VCMI on Railway

Run Heroes of Might and Magic III using VCMI engine in your browser on Railway with persistent save games.

## Overview

This setup provides a complete browser-based VCMI installation that:
- Runs VCMI in a desktop environment accessible via web browser
- Uses noVNC for web-based remote desktop access
- Persists save games across deployments
- Builds VCMI from source for latest features

## Prerequisites

1. **Railway Account**: Sign up at [railway.app](https://railway.app)
2. **GitHub Account**: For connecting your repository
3. **HoMM 3 Game Files**: You'll need to upload your own legal copy of HoMM 3 game files on first start

## Railway Setup

### Step 1: Create a New Project

1. Go to [Railway Dashboard](https://railway.app/dashboard)
2. Click "New Project"
3. Select "Deploy from GitHub repo"
4. Choose this repository

### Step 2: Configure Persistent Storage

You need to create volumes for game files and save games:

1. In your Railway project, go to the service
2. Click on "Volumes" or "Storage" tab
3. Create volume mounts:
   - **Mount Path**: `/data` (for HoMM 3 game files - ~500MB recommended)
   - **Mount Path**: `/app/saves` (for save games)
   - **Mount Path**: `/app/config` (for VCMI configuration - optional)
   
   These volumes will persist across deployments.

### Step 3: Environment Variables (Optional)

You can set these environment variables in Railway:

- `VNC_PASSWORD`: Password for VNC connection (default: "password")
  - **Important**: Change this for security!

### Step 4: Deploy

Railway will automatically build and deploy when you push to your repository.

## Accessing Your Game

1. Once deployed, Railway will provide a public URL
2. Open the URL in your browser
3. You'll see the noVNC interface
4. Enter the VNC password (default: "password" or your custom one)

## Setting Up HoMM 3

### Game Files Upload (Required on First Start)

⚠️ **You must upload your HoMM 3 game files after deployment.** The files are stored in persistent storage at `/data` so they persist across deployments.

Required files from your HoMM 3 installation:
- `Data/` directory containing:
  - `H3bitmap.lod`, `H3sprite.lod` - Core game graphics
  - `H3ab_bmp.lod`, `H3ab_spr.lod` - Armageddon's Blade graphics (if you have expansion)
  - `Heroes3.snd`, `H3ab_ahd.snd` - Sound files
  - `H3ab_ahd.vid` - Video files (optional)
- `Maps/` directory (optional but recommended)
- `MP3/` directory (optional, for music)

### Upload Methods

#### Method 1: Using Helper Script (Recommended)

1. After connecting via browser, open a terminal
2. Run the setup script:
   ```bash
   /setup-homm3-files.sh
   ```
3. Choose from:
   - Option 1: Copy from a path (if files are already accessible)
   - Option 2: Download from URL (if you host files online)
   - Option 3: Instructions for SFTP/SCP

#### Method 2: Using Railway CLI

1. Install Railway CLI: `npm i -g @railway/cli`
2. Connect: `railway connect`
3. Upload files:
   ```bash
   scp -r /path/to/homm3/Data/* railway:/data/Data/
   scp -r /path/to/homm3/Maps railway:/data/
   ```

#### Method 3: Via Terminal (Direct Download)

1. Host your HoMM 3 files somewhere (Dropbox, Google Drive, etc.)
2. In terminal:
   ```bash
   mkdir -p /data/Data
   cd /data/Data
   wget -O homm3.zip "YOUR_FILE_URL"
   unzip homm3.zip
   # Extract and organize files as needed
   ```

### File Locations

- **Upload location**: `/data/Data/` (persistent storage)
- **VCMI access**: `~/.vcmi/Data/` (automatically linked to `/data/Data/`)
- **Verify files**: `ls -la ~/.vcmi/Data/` should show your .lod, .snd, .vid files

### Running VCMI

Once your game files are in place:

1. Open a terminal in the desktop
2. Run: `vcmiclient` or `vcmiserver`
3. The game should launch!

Or use the desktop shortcut created automatically, or right-click → VCMI Client from the Fluxbox menu.

## Mods (Horn of the Abyss, etc.)

VCMI supports mods like Horn of the Abyss (HotA). To install mods:

1. **Using the setup script:**
   ```bash
   /setup-hota-mod.sh
   ```
   Follow the prompts to install HotA or other mods.

2. **Manual installation:**
   - Download HotA from: https://www.hotacampaign.com/
   - Or use Heroes Launcher: https://heroescommunity.com/viewforum.php?f=27
   - Copy mod files to `/app/mods/` (persistent storage)
   - Restart VCMI and enable the mod in Mod Manager

Mods are stored in `/app/mods` which persists across deployments.

## Save Games

Save games are automatically persisted in `/app/saves` which is:
- Mounted as a Railway volume
- Preserved across deployments
- Located at `~/.vcmi` (symlinked)

## Troubleshooting

### VCMI won't start
- Check that HoMM 3 game files are properly installed
- Verify file permissions
- Check logs: `cat /var/log/supervisor/vnc.log`

### Can't connect to desktop
- Verify the Railway service is running
- Railway automatically assigns a PORT - check your service's public URL
- Try refreshing the browser
- Check supervisor logs: `cat /var/log/supervisor/supervisord.log`

### Save games not persisting
- Verify the volume mount in Railway dashboard
- Check that `/app/saves` is properly linked to `~/.vcmi/Saves`

### Game files missing
- Verify game files are uploaded to `/data/Data/`
- Check that `~/.vcmi/Data/` is linked: `ls -la ~/.vcmi/Data/`
- Re-run `/setup-homm3-files.sh` if needed
- Ensure `/data` volume is mounted in Railway

## Development

### Local Testing

To test locally:

```bash
docker build -t homm3-vcmi .
docker run -p 6080:6080 \
  -v $(pwd)/data:/data \
  -v $(pwd)/saves:/app/saves \
  homm3-vcmi
```

Then open `http://localhost:6080` in your browser.

### Updating VCMI

To get the latest VCMI version, rebuild the Docker image. The Dockerfile installs VCMI from the official PPA, which is automatically updated.

## Security Notes

⚠️ **Important**: 
- Change the default VNC password before deploying to production
- Consider adding authentication to the noVNC interface
- Railway provides HTTPS by default, which helps secure the connection

## License

This setup uses VCMI, which is licensed under GPL-2.0. You must own the original Heroes of Might and Magic III game to use this legally.

## Resources

- [VCMI Project](https://vcmi.eu/)
- [VCMI GitHub](https://github.com/vcmi/vcmi)
- [Railway Documentation](https://docs.railway.app/)
- [noVNC Documentation](https://github.com/novnc/noVNC)

## Support

For VCMI issues: [VCMI Forums](https://forum.vcmi.eu/)
For Railway issues: [Railway Discord](https://discord.gg/railway)

