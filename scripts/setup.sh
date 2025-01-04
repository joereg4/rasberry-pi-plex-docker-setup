#!/bin/bash

# Error handling
set -e  # Exit on error

# Function to handle errors
handle_error() {
    local line_number=$1
    echo "Error occurred in line $line_number"
    case $line_number in
        *"apt"*) echo "Package installation failed. Check internet connection and try again." ;;
        *"git"*) echo "Repository clone failed. Check permissions and connectivity." ;;
        *"chmod"*) echo "Script permission setting failed. Check directory permissions." ;;
        *) echo "Unknown error occurred. Please check the logs." ;;
    esac
}

trap 'handle_error $LINENO' ERR

# Function to check installation
check_install() {
    if ! command -v $1 &> /dev/null; then
        echo "Error: $1 installation failed"
        exit 1
    fi
}

# Update system
echo "Updating system packages..."
apt update && apt upgrade -y

# Install required packages
echo "Installing required packages..."
apt install -y docker.io docker-compose git ufw htop ffmpeg mailutils

# Optional: Configure email if credentials exist
if [ -n "$SMTP_HOST" ]; then
    echo "Configuring email notifications..."
    # Install postfix for email capability
    DEBIAN_FRONTEND=noninteractive apt install -y postfix
fi

# Verify installations
for cmd in docker docker-compose git ufw htop ffmpeg; do
    check_install $cmd
done

# Enable and start Docker
echo "Configuring Docker..."
systemctl enable docker
systemctl start docker

# Configure UFW
echo "Setting up firewall..."
ufw default deny incoming
ufw default allow outgoing
ufw allow ssh
ufw allow 32400/tcp  # Plex main port
ufw allow 32469/tcp  # Plex DLNA
ufw allow 1900/udp   # Plex DLNA discovery
ufw allow 32410:32414/udp  # Plex media streaming
echo "y" | ufw enable

# Create Plex directories
echo "Creating directories..."

# Check for block storage
if [ -b "/dev/sdb" ]; then
    echo "Setting up block storage..."
    mkfs.ext4 /dev/sdb
    mkdir -p /mnt/blockstore
    mount /dev/sdb /mnt/blockstore
    echo "/dev/sdb /mnt/blockstore ext4 defaults 0 0" >> /etc/fstab
    mkdir -p /mnt/blockstore/plex/media
    ln -s /mnt/blockstore/plex/media /opt/plex/media
else
    # Use local storage
    mkdir -p /opt/plex/media
fi

mkdir -p /opt/plex/config

# Set permissions
chown -R 1000:1000 /opt/plex

# Clone repository
echo "Cloning repository..."
cd /opt
git clone https://github.com/joereg4/plex-docker-setup.git
cd plex-docker-setup

# Make scripts executable
chmod +x scripts/*.sh

# Create environment file
cp .env.example .env

# Set up automatic storage checks
echo "Setting up automatic storage monitoring..."
(crontab -l 2>/dev/null || echo "") | { cat; echo "0 0 * * * /opt/plex-docker-setup/scripts/check_storage.sh > /opt/plex-docker-setup/scripts/reports/storage_$(date +\%Y\%m\%d).log 2>&1"; } | crontab -
(crontab -l 2>/dev/null || echo "") | { cat; echo "0 1 * * 0 /opt/plex-docker-setup/scripts/optimize_media.sh > /opt/plex-docker-setup/scripts/reports/optimize_$(date +\%Y\%m\%d).log 2>&1"; } | crontab -

echo "==============================================="
echo "Setup complete!"
echo "==============================================="
echo "Next steps:"
echo "1. Edit .env file with your settings: nano .env"
echo "2. Start Plex: docker-compose up -d"
echo ""
echo "Security Recommendations:"
echo "- Set up SSH key authentication"
echo "- Review firewall rules: ufw status"
echo "- Keep system updated: apt update && apt upgrade"
echo ""
echo "Storage Management:"
echo "Automatic monitoring has been set up:"
echo "- Daily storage check at midnight"
echo "- Weekly optimization check on Sundays at 1 AM"
echo ""
echo "Manual monitoring commands:"
echo "- Monitor storage: ./scripts/check_storage.sh"
echo "- Check for optimization: ./scripts/optimize_media.sh"
echo ""
echo "Reports location: /opt/plex-docker-setup/scripts/reports/"
echo ""
echo "To view recent storage report:"
echo "cat /opt/plex-docker-setup/scripts/reports/storage_$(date +%Y%m%d).log" 