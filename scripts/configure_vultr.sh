#!/bin/bash

# Colors for output
export RED='\033[0;31m'
export GREEN='\033[0;32m'
export YELLOW='\033[1;33m'
export NC='\033[0m'

# Function to install Go and Vultr CLI
install_vultr_cli() {
    echo -e "\n${YELLOW}Installing Go...${NC}"
    wget https://go.dev/dl/go1.20.14.linux-amd64.tar.gz
    tar -C /usr/local -xzf go1.20.14.linux-amd64.tar.gz
    rm go1.20.14.linux-amd64.tar.gz
    
    # Set Go environment
    export PATH=$PATH:/usr/local/go/bin
    export GOPATH=$HOME/go
    export PATH=$PATH:$GOPATH/bin
    export GO111MODULE=on
    
    # Setup Go workspace
    mkdir -p ~/go/{bin,pkg,src}
    
    echo -e "\n${YELLOW}Installing Vultr CLI...${NC}"
    go install github.com/vultr/vultr-cli/v3@v3.3.0
    
    # Verify installation
    if vultr-cli version; then
        echo -e "${GREEN}✓ Vultr CLI installed successfully${NC}"
    else
        echo -e "${RED}Failed to install Vultr CLI${NC}"
        exit 1
    fi
}

# Function to configure API
configure_api() {
    echo -e "\n${YELLOW}Configuring Vultr API...${NC}"
    
    # Check if API key exists in .env
    if [ -f .env ] && grep -q "VULTR_API_KEY" .env; then
        export VULTR_API_KEY=$(grep "VULTR_API_KEY" .env | cut -d '=' -f2)
    else
        echo "Please get your API key from https://my.vultr.com/settings/#settingsapi"
        echo "Enter your Vultr API key:"
        read -r api_key
        echo "VULTR_API_KEY=$api_key" >> .env
        export VULTR_API_KEY=$api_key
    fi
    
    # Test API connection
    if vultr-cli account info; then
        echo -e "${GREEN}✓ API connection successful${NC}"
    else
        echo -e "${RED}API connection failed${NC}"
        exit 1
    fi
}

# Main menu
while true; do
    echo -e "\n${YELLOW}Choose an option:${NC}"
    echo "1) Install Vultr CLI"
    echo "2) Configure Vultr API"
    echo "3) Configure Instance/Storage"
    echo "4) Do all steps"
    echo "5) Exit"
    read -r choice
    
    case $choice in
        1)
            install_vultr_cli
            ;;
        2)
            configure_api
            ;;
        3)
            echo "Configuring Instance/Storage..."
            ;;
        4)
            echo "Performing all steps..."
            install_vultr_cli
            configure_api
            ;;
        5)
            echo "Exiting..."
            exit 0
            ;;
        *)
            echo -e "${RED}Invalid option${NC}"
            ;;
    esac
done 