# Setup Guide

## Prerequisites
- Ubuntu 22.04 LTS
- Docker installed
- Git installed
- Block storage attached to server

## Initial Setup

### 1. Block Storage Setup
```bash
# Create mount point
sudo mkdir -p /mnt/blockstore

# First, check which device is your block storage
lsblk
# Usually /dev/vdc for Vultr block storage
sudo mkfs.ext4 /dev/vdc

# Mount block storage
sudo mount /dev/vdc /mnt/blockstore

# Add to fstab for persistence
echo "/dev/vdc /mnt/blockstore ext4 defaults,nofail 0 0" | sudo tee -a /etc/fstab

# Create media directories
sudo mkdir -p /mnt/blockstore/plex/media/{Movies,"TV Shows",Music,Photos}

# Set permissions
sudo chown -R 1000:1000 /mnt/blockstore/plex
sudo chmod -R 755 /mnt/blockstore/plex
```

### 2. Plex Setup
```bash
# Clone repository
git clone https://github.com/joereg4/plex-docker-setup.git
cd plex-docker-setup

# Copy and edit environment file
cp .env.example .env
nano .env
```

Required variables:
- `PLEX_CLAIM`: Get from [plex.tv/claim](https://plex.tv/claim)

### 3. Run Setup
```bash
chmod +x scripts/setup/setup_plex.sh
./scripts/setup/setup_plex.sh
```

The setup script will:
- Create required directories in /opt/plex
- Link media directories to block storage
- Set correct permissions
- Start Plex container
- Verify container is running

```bash
chmod +x scripts/setup/setup_plex.sh
./scripts/setup/setup_plex.sh
```

The script performs several checks:
- Verifies block storage is mounted
- Checks filesystem type and permissions
- Ensures enough space is available
- Validates environment variables

If any check fails, the script will show what needs to be fixed.

## Verification
### 1. Block Storage
```bash
# Check block device exists
lsblk

# Verify mount
df -h /mnt/blockstore

# Check filesystem type
df -T /mnt/blockstore

# Verify permissions
ls -ld /mnt/blockstore/plex
ls -l /mnt/blockstore/plex/media/

# Test write access
touch /mnt/blockstore/plex/media/test_file
rm /mnt/blockstore/plex/media/test_file
```

### 2. Directory Structure
```bash
ls -la /opt/plex/media
ls -la /opt/plex/{database,transcode}
```

### 3. Plex Container
```bash
# Check container status
docker ps

# View logs
docker logs plex
```

### 4. Access Plex:
- Open `http://YOUR_SERVER_IP:32400/web`
- Sign in with your Plex account
- Add media libraries pointing to:
  * Movies: `/data/Movies`
  * TV Shows: `/data/TV Shows`
  * Music: `/data/Music`
  * Photos: `/data/Photos`

### 5. Test Media Access
```bash
# Create test file
touch "/mnt/blockstore/plex/media/Movies/test.mp4"

# Verify it appears in Plex
# Then clean up
rm "/mnt/blockstore/plex/media/Movies/test.mp4"
```

## Troubleshooting
If you see "No soup for you":
1. Stop Plex: `docker stop plex`
2. Edit preferences:
```bash
nano /opt/plex/Library/Application\ Support/Plex\ Media\ Server/Preferences.xml
```
3. Remove these lines:
```xml
PlexOnlineHome="1"
PlexOnlineMail="your-email@example.com"
PlexOnlineToken="your-token"
PlexOnlineUsername="your-username"
```
4. Start Plex: `docker start plex`

## Block Storage Management

### Expanding Block Storage
When you need more space, follow these steps:

1. Stop Plex and unmount storage:
   ```bash
   # Stop Plex container
   cd ~/plex-docker-setup
   docker-compose down
   
   # Unmount block storage
   sudo umount /mnt/blockstore
   ```

2. In Vultr Dashboard:
   - Go to Products > Block Storage
   - Select your block storage volume
   - Click "Detach"
   - Wait for status to show "detached"
   - Click "Resize"
   - Enter new size (e.g., 100GB)
   - Wait for resize to complete
   - Click "Attach"
   - Select your instance
   - Wait for status to show "attached"

3. On your server, resize and remount:
   ```bash
   # Resize the filesystem
   sudo resize2fs /dev/vdb
   
   # Mount block storage
   sudo mount /dev/vdb /mnt/blockstore
   
   # Verify new size
   df -h /mnt/blockstore
   
   # Start Plex
   docker-compose up -d
   ```

Note: If SSH disconnects during this process, wait 30 seconds and reconnect before continuing.  