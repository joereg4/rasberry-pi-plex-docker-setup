# Plex Server Setup Guide

## Prerequisites
- Ubuntu 22.04 LTS
- Docker installed
- Git installed
- Block storage attached to server

## Setup Steps

### 1. Block Storage Preparation
Before running the setup script, we need to prepare the block storage:

1. Check your block storage device:
   ```bash
   lsblk
   ```
   Look for your block storage (usually `/dev/vdc` on Vultr)

2. Format and mount the block storage:
   ```bash
   sudo ./scripts/setup/mount_storage.sh
   ```
   This will format, mount, and set up the storage for Plex media

### 2. Plex Installation

1. Clone and prepare the repository:
   ```bash
   git clone https://github.com/joereg4/plex-docker-setup.git
   cd plex-docker-setup
   chmod +x scripts/setup/*.sh
   ```

2. Get your Plex claim token from [plex.tv/claim](https://plex.tv/claim)

3. Copy and edit the environment file:
   ```bash
   cp .env.example .env
   nano .env    # Add your Plex claim token here
   ```

4. Set up Plex:
   ```bash
   sudo ./scripts/setup/setup_plex.sh
   ```
   The script will:
   - Create required directories
   - Configure permissions
   - Start Plex container
   - Verify everything is working

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

   Note: While your media is stored in `/mnt/blockstore/plex/media/` on the server,
   Plex sees these directories as `/data/` inside the container.

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