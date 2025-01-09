#!/bin/bash

# Source common functions
source "$(dirname "$0")/../common/common.sh"

echo "=== Monitoring Setup ==="

# Verify we're in the correct directory
if [ ! -f "docker-compose.yml" ]; then
    echo -e "${RED}Error: Must be run from plex-docker-setup directory${NC}"
    exit 1
fi

# Verify .env exists
if [ ! -f ".env" ]; then
    echo -e "${RED}Error: .env file not found. Run setup_plex.sh first${NC}"
    exit 1
fi

# Function to configure email
setup_email() {
    echo -e "\n${YELLOW}Setting up Email Notifications${NC}"
    
    # Install required packages
    apt-get update
    apt-get install -y mailutils postfix
    
    # Configure Postfix
    postconf -e "relayhost = [smtp.gmail.com]:587"
    postconf -e "smtp_sasl_auth_enable = yes"
    postconf -e "smtp_sasl_security_options = noanonymous"
    postconf -e "smtp_sasl_password_maps = hash:/etc/postfix/sasl_passwd"
    postconf -e "smtp_use_tls = yes"
    postconf -e "smtp_tls_security_level = encrypt"
    postconf -e "smtp_tls_CAfile = /etc/ssl/certs/ca-certificates.crt"
    
    # Get Gmail credentials
    echo "Enter your Gmail app password (create at https://myaccount.google.com/apppasswords):"
    read -r email_pass
    echo "Enter Gmail address:"
    read -r smtp_user
    echo "Enter notification email address:"
    read -r notify_email
    
    # Update .env
    sed -i "s/SMTP_USER=.*/SMTP_USER=$smtp_user/" .env
    sed -i "s/SMTP_PASS=.*/SMTP_PASS=\"$email_pass\"/" .env
    sed -i "s/NOTIFY_EMAIL=.*/NOTIFY_EMAIL=$notify_email/" .env
    
    # Export for immediate use
    export SMTP_USER=$smtp_user
    export SMTP_PASS="$email_pass"
    export NOTIFY_EMAIL=$notify_email
    
    # Configure Postfix
    echo "[smtp.gmail.com]:587 $smtp_user:$email_pass" > /etc/postfix/sasl_passwd
    chmod 600 /etc/postfix/sasl_passwd
    postmap /etc/postfix/sasl_passwd
    
    # Restart Postfix
    service postfix restart
    
    # Send test email
    echo "Test email from Plex server at $(date)" | mail -s "Plex Email Test" "$notify_email"
    echo -e "${GREEN}✓ Test email sent to $notify_email${NC}"
}

# Function to setup Vultr monitoring
setup_vultr() {
    echo -e "\n${YELLOW}Setting up Vultr monitoring...${NC}"
    
    # State file for tracking progress
    STATE_FILE="/tmp/vultr_setup_state"
    
    # Function to save state
    save_state() {
        echo "$1" > "$STATE_FILE"
    }
    
    # Function to get state
    get_state() {
        if [ -f "$STATE_FILE" ]; then
            cat "$STATE_FILE"
        else
            echo "init"
        fi
    }
    
    # Check if we're resuming from a previous attempt
    CURRENT_STATE=$(get_state)
    echo -e "${YELLOW}Resuming from state: $CURRENT_STATE${NC}"
    
    # Install Go if needed
    if [ "$CURRENT_STATE" = "init" ]; then
        if ! command -v go &> /dev/null; then
            wget https://go.dev/dl/go1.20.14.linux-amd64.tar.gz
            rm -rf /usr/local/go && tar -C /usr/local -xzf go1.20.14.linux-amd64.tar.gz
            export PATH=$PATH:/usr/local/go/bin
            rm go1.20.14.linux-amd64.tar.gz
            
            # Add Go to current shell's PATH
            eval "$(go env)"
            export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin
        fi
        save_state "go_installed"
    fi
    
    # Setup Go workspace
    if [ "$CURRENT_STATE" = "go_installed" ] || [ "$CURRENT_STATE" = "init" ]; then
        mkdir -p ~/go/{bin,pkg,src}
        export GOPATH=$HOME/go
        export PATH=$PATH:$GOPATH/bin
        export GO111MODULE=on
        
        # Ensure PATH includes Go bins
        export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin
        save_state "workspace_setup"
    fi
    
    # Install Vultr CLI
    if [ "$CURRENT_STATE" = "workspace_setup" ] || [ "$CURRENT_STATE" = "init" ]; then
        go install github.com/vultr/vultr-cli/v3@v3.3.0
        # Verify vultr-cli is in PATH
        if ! command -v vultr-cli &> /dev/null; then
            echo -e "${RED}Error: vultr-cli not found in PATH${NC}"
            echo -e "${YELLOW}Adding Go bins to PATH...${NC}"
            export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin
        fi
        save_state "vultr_cli_installed"
    fi
    
    # Get Vultr configuration
    echo "Enter your Vultr API key (from https://my.vultr.com/settings/#settingsapi):"
    read -r vultr_api_key
    
    # Update .env and export immediately
    sed -i "s/VULTR_API_KEY=.*/VULTR_API_KEY=$vultr_api_key/" .env
    export VULTR_API_KEY="$vultr_api_key"
    
    # Configure vultr-cli
    echo -e "\n${YELLOW}Configuring Vultr CLI...${NC}"
    echo "$vultr_api_key" | vultr-cli config
    echo -e "${GREEN}✓ Vultr CLI configured${NC}"
    
    # Test the API key
    echo -e "\n${YELLOW}Testing Vultr API connection...${NC}"
    ACCOUNT_INFO=$(curl -s -H "Authorization: Bearer ${VULTR_API_KEY}" \
        "https://api.vultr.com/v2/account")
    
    if echo "$ACCOUNT_INFO" | grep -q "email"; then
        echo -e "${GREEN}✓ Vultr API key configured${NC}"
        
        # Show instances with filtered output
        echo -e "\n${YELLOW}Available Instances:${NC}"
        INSTANCES=$(curl -s -H "Authorization: Bearer ${VULTR_API_KEY}" \
            "https://api.vultr.com/v2/instances")
        echo "$INSTANCES" | jq -r '.instances[] | "\(.label) \(.main_ip) \(.id)"' | \
            awk '{printf "%-22s %-22s %s\n", $1, $2, $3}'
        
        echo "Enter your Instance ID from above:"
        read -r instance_id
        sed -i "s/VULTR_INSTANCE_ID=.*/VULTR_INSTANCE_ID=$instance_id/" .env
        export VULTR_INSTANCE_ID="$instance_id"
        
        # Ask about block storage
        echo -e "\n${YELLOW}Do you want to configure block storage? (y/n)${NC}"
        read -r use_block
        
        if [[ $use_block =~ ^[Yy]$ ]]; then
            echo -e "\n${YELLOW}Available Block Storage:${NC}"
            vultr-cli block-storage list | awk '
                NR==1 {print "LABEL                   SIZE GB    ID"}
                NR>1 && NR<5 {printf "%-22s %-9s %s\n", $5, $4, $1}'
            echo "Enter your Block Storage ID from above:"
            read -r block_id
            sed -i "s/VULTR_BLOCK_ID=.*/VULTR_BLOCK_ID=$block_id/" .env
            export VULTR_BLOCK_ID="$block_id"

            # Add Go and vultr-cli to PATH
            echo 'export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin' >> ~/.bashrc
            export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin

            # Setup block storage
            echo -e "\n${YELLOW}Setting up block storage...${NC}"
            
            # Save block storage ID for recovery
            echo "$block_id" > "/tmp/vultr_block_id"
            
            # Check if block storage is already attached
            echo -e "${YELLOW}Checking current block storage status...${NC}"
            BLOCK_STATUS=$(curl -s -H "Authorization: Bearer ${VULTR_API_KEY}" \
                "https://api.vultr.com/v2/blocks/${block_id}")
            
            if echo "$BLOCK_STATUS" | jq -r '.block.status' | grep -q "active"; then
                echo -e "${GREEN}✓ Block storage already attached${NC}"
                save_state "storage_attached"
            else
                # Attach block storage using Vultr CLI
                echo -e "${YELLOW}Attaching block storage to instance...${NC}"
                ATTACH_RESPONSE=$(curl -s -X POST \
                    -H "Authorization: Bearer ${VULTR_API_KEY}" \
                    -H "Content-Type: application/json" \
                    -d "{\"instance_id\":\"${instance_id}\"}" \
                    "https://api.vultr.com/v2/blocks/${block_id}/attach")
                
                if ! echo "$ATTACH_RESPONSE" | jq -e '.error' > /dev/null; then
                    echo -e "${GREEN}✓ Attachment initiated${NC}"
                else
                    ERROR_MSG=$(echo "$ATTACH_RESPONSE" | jq -r '.error.message')
                    echo -e "${RED}Error attaching block storage: $ERROR_MSG${NC}"
                    exit 1
                fi
            fi
            
            # Wait for device to appear
            echo -e "${YELLOW}Waiting for block device...${NC}"
            for i in {1..30}; do
                if [ -b "/dev/vdb" ]; then
                    echo -e "${GREEN}✓ Block device detected${NC}"
                    break
                fi
                if [ $i -eq 30 ]; then
                    echo -e "${RED}Timeout waiting for block device${NC}"
                    echo -e "${YELLOW}Please check Vultr dashboard and run setup again if needed${NC}"
                    exit 1
                fi
                echo -n "."
                sleep 2
            done
            
            # Verify attachment status
            echo -e "${YELLOW}Verifying block storage attachment...${NC}"
            if ! vultr-cli block-storage get $block_id | grep -q "active"; then
                echo -e "${RED}Error: Block storage not properly attached${NC}"
                exit 1
            fi
            
            # Verify device exists and is accessible
            if [ ! -b "/dev/vdb" ]; then
                echo -e "${RED}Error: Block device /dev/vdb not found${NC}"
                exit 1
            fi
            
            # Show block device info
            echo -e "${YELLOW}Block device details:${NC}"
            lsblk /dev/vdb
            
            mkdir -p /mnt/blockstore
            
            # Check if device needs formatting
            if ! blkid /dev/vdb >/dev/null 2>&1; then
                echo -e "${YELLOW}Formatting block storage...${NC}"
                mkfs.ext4 /dev/vdb
            fi

            # Mount the device
            mount /dev/vdb /mnt/blockstore
            echo -e "${YELLOW}Verifying mount point...${NC}"
            if ! mountpoint -q /mnt/blockstore; then
                echo -e "${RED}Error: Failed to mount block storage${NC}"
                exit 1
            fi
            
            # Check mount permissions and space
            echo -e "${YELLOW}Checking mount details:${NC}"
            df -h /mnt/blockstore
            echo -e "${YELLOW}Mount permissions:${NC}"
            ls -ld /mnt/blockstore
            
            # Verify write access
            echo -e "${YELLOW}Testing write access...${NC}"
            if ! touch /mnt/blockstore/test_write 2>/dev/null; then
                echo -e "${RED}Error: Cannot write to mount point${NC}"
                exit 1
            fi
            rm -f /mnt/blockstore/test_write
            
            echo -e "${GREEN}✓ Block storage mounted${NC}"

            # Add to fstab for persistent mount
            if ! grep -q "/dev/vdb" /etc/fstab; then
                echo "/dev/vdb /mnt/blockstore ext4 defaults,nofail 0 0" >> /etc/fstab
                echo -e "${GREEN}✓ Added to fstab for persistent mount${NC}"
            fi

            # Migrate media to block storage
            echo -e "\n${YELLOW}Setting up media directories on block storage...${NC}"
            mkdir -p /mnt/blockstore/plex/media/{Movies,TV\ Shows,Music,Photos}
            
            # Set correct permissions
            chown -R 1000:1000 /mnt/blockstore/plex
            chmod -R 755 /mnt/blockstore/plex
            
            # Migrate existing data if any
            if [ -d "/opt/plex/media" ]; then
                echo -e "${YELLOW}Migrating existing media to block storage...${NC}"
                rsync -av --remove-source-files /opt/plex/media/* /mnt/blockstore/plex/media/
                
                # Remove old directory and create symlink
                rm -rf /opt/plex/media
                ln -sf /mnt/blockstore/plex/media /opt/plex/media
                
                echo -e "${GREEN}✓ Media migrated to block storage${NC}"
            fi
            
            # Verify symlinks
            echo -e "${YELLOW}Verifying storage setup:${NC}"
            readlink -f /opt/plex/media
            df -h /mnt/blockstore
        fi
    fi
}

# Function to setup monitoring cron jobs
setup_monitoring() {
    echo -e "\n${YELLOW}Setting up monitoring jobs${NC}"
    
    # Configure Git and script permissions
    echo -e "\n${YELLOW}Configuring Git and script permissions...${NC}"
    
    # Make all scripts executable
    find "$(dirname "$0")/.." -type f -name "*.sh" -exec chmod +x {} \;
    
    # Create post-merge hook if not exists
    if [ ! -f ".git/hooks/post-merge" ]; then
        mkdir -p .git/hooks
        cat > .git/hooks/post-merge << 'EOF'
#!/bin/bash

# Make all scripts executable after pull
find scripts/ -type f -name "*.sh" -exec chmod +x {} \;

# Set specific permissions for sensitive files
chmod 600 .env 2>/dev/null || true
chmod 600 .env.example

echo "Script permissions updated!"
EOF

        # Make hook executable
        chmod +x .git/hooks/post-merge
    fi
    
    # Create .gitattributes if it doesn't exist
    if [ ! -f ".gitattributes" ]; then
        echo -e "# Ignore permission changes on scripts\nscripts/**/*.sh -diff" > .gitattributes
        echo -e "${GREEN}✓ Created .gitattributes${NC}"
    fi
    
    # Set core.fileMode to false
    git config core.fileMode false
    
    # Install monitoring tools
    echo -e "${YELLOW}Installing monitoring packages...${NC}"
    apt-get update
    apt-get install -y sysstat parted hdparm
    
    # Verify installations
    if ! command -v iostat &> /dev/null; then
        echo -e "${RED}Warning: sysstat installation failed${NC}"
    fi
    
    # Get current crontab
    current_crontab=$(crontab -l 2>/dev/null)
    
    # Check if storage monitoring is already configured
    if ! echo "$current_crontab" | grep -q "manage_storage.sh auto"; then
        # Add storage management (every 5 minutes)
        (echo "$current_crontab"; echo "*/5 * * * * $(pwd)/scripts/storage/manage_storage.sh auto") | crontab -
        echo -e "${GREEN}✓ Storage management added${NC}"
    fi
    
    # Add storage monitoring with email alerts if not exists
    if ! echo "$current_crontab" | grep -q "monitor_storage.sh"; then
        # Add storage monitoring (hourly)
        (crontab -l 2>/dev/null; echo "0 * * * * $(pwd)/scripts/storage/monitor_storage.sh") | crontab -
        echo -e "${GREEN}✓ Storage monitoring added${NC}"
    fi
    
    echo -e "${GREEN}✓ Monitoring jobs configured${NC}"
    echo "Storage management: Every 5 minutes"
    echo "Storage monitoring: Hourly"
}

# Main setup
echo -e "\n${YELLOW}This will set up email notifications and Vultr storage monitoring${NC}"
setup_email
setup_vultr
setup_monitoring

# Verify configuration
echo -e "\n${GREEN}=== Configuration Complete ===${NC}"
echo -e "\n${YELLOW}Email Configuration:${NC}"
echo "SMTP_USER=$SMTP_USER"
echo "NOTIFY_EMAIL=$NOTIFY_EMAIL"
echo "SMTP_PASS=$SMTP_PASS"

echo -e "\n${YELLOW}Vultr Configuration:${NC}"
echo "VULTR_API_KEY=$VULTR_API_KEY"
echo "VULTR_INSTANCE_ID=$VULTR_INSTANCE_ID"
echo "VULTR_BLOCK_ID=$VULTR_BLOCK_ID"

echo -e "\n${YELLOW}Cron Jobs:${NC}"
crontab -l 