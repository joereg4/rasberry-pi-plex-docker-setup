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

2. Add your media libraries:
   - Movies: `/data/Movies`
   - TV Shows: `/data/TV Shows`
   - Music: `/data/Music`
   - Photos: `/data/Photos`

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