#!/bin/bash
# Colors
export RED='\033[0;31m'
export GREEN='\033[0;32m'
export YELLOW='\033[1;33m'
export NC='\033[0m'

echo "=== Plex Setup ==="

# Pre-configure all system settings to avoid prompts
echo "libc6 libraries/restart-without-asking boolean true" | debconf-set-selections
echo "linux-base want-reboot-on-upgrade boolean false" | debconf-set-selections
echo "needrestart/restart-services boolean false" | debconf-set-selections
echo "needrestart/kernel-restart-required boolean false" | debconf-set-selections

# Prevent service restarts during upgrade
mkdir -p /etc/needrestart/conf.d/
cat > /etc/needrestart/conf.d/10-no-restart.conf <<EOF
\$nrconf{restart} = 'a';
\$nrconf{kernelhints} = 0;
\$nrconf{restart_mode} = 'a';
\$nrconf{kernel_mode} = 'a';
EOF

# Disable all interactive prompts
export DEBIAN_FRONTEND=noninteractive
export NEEDRESTART_MODE=a
export NEEDRESTART_SUSPEND=1
export NEEDRESTART_DISABLE=1

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo -e "${RED}Error: Docker not installed${NC}"
    echo -e "${YELLOW}Installing Docker...${NC}"
    apt-get update
    apt-get install -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" -y -q docker.io docker-compose
    
    # Start and enable Docker
    systemctl start docker
    systemctl enable docker
    
    # Verify installation
    if ! command -v docker &> /dev/null; then
        echo -e "${RED}Docker installation failed${NC}"
        exit 1
    fi
    echo -e "${GREEN}✓ Docker installed successfully${NC}"
fi

# Check/create .env
if [ ! -f ".env" ]; then
    cp .env.example .env
fi

# Get claim token
echo "Please get your claim token from https://plex.tv/claim"
echo "Enter your Plex claim token:"
read -r plex_claim
sed -i "s/PLEX_CLAIM=.*/PLEX_CLAIM=$plex_claim/" .env

# Configure timezone
echo "Select timezone:"
echo "1) America/New_York"
echo "2) America/Chicago"
echo "3) America/Denver"
echo "4) America/Los_Angeles"
echo "5) Custom"
read -r tz_choice

case $tz_choice in
    1) timezone="America/New_York" ;;
    2) timezone="America/Chicago" ;;
    3) timezone="America/Denver" ;;
    4) timezone="America/Los_Angeles" ;;
    5) 
        echo "Enter custom timezone:"
        read -r timezone
        ;;
esac

sed -i "s|TZ=.*|TZ=$timezone|" .env

# Create directories
mkdir -p /opt/plex/{config,media}

# Start Plex
docker-compose up -d

echo -e "${GREEN}✓ Plex setup complete!${NC}"
echo "Access Plex at: http://localhost:32400/web" 