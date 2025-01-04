#!/bin/bash

# Error handling
set -e  # Exit on error

# Create needrestart config directory
mkdir -p /etc/needrestart/conf.d/

# Pre-configure all system settings to avoid prompts
echo "libc6 libraries/restart-without-asking boolean true" | debconf-set-selections
echo "linux-base want-reboot-on-upgrade boolean false" | debconf-set-selections
echo "needrestart/restart-services boolean false" | debconf-set-selections
echo "needrestart/kernel-restart-required boolean false" | debconf-set-selections

# Prevent service restarts during upgrade
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

# Function to install package non-interactively
install_package() {
    local package=$1
    echo "Installing $package..."
    if ! apt-get install -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" -y -q "$package"; then
        echo "Failed to install $package"
        return 1
    fi
}

# Update system
echo "Updating system packages..."
apt-get update
apt-get upgrade -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" -y -q

# Install required packages
echo "Installing required packages..."
if in_container; then
    for pkg in git curl wget nano ffmpeg golang-go; do
        install_package "$pkg"
    done
else
    for pkg in docker.io docker-compose git ufw htop ffmpeg mailutils; do
        install_package "$pkg"
    done
fi

# Function to verify vultr-cli functionality
verify_vultr_cli() {
    echo "Verifying Vultr CLI installation..."
    
    # Check if binary exists and is executable
    if ! command -v vultr-cli &> /dev/null; then
        echo -e "${RED}Error: vultr-cli not found in PATH${NC}"
        return 1
    fi
    
    # Check version output
    if ! vultr-cli version &> /dev/null; then
        echo -e "${RED}Error: vultr-cli version check failed${NC}"
        return 1
    fi
    
    # Check basic command functionality
    if ! vultr-cli regions list &> /dev/null; then
        echo -e "${RED}Error: vultr-cli cannot connect to API${NC}"
        return 1
    fi
    
    echo -e "${GREEN}✓ Vultr CLI verified${NC}"
    return 0
}

# Install Vultr CLI
echo "Installing Vultr CLI..."

# Try official installer first
if ! curl -fsSL https://raw.githubusercontent.com/vultr/vultr-cli/master/scripts/installer.sh | bash; then
    echo -e "${YELLOW}Official installer failed, trying alternative method...${NC}"
    
    # Alternative installation method
    if command -v go &> /dev/null; then
        echo "Installing via Go..."
        go install github.com/vultr/vultr-cli@latest
        if [ -f ~/go/bin/vultr-cli ]; then
            mv ~/go/bin/vultr-cli /usr/local/bin/
        fi
    else
        echo "Installing Go..."
        apt-get install -y golang-go
        go install github.com/vultr/vultr-cli@latest
        if [ -f ~/go/bin/vultr-cli ]; then
            mv ~/go/bin/vultr-cli /usr/local/bin/
        fi
    fi
fi

# Verify installation
if ! verify_vultr_cli; then
    echo -e "${RED}Vultr CLI installation failed. Please install manually:${NC}"
    echo "1. curl -fsSL https://raw.githubusercontent.com/vultr/vultr-cli/master/scripts/installer.sh | bash"
    echo "2. vultr-cli --help"
    exit 1
fi

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
    # Pre-configure all postfix settings
    debconf-set-selections <<EOF
    # Kernel upgrade settings
    linux-base/no-reboot-on-upgrade boolean true
    linux-base/want-reboot-on-upgrade boolean false
    
    # Postfix settings
    postfix postfix/mailname string $(hostname)
    postfix postfix/main_mailer_type string 'Internet Site'
    postfix postfix/destinations string $(hostname), localhost.localdomain, localhost
    postfix postfix/retry_defer_notify string
    postfix postfix/kernel_version_warning boolean false
    postfix postfix/recipient_delim string +
    postfix postfix/mydomain_warning boolean
    postfix postfix/mynetworks string 127.0.0.0/8 [::ffff:127.0.0.0]/104 [::1]/128
    postfix postfix/relayhost string
    postfix postfix/chattr boolean false
    postfix postfix/procmail boolean false
    postfix postfix/root_address string
    postfix postfix/rfc1035_violation boolean false
EOF
    
    # Install postfix completely non-interactively
    DEBIAN_FRONTEND=noninteractive apt-get install -y -q postfix
    
    # Suppress kernel upgrade prompts
    echo "libc6 libraries/restart-without-asking boolean true" | debconf-set-selections
    echo "linux-base want-reboot-on-upgrade boolean false" | debconf-set-selections
fi

# Verify installations
if in_container; then
    # Only check required tools for container
    for cmd in git ffmpeg vultr-cli; do
        check_install $cmd
    done
else
    # Check all tools for host system
    for cmd in docker docker-compose git ufw htop ffmpeg vultr-cli; do
        check_install $cmd
    done
fi

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
if ! in_container; then
    # Install UFW if not present
    if ! command -v ufw >/dev/null 2>&1; then
        echo "Installing UFW..."
        if ! apt install -y ufw; then
            echo -e "${RED}Failed to install UFW. Firewall will not be configured.${NC}"
            return 1
        fi
        # Verify UFW installation
        if ! command -v ufw >/dev/null 2>&1; then
            echo -e "${RED}UFW installation verified but command not found. Skipping firewall setup.${NC}"
            return 1
        fi
        echo -e "${GREEN}UFW installed successfully${NC}"
    fi

    # Configure UFW only if installation was successful
    echo "Configuring UFW rules..."
    {
        ufw default deny incoming
        ufw default allow outgoing
        ufw allow ssh
        ufw allow 32400/tcp  # Plex main port
        ufw allow 32469/tcp  # Plex DLNA
        ufw allow 1900/udp   # Plex DLNA discovery
        ufw allow 32410:32414/udp  # Plex media streaming
        echo "y" | ufw enable
    } || {
        echo -e "${RED}Failed to configure UFW rules. Please check UFW status manually.${NC}"
        return 1
    }
    echo -e "${GREEN}Firewall configured successfully${NC}"
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
if ! in_container; then
    cd /opt
    git clone https://github.com/joereg4/plex-docker-setup.git
    cd plex-docker-setup
else
    echo "Running in container - skipping repository clone"
fi

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
        sed -i "s|TZ=.*|TZ=$timezone|" .env
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
    
    # Export API key for immediate use
    export VULTR_API_KEY="$vultr_api_key"
    
    # Configure Vultr CLI
    mkdir -p ~/.vultr-cli
    echo "api-key: ${vultr_api_key}" > ~/.vultr-cli/config.yaml
    
    # Get instance information
    echo "Fetching instance information..."
    
    # Function to validate ID format
    validate_id() {
        local id=$1
        local type=$2
        case $type in
            "instance")
                [[ $id =~ ^ins_[a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12}$ ]] && return 0
                ;;
            "block")
                [[ $id =~ ^bs_[a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12}$ ]] && return 0
                ;;
        esac
        return 1
    }
    
    # Function to get current instance ID
    get_current_instance() {
        local hostname=$(hostname)
        vultr-cli instance list | grep -i "$hostname" | awk '{print $1}'
    }
    
    echo -e "\n${GREEN}Available Instances:${NC}"
    vultr-cli instance list
    echo -e "\n${GREEN}Available Block Storage:${NC}"
    vultr-cli block-storage list
    
    echo -e "\n${YELLOW}Copy the IDs from above listings${NC}"
    
    if [ $? -eq 0 ]; then
        # Try to detect current instance
        detected_instance=$(get_current_instance)
        if [ -n "$detected_instance" ]; then
            echo -e "${GREEN}Detected current instance: $detected_instance${NC}"
            echo "Use this ID? (y/n)"
            read -r use_detected
            if [ "$use_detected" = "y" ]; then
                instance_id=$detected_instance
            fi
        fi
        
        echo "Enter the Block Storage ID (leave blank if not using block storage):"
        echo "Example format: bs_xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
        read -r block_id
        if [ -n "$block_id" ]; then
            if ! validate_id "$block_id" "block"; then
                echo -e "${RED}Invalid Block Storage ID format${NC}"
                echo "Please enter a valid ID (bs_xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx)"
                read -r block_id
            fi
            sed -i "s/VULTR_BLOCK_ID=.*/VULTR_BLOCK_ID=$block_id/" .env
        fi
        
        if [ -z "$instance_id" ]; then
            echo "Enter your Instance ID:"
            echo "Example format: ins_xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
            read -r instance_id
        fi
        
        if ! validate_id "$instance_id" "instance"; then
            echo -e "${RED}Invalid Instance ID format${NC}"
            echo "Please enter a valid ID (ins_xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx)"
            read -r instance_id
        fi
        
        sed -i "s/VULTR_INSTANCE_ID=.*/VULTR_INSTANCE_ID=$instance_id/" .env
        
        # Verify IDs
        echo -e "\n${GREEN}Verifying configuration...${NC}"
        # Verify instance exists
        if ! vultr-cli instance get "$instance_id" &>/dev/null; then
            echo -e "${RED}Warning: Could not verify Instance ID${NC}"
        fi
        # Verify block storage if provided
        if [ -n "$block_id" ]; then
            # Check if block storage exists
            if ! vultr-cli block-storage get "$block_id" &>/dev/null; then
                echo -e "${RED}Warning: Could not verify Block Storage ID${NC}"
            else
                # Check if block storage is attached to correct instance
                block_info=$(vultr-cli block-storage get "$block_id")
                attached_to=$(echo "$block_info" | grep "ATTACHED TO" | awk '{print $3}')
                
                if [ "$attached_to" = "$instance_id" ]; then
                    echo -e "${GREEN}✓ Block storage correctly attached to this instance${NC}"
                elif [ -n "$attached_to" ]; then
                    echo -e "${RED}Warning: Block storage is attached to different instance: $attached_to${NC}"
                    echo "Would you like to detach and reattach to this instance? (y/n)"
                    read -r reattach
                    if [ "$reattach" = "y" ]; then
                        echo "Detaching block storage..."
                        vultr-cli block-storage detach "$block_id"
                        sleep 5  # Wait for detachment
                        echo "Attaching block storage to current instance..."
                        vultr-cli block-storage attach "$block_id" "$instance_id"
                        echo -e "${GREEN}✓ Block storage reattached${NC}"
                    fi
                else
                    echo "Block storage is not attached. Attaching now..."
                    vultr-cli block-storage attach "$block_id" "$instance_id"
                    echo -e "${GREEN}✓ Block storage attached${NC}"
                fi
                
                # Verify mount point
                if [ -b "/dev/sdb" ]; then
                    echo -e "${GREEN}✓ Block device detected${NC}"
                else
                    echo -e "${YELLOW}! Block device not detected yet. May need to wait or reboot.${NC}"
                fi
            fi
        fi
        
        echo "Instance ID: $instance_id"
        echo "Block Storage ID: ${block_id:-None configured}"
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
    echo "Using Gmail for email notifications"
    echo "Enter your Gmail app password (create one at https://myaccount.google.com/apppasswords):"
    read -r email_pass
    sed -i "s/SMTP_PASS=.*/SMTP_PASS=$email_pass/" .env

    echo "Enter your notification email address:"
    read -r notify_email
    sed -i "s/NOTIFY_EMAIL=.*/NOTIFY_EMAIL=$notify_email/" .env
    
    echo "Enter the email address to send from:"
    read -r smtp_user
    sed -i "s/SMTP_USER=.*/SMTP_USER=$smtp_user/" .env

    # Gmail specific settings
    sed -i "s/SMTP_HOST=.*/SMTP_HOST=smtp.gmail.com/" .env
    sed -i "s/SMTP_PORT=.*/SMTP_PORT=587/" .env
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