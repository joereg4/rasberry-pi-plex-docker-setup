#!/bin/bash

# Colors for output
export RED='\033[0;31m'
export GREEN='\033[0;32m'
export YELLOW='\033[1;33m'
export NC='\033[0m'

# Function to install Vultr CLI
install_vultr_cli() {
    echo "Installing Vultr CLI..."
    
    # Install Go 1.20+
    echo "Installing Go..."
    wget https://go.dev/dl/go1.20.14.linux-amd64.tar.gz
    rm -rf /usr/local/go && tar -C /usr/local -xzf go1.20.14.linux-amd64.tar.gz
    export PATH=$PATH:/usr/local/go/bin
    rm go1.20.14.linux-amd64.tar.gz
    
    # Setup Go workspace
    mkdir -p ~/go/{bin,pkg,src}
    export GOPATH=$HOME/go
    export PATH=$PATH:$GOPATH/bin
    export GO111MODULE=on
    
    # Install Vultr CLI
    echo "Installing Vultr CLI..."
    go install github.com/vultr/vultr-cli/v3@v3.3.0
    
    # Verify installation
    if ! command -v vultr-cli &> /dev/null; then
        echo -e "${RED}Vultr CLI installation failed${NC}"
        return 1
    fi
    
    # Test CLI works
    if ! vultr-cli version; then
        echo -e "${RED}Vultr CLI verification failed${NC}"
        return 1
    fi
    
    echo -e "${GREEN}✓ Vultr CLI installed successfully${NC}"
    return 0
}

# Function to configure Vultr API
configure_vultr_api() {
    echo "Enter your Vultr API key (from https://my.vultr.com/settings/#settingsapi):"
    read -r api_key
    
    # Update .env
    sed -i "s/VULTR_API_KEY=.*/VULTR_API_KEY=$api_key/" .env
    
    # Configure CLI
    mkdir -p ~/.vultr-cli
    echo "api-key: ${api_key}" > ~/.vultr-cli/config.yaml
    
    # Test configuration
    if ! vultr-cli account info &>/dev/null; then
        echo -e "${RED}API key verification failed${NC}"
        return 1
    fi
    
    echo -e "${GREEN}✓ API key configured successfully${NC}"
    return 0
}

# Function to configure instance and storage
configure_instance_storage() {
    echo -e "\n${GREEN}Available Instances:${NC}"
    vultr-cli instance list
    
    echo -e "\n${GREEN}Available Block Storage:${NC}"
    vultr-cli block-storage list
    
    echo -e "\n${YELLOW}Enter Instance ID (or press Enter to skip):${NC}"
    read -r instance_id
    if [ -n "$instance_id" ]; then
        sed -i "s/VULTR_INSTANCE_ID=.*/VULTR_INSTANCE_ID=$instance_id/" .env
    fi
    
    echo -e "\n${YELLOW}Enter Block Storage ID (or press Enter to skip):${NC}"
    read -r block_id
    if [ -n "$block_id" ]; then
        sed -i "s/VULTR_BLOCK_ID=.*/VULTR_BLOCK_ID=$block_id/" .env
    fi
}

# Main menu
echo "=== Vultr Configuration ==="
echo "1. Install Vultr CLI"
echo "2. Configure Vultr API"
echo "3. Configure Instance/Storage"
echo "4. Do all steps"
echo "5. Exit"
echo "Choose an option (1-5):"
read -r choice

case $choice in
    1) install_vultr_cli ;;
    2) configure_vultr_api ;;
    3) configure_instance_storage ;;
    4)
        install_vultr_cli && \
        configure_vultr_api && \
        configure_instance_storage
        ;;
    5) exit 0 ;;
    *) echo "Invalid option" ;;
esac 