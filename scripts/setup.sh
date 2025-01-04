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

# Function to check if running in container
in_container() {
    [ -f /.dockerenv ] && return 0 || return 1
}

# Update system
echo "Updating system packages..."
apt update && apt upgrade -y

# Install required packages
echo "Installing required packages..."
if in_container; then
    apt install -y git curl wget nano ffmpeg golang-go
else
    apt install -y docker.io docker-compose git ufw htop ffmpeg mailutils
fi

# Install Vultr CLI
echo "Installing Vultr CLI..."
# Install Go (required for Vultr CLI)
apt install -y golang-go

# Install Vultr CLI using Go
go install github.com/vultr/vultr-cli@latest

# Move vultr-cli to system path
mv ~/go/bin/vultr-cli /usr/local/bin/

# Configure Vultr CLI if API key exists
if [ -n "$VULTR_API_KEY" ]; then
    echo "Configuring Vultr CLI..."
    mkdir -p ~/.vultr-cli
    echo "api-key: ${VULTR_API_KEY}" > ~/.vultr-cli/config.yaml
    
    # Verify CLI works
    if ! vultr-cli account info &>/dev/null; then
        echo -e "${RED}Warning: Vultr CLI configuration failed${NC}"
    else
        echo -e "${GREEN}Vultr CLI configured successfully${NC}"
    fi
fi

# Optional: Configure email if credentials exist
if [ -n "$SMTP_HOST" ]; then
    echo "Configuring email notifications..."
    # Install postfix for email capability
    DEBIAN_FRONTEND=noninteractive apt install -y postfix
fi

# Verify installations
for cmd in docker docker-compose git ufw htop ffmpeg vultr-cli; do
    check_install $cmd
done

# Enable and start Docker
echo "Configuring Docker..."
if ! in_container && command -v systemctl >/dev/null 2>&1; then
    systemctl enable docker
    systemctl start docker
else
    echo "Running in container - skipping Docker service management"
fi

# Configure UFW
echo "Setting up firewall..."
if command -v systemctl >/dev/null 2>&1; then
    ufw default deny incoming
    ufw default allow outgoing
    ufw allow ssh
    ufw allow 32400/tcp  # Plex main port
    ufw allow 32469/tcp  # Plex DLNA
    ufw allow 1900/udp   # Plex DLNA discovery
    ufw allow 32410:32414/udp  # Plex media streaming
    echo "y" | ufw enable
else
    echo "Running in container - skipping firewall configuration"
fi

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

# Interactive configuration
echo "==============================================="
echo "Plex Configuration"
echo "==============================================="
echo "Would you like to configure Plex settings now? (y/n)"
read -r configure_plex

if [ "$configure_plex" = "y" ]; then
    # Get claim token
    echo "Please get your claim token from https://plex.tv/claim"
    echo "Enter your Plex claim token:"
    read -r plex_claim
    sed -i "s/PLEX_CLAIM=.*/PLEX_CLAIM=$plex_claim/" .env
    
    # Timezone selection
    echo "Common US timezones:"
    echo "1) America/New_York (Eastern)"
    echo "2) America/Chicago (Central)"
    echo "3) America/Denver (Mountain)"
    echo "4) America/Los_Angeles (Pacific)"
    echo "5) America/Anchorage (Alaska)"
    echo "6) Pacific/Honolulu (Hawaii)"
    echo "7) Custom timezone"
    echo ""
    echo "Select timezone (1-7, default: America/New_York):"
    read -r tz_choice
    
    case $tz_choice in
        1) timezone="America/New_York" ;;
        2) timezone="America/Chicago" ;;
        3) timezone="America/Denver" ;;
        4) timezone="America/Los_Angeles" ;;
        5) timezone="America/Anchorage" ;;
        6) timezone="Pacific/Honolulu" ;;
        7)
            echo "Enter custom timezone (e.g., Europe/London)"
            echo "List all timezones? (y/n)"
            read -r list_tz
            if [ "$list_tz" = "y" ]; then
                timedatectl list-timezones
                echo "Press Enter to continue..."
                read -r
            fi
            echo "Enter timezone:"
            read -r timezone
            ;;
        *) timezone="America/New_York" ;;
    esac
    if [ -n "$timezone" ]; then
        sed -i "s/TZ=.*/TZ=$timezone/" .env
    fi
fi

# Interactive configuration
echo "==============================================="
echo "Vultr Configuration"
echo "==============================================="
echo "Would you like to configure Vultr settings now? (y/n)"
read -r configure_vultr

if [ "$configure_vultr" = "y" ]; then
    echo "Enter your Vultr API key (from https://my.vultr.com/settings/#settingsapi):"
    read -r vultr_api_key
    
    # Update .env with Vultr settings
    sed -i "s/VULTR_API_KEY=.*/VULTR_API_KEY=$vultr_api_key/" .env
    
    # Configure Vultr CLI
    mkdir -p ~/.vultr-cli
    echo "api-key: ${vultr_api_key}" > ~/.vultr-cli/config.yaml
    
    # Get instance information
    echo "Fetching instance information..."
    if vultr-cli instance list &>/dev/null; then
        echo "Enter the Block Storage ID (leave blank if not using block storage):"
        read -r block_id
        if [ -n "$block_id" ]; then
            sed -i "s/VULTR_BLOCK_ID=.*/VULTR_BLOCK_ID=$block_id/" .env
        fi
        
        echo "Enter your Instance ID:"
        read -r instance_id
        sed -i "s/VULTR_INSTANCE_ID=.*/VULTR_INSTANCE_ID=$instance_id/" .env
    else
        echo "Failed to connect to Vultr API. Please configure manually later."
    fi
else
    echo "Skipping Vultr configuration. You can configure later by editing .env"
fi

echo "==============================================="
echo "Email Configuration"
echo "==============================================="
echo "Would you like to configure email notifications? (y/n)"
read -r configure_email

if [ "$configure_email" = "y" ]; then
    echo "Using SendGrid for email notifications"
    echo "Enter your SendGrid API key:"
    read -r sendgrid_key
    sed -i "s/SMTP_PASS=.*/SMTP_PASS=$sendgrid_key/" .env

    echo "Enter your notification email address:"
    read -r notify_email
    sed -i "s/NOTIFY_EMAIL=.*/NOTIFY_EMAIL=$notify_email/" .env
    
    echo "Enter the email address to send from:"
    read -r smtp_user
    sed -i "s/SMTP_USER=.*/SMTP_USER=$smtp_user/" .env
fi

# Set up automatic storage checks
echo "Setting up automatic storage monitoring..."
(crontab -l 2>/dev/null || echo "") | { cat; echo "0 0 * * * /opt/plex-docker-setup/scripts/check_storage.sh > /opt/plex-docker-setup/scripts/reports/storage_$(date +\%Y\%m\%d).log 2>&1"; } | crontab -
(crontab -l 2>/dev/null || echo "") | { cat; echo "0 1 * * 0 /opt/plex-docker-setup/scripts/optimize_media.sh > /opt/plex-docker-setup/scripts/reports/optimize_$(date +\%Y\%m\%d).log 2>&1"; } | crontab -
(crontab -l 2>/dev/null || echo "") | { cat; echo "0 * * * * /opt/plex-docker-setup/scripts/manage_storage.sh auto > /opt/plex-docker-setup/scripts/reports/storage_expansion_$(date +\%Y\%m\%d).log 2>&1"; } | crontab -

echo "==============================================="
echo "Setup complete!"
echo "==============================================="
echo "Your configuration has been saved to: /opt/plex-docker-setup/.env"
echo ""
echo "Review your configuration:"
echo "nano /opt/plex-docker-setup/.env"
echo ""
echo "Current .env contents:"
echo "----------------------------------------"
cat .env | grep -v "PASS\|KEY\|TOKEN"  # Show contents except sensitive data
echo "----------------------------------------"
echo "Sensitive data has been hidden. Use 'cat .env' to see all values"
echo ""
echo "Next steps:"
echo "1. Edit .env file if needed: nano .env"
echo "2. Start Plex: docker-compose up -d"
echo ""
echo "Security Recommendations:"
echo "- Set up SSH key authentication"
echo "- Review firewall rules: ufw status"
echo "- Keep system updated: apt update && apt upgrade"
echo ""
echo "Vultr Management:"
echo "- Check Vultr status: vultr-cli account info"
echo "- List instances: vultr-cli instance list"
echo "- View block storage: vultr-cli block-storage list"
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