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
    
    # Configure firewall
    if command -v ufw &> /dev/null; then
        echo -e "${YELLOW}Configuring firewall...${NC}"
        ufw allow 32400/tcp  # Plex main port
        ufw allow 32469/tcp  # Plex DLNA
        ufw allow 1900/udp   # Plex DLNA discovery
        ufw allow 32410:32414/udp  # Plex media streaming
        echo -e "${GREEN}✓ Firewall configured${NC}"
    fi
    
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

# Configure PLEX_HOST
echo -e "\n${YELLOW}Configure Plex Host${NC}"
# Try to detect server IP
detected_ip=$(hostname -I | awk '{print $1}')
if [ -n "$detected_ip" ]; then
    echo -e "Detected IP: ${GREEN}$detected_ip${NC}"
fi

echo -e "Choose how to access Plex:"
echo "1) IP Address (detected: ${GREEN}$detected_ip${NC})"
echo "2) Custom Domain"
echo "3) Localhost"
read -r host_choice

case $host_choice in
    1)
        plex_host="$detected_ip"
        echo -e "${GREEN}✓ Using IP address: $plex_host${NC}"
        ;;
    2)
        echo "Enter your domain (e.g., plex.yourdomain.com):"
        read -r plex_host
        echo -e "${YELLOW}Note: Make sure DNS record points to: $detected_ip${NC}"
        
        # Try to verify DNS
        echo -e "\n${YELLOW}Checking DNS resolution...${NC}"
        resolved_ip=$(dig +short "$plex_host" || host "$plex_host" | grep "has address" | awk '{print $4}')
        
        if [ -n "$resolved_ip" ]; then
            echo -e "${GREEN}✓ Domain resolves to: $resolved_ip${NC}"
            if [ "$resolved_ip" != "$detected_ip" ]; then
                echo -e "${RED}Warning: Domain points to different IP${NC}"
                echo -e "Domain IP: $resolved_ip"
                echo -e "Server IP: $detected_ip"
                echo -e "${YELLOW}Please verify your DNS settings${NC}"
                echo -e "\nTroubleshooting tips:"
                echo "1. Check DNS records at your provider"
                echo "2. If using Cloudflare, disable proxy (use DNS only)"
                echo "3. Wait for DNS propagation (up to 60 minutes)"
                echo "4. Try: nslookup $plex_host"
            fi
        else
            echo -e "${RED}Warning: Could not resolve domain${NC}"
            echo "DNS might need time to propagate"
            echo -e "\nTroubleshooting tips:"
            echo "1. Verify domain exists and DNS records are set"
            echo "2. Lower TTL during setup if possible"
            echo "3. Try: dig $plex_host"
        fi
        
        # Configure UFW for port 80/443 if using domain
        if command -v ufw &> /dev/null; then
            echo -e "\n${YELLOW}Configuring firewall for web access...${NC}"
            ufw allow 80/tcp
            ufw allow 443/tcp
            echo -e "${GREEN}✓ Added web ports to firewall${NC}"
        fi
         ;;
    3|"")
        plex_host="localhost"
        echo -e "${YELLOW}Using localhost${NC}"
        ;;
    *)
        echo -e "${RED}Invalid choice. Using localhost${NC}"
        plex_host="localhost"
        ;;
esac

# Update PLEX_HOST in .env
sed -i "s/PLEX_HOST=.*/PLEX_HOST=$plex_host/" .env
echo -e "${GREEN}✓ Plex host set to: $plex_host${NC}"

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
# Set permissions
chown -R 1000:1000 /opt/plex
chmod -R 755 /opt/plex

# Start Plex
docker-compose up -d

# Wait for container to start
echo -e "\n${YELLOW}Waiting for Plex container to start...${NC}"
sleep 5
if docker ps | grep -q plex; then
    echo -e "${GREEN}✓ Plex container is running${NC}"
else
    echo -e "${RED}! Plex container failed to start${NC}"
    echo "Check logs with: docker-compose logs plex"
fi

echo -e "${GREEN}✓ Plex setup complete!${NC}"
if [ -n "$plex_host" ]; then
    echo "Access Plex at: http://$plex_host:32400/web"
else
    echo "Access Plex at: http://localhost:32400/web"
fi
echo -e "\n${YELLOW}Note: It may take a few minutes for Plex to start up${NC}"
echo "Check container status with: docker ps" 