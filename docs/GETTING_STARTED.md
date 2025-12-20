# Getting Started - Raspberry Pi 5 Plex Setup

Complete step-by-step guide from unboxing to running Plex on your Raspberry Pi 5.

## What You'll Need

### Hardware
- **Raspberry Pi 5** (16GB RAM recommended for best performance)
- **MicroSD Card** (32GB minimum, 64GB+ recommended, Class 10 or better)
- **Samsung USB Drive** (2TB recommended for media storage)
- **Power Supply** (Official Raspberry Pi 5 USB-C power supply recommended)
- **USB-C Cable** (for power, if not included)
- **USB Cable** (USB-A to USB-C or USB-A to USB-A, depending on your USB drive)
- **Ethernet Cable** (for initial setup, or use WiFi)
- **Computer** (Windows, Mac, or Linux) to flash the OS image

### Software
- **Raspberry Pi Imager** - Download from [raspberrypi.com/software](https://www.raspberrypi.com/software/)
- **Ubuntu 22.04 LTS ARM64** image (will be downloaded via Imager)

## Step 1: Initial Hardware Setup

### 1.1 Prepare the MicroSD Card

1. **Insert the microSD card** into your computer's card reader
2. **Download Raspberry Pi Imager**:
   - Visit [raspberrypi.com/software](https://www.raspberrypi.com/software/)
   - Download and install Raspberry Pi Imager for your operating system

3. **Flash Ubuntu to the microSD card**:
   - Open Raspberry Pi Imager
   - Click "Choose OS"
   - Select "Other general-purpose OS" → "Ubuntu" → "Ubuntu 22.04.3 LTS (Raspberry Pi)"
   - Click "Choose Storage" and select your microSD card
   - **Important**: Click the gear icon (⚙️) to configure:
     - **Enable SSH**: Check this box
     - **Set username and password**: Choose a username (e.g., `pi`) and strong password
     - **Configure wireless LAN** (optional): Enter your WiFi SSID and password if using WiFi
     - **Set locale settings**: Choose your timezone
   - Click "Save" then "Write"
   - Wait for the image to be written and verified (this may take 10-15 minutes)

### 1.2 Assemble the Raspberry Pi

1. **Insert the microSD card** into the Raspberry Pi 5 (slot is on the bottom)
2. **Connect peripherals** (if using):
   - HDMI cable to monitor/TV
   - USB keyboard and mouse
3. **Connect Ethernet cable** (if using wired network)
4. **DO NOT connect the USB drive yet** - we'll do that after initial setup
5. **Connect the power supply** last (USB-C port)

## Step 2: First Boot and Initial Configuration

### 2.1 Boot the Raspberry Pi

1. **Power on** the Raspberry Pi by connecting the power supply
2. **Wait 1-2 minutes** for the system to boot (first boot takes longer)
3. **Find the IP address**:
   - **If using a monitor**: The IP address may be displayed on screen
   - **If using SSH**: Check your router's admin panel or use:
     ```bash
     # On your computer (if on same network)
     ping raspberrypi.local
     # Or scan your network
     ```

### 2.2 Connect to Your Raspberry Pi

**Option A: SSH (Recommended)**
```bash
# From your computer
ssh username@raspberrypi.local
# Or use the IP address
ssh username@192.168.1.XXX
```

**Option B: Direct Connection (Monitor + Keyboard)**
- Log in with the username and password you set in Raspberry Pi Imager

### 2.3 Initial System Updates

Once connected, update the system:

```bash
# Update package lists
sudo apt update

# Upgrade all packages
sudo apt upgrade -y

# Install essential tools
sudo apt install -y git curl wget

# Reboot to ensure all updates are applied
sudo reboot
```

Wait 1-2 minutes, then reconnect via SSH.

## Step 3: Connect and Prepare USB Drive

### 3.1 Connect the Samsung USB Drive

1. **Power off the Raspberry Pi** (if it's running):
   ```bash
   sudo shutdown -h now
   ```

2. **Connect your Samsung USB drive**:
   - Use a USB-A to USB-C cable (or USB-A to USB-A adapter)
   - Connect to one of the USB 3.0 ports on the Raspberry Pi 5
   - **USB-C port is recommended** for better performance (if your drive supports it)

3. **Power on the Raspberry Pi** and reconnect via SSH

### 3.2 Verify USB Drive is Detected

```bash
# Check if the USB drive is detected
lsblk

# You should see your USB drive listed, typically as:
# sda or sdb (if microSD is sda)
# Look for a device with the size matching your USB drive (e.g., 2TB)
```

**Example output:**
```
NAME        MAJ:MIN RM   SIZE RO TYPE MOUNTPOINT
mmcblk0     179:0    0  64G  0 disk
└─mmcblk0p1 179:1    0  64G  0 part /
sda         8:0      0   1.8T  0 disk    # <-- This is your USB drive
```

## Step 4: Install Plex Server

### 4.1 Clone the Repository

```bash
# Navigate to your home directory
cd ~

# Clone the repository
git clone https://github.com/joereg4/rasberry-pi-plex-docker-setup.git

# Navigate into the directory
cd rasberry-pi-plex-docker-setup

# Make setup scripts executable
chmod +x scripts/setup/*.sh
```

### 4.2 Get Your Plex Claim Token

1. **Open a web browser** on your computer
2. **Visit**: [https://plex.tv/claim](https://plex.tv/claim)
3. **Sign in** with your Plex account (or create one if needed)
4. **Copy the claim token** (it looks like: `claim-xxxxxxxxxxxxxxxxxxxx`)
5. **Keep this token handy** - you'll need it in the next step

### 4.3 Run the Setup Script

```bash
# Run the setup script as root
sudo ./scripts/setup/setup_plex.sh
```

The script will:

1. **Check for Docker** - Install if not present
2. **Prompt for Plex claim token** - Paste the token you copied
3. **Configure Plex host** - Choose IP address, domain, or localhost
4. **Set timezone** - Select your timezone
5. **Detect USB drive** - Automatically find your Samsung USB drive
6. **Format USB drive** (if needed) - Will ask for confirmation before formatting
7. **Mount USB drive** - Mount at `/mnt/blockstore`
8. **Create directories** - Set up all required media folders
9. **Configure permissions** - Set proper ownership and permissions
10. **Start Plex** - Launch the Plex container

**Follow the prompts** and answer the questions as they appear.

### 4.4 Verify Installation

After the script completes:

```bash
# Check if Plex container is running
docker ps

# You should see a container named "plex" running
# Check Plex logs if needed
docker-compose logs plex
```

## Step 5: Access and Configure Plex

### 5.1 Access Plex Web Interface

1. **Find your Raspberry Pi's IP address** (if you don't know it):
   ```bash
   hostname -I
   ```

2. **Open a web browser** on any device on your network

3. **Navigate to**: `http://YOUR_PI_IP:32400/web`
   - Replace `YOUR_PI_IP` with the IP address from step 1
   - Example: `http://192.168.1.100:32400/web`

4. **Sign in** with your Plex account

### 5.2 Set Up Media Libraries

1. **Click the '+' button** next to "Libraries" in the left sidebar

2. **For each library type** (Movies, TV Shows, Music, Photos):
   - Choose the library type
   - Name your library (e.g., "Movies")
   - Click "Add Folders"
   - Click "Browse for Media Folder"
   - Navigate to `/data` and select:
     * Movies: `/data/Movies`
     * TV Shows: `/data/TV Shows`
     * Music: `/data/Music`
     * Photos: `/data/Photos`

3. **Enable automatic scanning**:
   - Check "Scan my library automatically"
   - Check "Run a partial scan when changes are detected"

### 5.3 Add Media Files

You can add media files to your USB drive using several methods:

**Method 1: SCP (from your computer)**
```bash
# From your computer
scp /path/to/movie.mp4 username@raspberrypi.local:/mnt/blockstore/plex/media/Movies/
```

**Method 2: Samba/Network Share** (set up separately)

**Method 3: Direct copy** (if you have physical access)
```bash
# On the Raspberry Pi
# Copy files to the appropriate directory
sudo cp /path/to/media/* /mnt/blockstore/plex/media/Movies/
```

## Step 6: Verify Everything Works

### 6.1 Test Media Playback

1. **Add a test media file** to one of your libraries
2. **Open Plex** in your web browser
3. **Navigate to the library** and try playing the file
4. **Check playback** - Video should play smoothly

### 6.2 Check System Resources

```bash
# Check CPU and memory usage
htop
# Or
top

# Check disk space
df -h

# Check USB drive is mounted
mount | grep blockstore
```

## Troubleshooting

### USB Drive Not Detected

```bash
# Check USB devices
lsusb

# Check block devices
lsblk

# Check dmesg for USB connection messages
dmesg | tail -20
```

### Plex Container Won't Start

```bash
# Check Docker logs
docker-compose logs plex

# Check if port 32400 is in use
sudo netstat -tulpn | grep 32400

# Restart Docker
sudo systemctl restart docker
docker-compose up -d
```

### Can't Access Plex Web Interface

1. **Check firewall**:
   ```bash
   sudo ufw status
   sudo ufw allow 32400/tcp
   ```

2. **Check Plex is running**:
   ```bash
   docker ps | grep plex
   ```

3. **Verify IP address**:
   ```bash
   hostname -I
   ```

For more troubleshooting help, see [TROUBLESHOOTING.md](TROUBLESHOOTING.md)

## Next Steps

- ✅ **Plex is now running!** Start adding your media files
- 📚 Read the [Setup Guide](SETUP.md) for detailed configuration
- 🌐 Set up a custom domain with [Domain Setup](DOMAIN_SETUP.md)
- 🔒 Review [Security Guide](SECURITY.md) for best practices
- 🔧 Learn about maintenance in the main [README.md](../README.md)

## Quick Reference

**Access Plex**: `http://YOUR_PI_IP:32400/web`

**Media Directories**:
- Movies: `/mnt/blockstore/plex/media/Movies`
- TV Shows: `/mnt/blockstore/plex/media/TV Shows`
- Music: `/mnt/blockstore/plex/media/Music`
- Photos: `/mnt/blockstore/plex/media/Photos`

**Useful Commands**:
```bash
# Restart Plex
docker-compose restart plex

# View logs
docker-compose logs -f plex

# Update Plex
docker-compose pull && docker-compose up -d

# Check status
docker ps
```

---

**Congratulations!** Your Raspberry Pi 5 Plex server is now set up and ready to use! 🎉

