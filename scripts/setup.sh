#!/bin/bash

# Update system
apt update && apt upgrade -y

# Install required packages
apt install -y docker.io docker-compose git ufw htop

# Enable and start Docker
systemctl enable docker
systemctl start docker

# Configure UFW
ufw default deny incoming
ufw default allow outgoing
ufw allow ssh
ufw allow 32400/tcp  # Plex main port
ufw allow 32469/tcp  # Plex DLNA
ufw allow 1900/udp   # Plex DLNA discovery
ufw allow 32410:32414/udp  # Plex media streaming
echo "y" | ufw enable

# Create Plex directories
mkdir -p /opt/plex/config
mkdir -p /opt/plex/media

# Set permissions
chown -R 1000:1000 /opt/plex

# Clone repository
cd /opt
git clone https://github.com/joereg4/plex-docker-setup.git
cd plex-docker-setup

# Create environment file
cp .env.example .env

echo "Setup complete!"
echo "Next steps:"
echo "1. Edit .env file with your settings: nano .env"
echo "2. Start Plex: docker-compose up -d"
echo ""
echo "Security Recommendations:"
echo "- Set up SSH key authentication"
echo "- Review firewall rules: ufw status"
echo "- Keep system updated: apt update && apt upgrade" 