# Plex Server Setup Guide for Raspberry Pi 5

## Prerequisites
- Raspberry Pi 5 (16GB RAM recommended)
- Ubuntu Server 24.04.3 LTS (64-bit) or newer
- Docker installed (or will be installed by script)
- Git installed
- Samsung USB drive connected (2TB recommended)

## Setup Steps

### 1. USB Storage Preparation
The setup script will automatically detect and configure your USB drive, but you can prepare it manually if needed:

1. Check your USB drive is connected:
   ```bash
   lsblk
   ```
   Your Samsung USB drive should appear as `/dev/sda`, `/dev/sdb`, etc.

2. The setup script will:
   - Automatically detect your USB drive
   - Offer to format it if needed (ext4 filesystem)
   - Mount it at `/mnt/blockstore`
   - Add it to `/etc/fstab` for automatic mounting on boot

### 2. Plex Installation

1. Clone and prepare the repository:
   ```bash
   git clone https://github.com/joereg4/rasberry-pi-plex-docker-setup.git
   cd rasberry-pi-plex-docker-setup
   chmod +x scripts/setup/*.sh
   ```

2. Get your Plex claim token from [plex.tv/claim](https://plex.tv/claim)

3. Run the setup script:
   ```bash
   sudo ./scripts/setup/setup_plex.sh
   ```
   The script will:
   - Detect and configure your USB drive
   - Install Docker if needed
   - Create required directories
   - Configure permissions
   - Prompt for Plex claim token
   - Start Plex container
   - Verify everything is working
   
   **Note**: The `.env` file will be created automatically from `.env.example` if it doesn't exist.

### 3. Verify Installation

1. Check Plex is running:
   - Open `http://YOUR_SERVER_IP:32400/web`
   - Sign in with your Plex account

2. Set up your Plex libraries:
   a. Click the '+' button next to 'Libraries' in the left sidebar

   b. For each library type (Movies, TV Shows, etc.):
      - Choose the appropriate library type
      - Name your library (e.g., "Movies")
      - Click "Add Folders"
      - Click "Browse for Media Folder"
      - Navigate to `/data`
      - Select the corresponding folder:
        * Movies: `/data/Movies`
        * TV Shows: `/data/TV Shows`
        * Music: `/data/Music`
        * Photos: `/data/Photos`

   c. Advanced Settings (recommended):
      - Enable "Scan my library automatically"
      - Enable "Run a partial scan when changes are detected"

   > Important: Use these exact paths in Plex:
   - Movies: `/data/Movies`
   - TV Shows: `/data/TV Shows`
   - Music: `/data/Music`
   - Photos: `/data/Photos`

   Note: While your media is stored in `/mnt/blockstore/plex/media/` on the Raspberry Pi,
   Plex sees these directories as `/data/` inside the container. The USB drive is mounted
   at `/mnt/blockstore` and contains all your media files.

3. Test your libraries:
   ```bash
   # On your server, create a test file
   sudo touch "/mnt/blockstore/plex/media/Movies/test.mp4"
   
   # In Plex web interface:
   # - Go to Movies library
   # - Click the refresh button
   # - You should see test.mp4 appear
   
   # Clean up test file
   sudo rm "/mnt/blockstore/plex/media/Movies/test.mp4"
   ```

## Troubleshooting

If you see "No soup for you":
1. Stop Plex: `docker stop plex`
2. Remove the Preferences.xml file
3. Start Plex: `docker start plex`

For detailed troubleshooting steps, see [TROUBLESHOOTING.md](TROUBLESHOOTING.md)

## Next Steps

1. Add media to your libraries
2. Configure remote access
3. Set up users and sharing

For domain setup instructions, see [DOMAIN_SETUP.md](DOMAIN_SETUP.md)