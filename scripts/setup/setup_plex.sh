#!/bin/bash
# Source common functions using absolute path
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../common/common.sh"

# Colors
export RED='\033[0;31m'
export GREEN='\033[0;32m'
export YELLOW='\033[1;33m'
export NC='\033[0m'

# Start setup
echo "=== Plex Setup ==="

# Ensure .env is ready
setup_env_file

# Verify .env exists
if [ ! -f ".env" ]; then
    echo -e "${RED}Error: .env file not found in plex-docker-setup directory${NC}"
    exit 1
fi

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
    # Install docker.io and docker-compose-plugin (v2, Go-based - avoids Python compatibility issues)
    apt-get install -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" -y -q docker.io docker-compose-plugin
    
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

# Get claim token
echo "Please get your claim token from https://plex.tv/claim"
echo "Enter your Plex claim token:"
read -r plex_claim
sed -i "s/PLEX_CLAIM=.*/PLEX_CLAIM=$plex_claim/" .env
# Export for immediate use
export PLEX_CLAIM="$plex_claim"

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
# Export for immediate use
export PLEX_HOST="$plex_host"
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
# Export for immediate use
export TZ="$timezone"

# Configure Git to ignore file permission changes
echo -e "\n${YELLOW}Configuring Git...${NC}"
git config core.fileMode false

# Stash any local changes
if git diff --quiet; then
    echo -e "${GREEN}✓ Git working directory clean${NC}"
else
    echo -e "${YELLOW}Stashing local changes...${NC}"
    git stash
fi

# Verify running as root
if [ "$(id -u)" != "0" ]; then
    echo -e "${RED}Error: This script must be run as root${NC}"
    exit 1
fi

# Verify exports
echo -e "\n${YELLOW}Verifying environment variables:${NC}"
echo "PLEX_CLAIM=$PLEX_CLAIM"
echo "PLEX_HOST=$PLEX_HOST"
echo "TZ=$TZ"

# Verify USB storage is set up
echo -e "\n${YELLOW}Verifying USB storage...${NC}"

echo -e "\n${YELLOW}Checking available block devices:${NC}"
lsblk

# Function to detect USB storage device
# Returns only the device path - all messages go to stderr
detect_usb_storage() {
    local usb_device=""
    
    # Check for USB devices (sda, sdb, sdc, sdd, etc.)
    for device in /dev/sd[a-z]; do
        if [ -b "$device" ]; then
            # First check: Is it a USB device using udevadm?
            if udevadm info --query=property --name="$device" 2>/dev/null | grep -q "ID_BUS=usb"; then
                usb_device="$device"
                echo -e "${GREEN}Found USB storage device: $usb_device${NC}" >&2
                break
            fi
        fi
    done
    
    # Fallback: if no USB device found via udevadm, check for any /dev/sd* device
    # (some USB devices don't report ID_BUS=usb properly)
    if [ -z "$usb_device" ]; then
        for device in /dev/sd[a-z]; do
            if [ -b "$device" ]; then
                # Accept any sd* device (these are typically USB/SATA, not the SD card which is mmcblk*)
                usb_device="$device"
                echo -e "${YELLOW}Found potential storage device: $usb_device${NC}" >&2
                break
            fi
        done
    fi
    
    # Only output the device path (no other text)
    echo "$usb_device"
}

# Detect USB storage
USB_DEVICE=$(detect_usb_storage)

if [ -z "$USB_DEVICE" ]; then
    echo -e "${RED}Error: No USB storage device found${NC}"
    echo -e "${YELLOW}Please ensure your Samsung USB drive is connected${NC}"
    echo "Available devices:"
    lsblk
    echo ""
    echo "Would you like to:"
    echo "1) Retry detection"
    echo "2) Manually specify device (e.g., /dev/sda)"
    echo "3) Exit and check connections"
    read -r choice
    
    case $choice in
        2)
            echo "Enter device path (e.g., /dev/sda):"
            read -r USB_DEVICE
            if [ ! -b "$USB_DEVICE" ]; then
                echo -e "${RED}Error: Device $USB_DEVICE not found${NC}"
                exit 1
            fi
            ;;
        3)
            exit 1
            ;;
        *)
            echo -e "${RED}Exiting. Please check your USB drive connection and try again.${NC}"
            exit 1
            ;;
    esac
fi

# Check if USB device is already mounted
MOUNT_POINT=$(mount | grep "$USB_DEVICE" | awk '{print $3}' | head -1)

if [ -z "$MOUNT_POINT" ]; then
    echo -e "${YELLOW}USB device $USB_DEVICE is not mounted${NC}"
    echo "Checking if device has a filesystem..."
    
    # Check for existing filesystem
    if blkid "$USB_DEVICE"* | grep -q "TYPE="; then
        echo -e "${GREEN}Found existing filesystem on $USB_DEVICE${NC}"
        echo "Would you like to mount it at /mnt/blockstore? (y/n)"
        read -r mount_choice
        
        if [ "$mount_choice" = "y" ] || [ "$mount_choice" = "Y" ]; then
            # Get the partition (usually device + 1)
            PARTITION="${USB_DEVICE}1"
            if [ ! -b "$PARTITION" ]; then
                PARTITION="$USB_DEVICE"
            fi
            
            # Create mount point
            mkdir -p /mnt/blockstore
            
            # Mount the device
            mount "$PARTITION" /mnt/blockstore
            
            if [ $? -eq 0 ]; then
                echo -e "${GREEN}✓ Successfully mounted $PARTITION at /mnt/blockstore${NC}"
                
                # Add to fstab for persistence
                UUID=$(blkid -s UUID -o value "$PARTITION")
                if [ -n "$UUID" ]; then
                    if ! grep -q "$UUID" /etc/fstab; then
                        echo "UUID=$UUID /mnt/blockstore ext4 defaults 0 2" >> /etc/fstab
                        echo -e "${GREEN}✓ Added to /etc/fstab for automatic mounting${NC}"
                    fi
                fi
            else
                echo -e "${RED}Error: Failed to mount $PARTITION${NC}"
                exit 1
            fi
        else
            echo -e "${YELLOW}Please mount your USB drive manually and run the script again${NC}"
            exit 1
        fi
    else
        echo -e "${YELLOW}No filesystem found on $USB_DEVICE${NC}"
        echo "Would you like to format it? (WARNING: This will erase all data!) (y/n)"
        read -r format_choice
        
        if [ "$format_choice" = "y" ] || [ "$format_choice" = "Y" ]; then
            echo -e "${YELLOW}Formatting $USB_DEVICE as ext4...${NC}"
            mkfs.ext4 -F "$USB_DEVICE"
            
            if [ $? -eq 0 ]; then
                echo -e "${GREEN}✓ Formatting complete${NC}"
                
                # Create mount point and mount
                mkdir -p /mnt/blockstore
                mount "$USB_DEVICE" /mnt/blockstore
                
                if [ $? -eq 0 ]; then
                    echo -e "${GREEN}✓ Successfully mounted at /mnt/blockstore${NC}"
                    
                    # Add to fstab
                    UUID=$(blkid -s UUID -o value "$USB_DEVICE")
                    if [ -n "$UUID" ]; then
                        echo "UUID=$UUID /mnt/blockstore ext4 defaults 0 2" >> /etc/fstab
                        echo -e "${GREEN}✓ Added to /etc/fstab for automatic mounting${NC}"
                    fi
                else
                    echo -e "${RED}Error: Failed to mount after formatting${NC}"
                    exit 1
                fi
            else
                echo -e "${RED}Error: Formatting failed${NC}"
                exit 1
            fi
        else
            echo -e "${YELLOW}Please format and mount your USB drive manually and run the script again${NC}"
            exit 1
        fi
    fi
else
    echo -e "${GREEN}✓ USB device is already mounted at $MOUNT_POINT${NC}"
    
    # If mounted elsewhere, check if we should use it or remount
    if [ "$MOUNT_POINT" != "/mnt/blockstore" ]; then
        echo -e "${YELLOW}Device is mounted at $MOUNT_POINT, but we need /mnt/blockstore${NC}"
        echo "Would you like to remount it at /mnt/blockstore? (y/n)"
        read -r remount_choice
        
        if [ "$remount_choice" = "y" ] || [ "$remount_choice" = "Y" ]; then
            umount "$MOUNT_POINT"
            mkdir -p /mnt/blockstore
            mount "$USB_DEVICE" /mnt/blockstore
            echo -e "${GREEN}✓ Remounted at /mnt/blockstore${NC}"
        else
            echo -e "${YELLOW}Using existing mount point: $MOUNT_POINT${NC}"
            # Update the mount point variable
            MOUNT_POINT="/mnt/blockstore"
        fi
    fi
fi

# Create required directories
echo -e "\n${YELLOW}Creating directories...${NC}"

# Verify directory structure
echo -e "\n${YELLOW}Verifying directory structure:${NC}"
REQUIRED_DIRS=(
    "/mnt/blockstore/plex"
    "/mnt/blockstore/plex/media"
    "/mnt/blockstore/plex/media/Movies"
    "/mnt/blockstore/plex/media/TV Shows"
    "/mnt/blockstore/plex/media/Music"
    "/mnt/blockstore/plex/media/Photos"
    "/opt/plex"
    "/opt/plex/database"
    "/opt/plex/transcode"
)

for dir in "${REQUIRED_DIRS[@]}"; do
    if [ -d "$dir" ]; then
        echo -e "${GREEN}✓ Found $dir${NC}"
    else
        echo -e "${YELLOW}Creating $dir${NC}"
        mkdir -p "$dir"
    fi
done

# Remove any recursive symlinks
if [ -L "/mnt/blockstore/plex/media/media" ]; then
    echo -e "${YELLOW}Removing recursive symlink...${NC}"
    rm "/mnt/blockstore/plex/media/media"
fi

# Set all permissions at once
echo -e "\n${YELLOW}Setting permissions...${NC}"
chown -R 1000:1000 /opt/plex /mnt/blockstore/plex
chmod -R 755 /opt/plex /mnt/blockstore/plex

# Create symlink to block storage
echo -e "\n${YELLOW}Creating symlinks...${NC}"
ln -sf /mnt/blockstore/plex/media /opt/plex/media
if [ -L "/opt/plex/media" ] && [ -d "/opt/plex/media" ]; then
    echo -e "${GREEN}✓ Media symlink created successfully${NC}"
    ls -l /opt/plex/media
else
    echo -e "${RED}Error: Failed to create media symlink${NC}"
    exit 1
fi

# Verify space
echo -e "\n${YELLOW}Checking available space...${NC}"
AVAIL=$(df -BG /mnt/blockstore | awk 'NR==2 {print $4}' | sed 's/G//')
if [ "$AVAIL" -lt "50" ]; then
    echo -e "${YELLOW}Warning: Less than 50GB available on block storage${NC}"
    df -h /mnt/blockstore
fi

# Start Plex
docker compose up -d

# Wait for container to start
echo -e "\n${YELLOW}Waiting for Plex container to start...${NC}"
sleep 5
if docker ps | grep -q plex; then
    echo -e "${GREEN}✓ Plex container is running${NC}"
else
    echo -e "${RED}! Plex container failed to start${NC}"
    echo "Check logs with: docker compose logs plex"
fi

echo -e "${GREEN}✓ Plex setup complete!${NC}"
if [ -n "$plex_host" ]; then
    echo "Access Plex at: http://$plex_host:32400/web"
else
    echo "Access Plex at: http://localhost:32400/web"
fi
echo -e "\n${YELLOW}Note: It may take a few minutes for Plex to start up${NC}"
echo "Check container status with: docker ps"

# Add media location info
echo -e "\n${GREEN}Media Directory:${NC}"
echo "Common folders:"
echo "- /opt/plex/media/Movies"
echo "- /opt/plex/media/TV Shows"
echo "- /opt/plex/media/Music"
echo "- /opt/plex/media/Photos"
echo "- /opt/plex/media/Home Videos"
echo -e "${YELLOW}Note: Plex uses case-sensitive folder names${NC}"
echo -e "${YELLOW}These folders are ready for you to add media${NC}"

# Setup weekly cleanup
echo -e "\n${YELLOW}Setting up weekly cleanup...${NC}"
(crontab -l 2>/dev/null; echo "0 3 * * 0 $(pwd)/scripts/maintenance/cleanup.sh") | crontab -
echo -e "${GREEN}✓ Weekly cleanup scheduled${NC}"

# Configure Git and script permissions
echo -e "\n${YELLOW}Configuring Git and script permissions...${NC}"

# Make all scripts executable
find "$(dirname "$0")/.." -type f -name "*.sh" -exec chmod +x {} \;

# Create post-merge hook
mkdir -p .git/hooks
cat > .git/hooks/post-merge << 'EOF'
#!/bin/bash

echo "Running post-merge hook..."

# Make all scripts executable
find scripts/ -type f -name "*.sh" -exec chmod +x {} \;

# Set specific permissions for sensitive files
chmod 600 .env 2>/dev/null || true
chmod 600 .env.example

echo "Updated file permissions"
EOF

# Make the hook executable
chmod +x .git/hooks/post-merge

# Create .gitattributes if it doesn't exist
if [ ! -f ".gitattributes" ]; then
    echo -e "# Ignore permission changes on scripts\nscripts/**/*.sh -diff" > .gitattributes
    echo -e "${GREEN}✓ Created .gitattributes${NC}"
fi

# Set core.fileMode to false
echo -e "\n${YELLOW}Checking Git core.fileMode setting...${NC}"
current_file_mode=$(git config --get core.fileMode)

if [ "$current_file_mode" != "false" ]; then
    echo -e "${YELLOW}Setting core.fileMode to false${NC}"
    git config core.fileMode false
else
    echo -e "${GREEN}✓ core.fileMode is already set to false${NC}"
fi

# Add specific script changes to .gitignore if not already present
if ! grep -q "^scripts/\*\*/\*.log" .gitignore 2>/dev/null; then
    echo -e "\n# Ignore script outputs and temporary files" >> .gitignore
    echo "scripts/**/*.log" >> .gitignore
    echo "scripts/reports/" >> .gitignore
    echo "scripts/**/*.tmp" >> .gitignore
    echo -e "${GREEN}✓ Added script outputs to .gitignore${NC}"
fi

echo -e "${GREEN}✓ Git hooks and permissions configured${NC}" 