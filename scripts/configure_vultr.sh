#!/bin/bash

# Source common functions
source "$(dirname "$0")/common.sh"

echo "=== Vultr Configuration ==="

# Ensure .env is ready
setup_env_file

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
    
    # Ensure .env exists
    if [ ! -f .env ]; then
        echo -e "${RED}Error: .env file not found${NC}"
        echo -e "${YELLOW}Creating .env file...${NC}"
        touch .env
    fi
    
    # Ask for API key
    echo "Please get your API key from https://my.vultr.com/settings/#settingsapi"
    echo "Enter your Vultr API key:"
    read -r api_key
    
    # Use grep to safely check and remove existing key
    if grep -q "^VULTR_API_KEY=" .env; then
        sed -i '/^VULTR_API_KEY=/d' .env
    fi
    
    # Add new key with proper format
    echo "VULTR_API_KEY=$api_key" >> .env
    export VULTR_API_KEY=$api_key
    
    # Verify key was added
    if ! grep -q "^VULTR_API_KEY=" .env; then
        echo -e "${RED}Failed to update .env file${NC}"
        exit 1
    fi
    
    # Test API connection
    if vultr-cli account info; then
        echo -e "${GREEN}✓ API connection successful${NC}"
    else
        echo -e "${RED}✗ API connection failed${NC}"
        exit 1
    fi
}

# Function to validate UUID format
validate_uuid() {
    local uuid=$1
    if [[ ! $uuid =~ ^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$ ]]; then
        return 1
    fi
    return 0
}

# Function to check if Vultr CLI is installed
check_vultr_cli() {
    if ! command -v vultr-cli &> /dev/null; then
        echo -e "${RED}Vultr CLI not found. Installing first...${NC}"
        install_vultr_cli
        return 1
    fi
    return 0
}

# Function to show clean instance list
show_instances() {
    echo -e "\n${YELLOW}Available Instances:${NC}"
    echo -e "LABEL\t\t\tID"
    echo "----------------------------------------"
    vultr-cli instance list | awk '{print $3 "\t\t" $1}' | grep -v "LABEL"
}

# Function to show clean storage list
show_storage() {
    echo -e "\n${YELLOW}Available Block Storage:${NC}"
    echo -e "LABEL\t\t\tID"
    echo "----------------------------------------"
    vultr-cli block-storage list | awk '{print $5 "\t\t" $1}' | grep -v "LABEL"
}

# Function to configure instance and storage
configure_instance_storage() {
    echo -e "\n${YELLOW}Configuring Instance and Storage IDs...${NC}"
    
    # Check for Vultr CLI
    check_vultr_cli
    
    # Check for API key in environment
    if [ -z "$VULTR_API_KEY" ] && [ -f .env ]; then
        # Extract and clean the API key
        api_key=$(grep "^VULTR_API_KEY=" .env | cut -d '=' -f2 | tr -d ' #' | tr -d '"')
        if [ ! -z "$api_key" ]; then
            export VULTR_API_KEY="$api_key"
            echo -e "${GREEN}✓ API key loaded from .env${NC}"
        fi
    fi
    
    if [ -z "$VULTR_API_KEY" ]; then
        echo -e "${RED}API key not found. Configuring API first...${NC}"
        configure_api
    fi
    
    # Show clean instance list
    show_instances
    
    # Get and validate Instance ID
    while true; do
        echo -e "\nEnter your Instance ID from above:"
        read -r instance_id
        
        if ! validate_uuid "$instance_id"; then
            echo -e "${RED}Invalid UUID format. Please try again.${NC}"
            continue
        fi
        
        # Verify instance exists
        if vultr-cli instance get "$instance_id" &>/dev/null; then
            break
        else
            echo -e "${RED}Instance ID not found. Please verify and try again.${NC}"
        fi
    done
    
    # Update Instance ID in .env
    if grep -q "^VULTR_INSTANCE_ID=" .env; then
        sed -i '/^VULTR_INSTANCE_ID=/d' .env
    fi
    echo "VULTR_INSTANCE_ID=$instance_id" >> .env
    
    # Show clean storage list
    show_storage
    
    # Get and validate Block Storage ID
    while true; do
        echo -e "\nEnter your Block Storage ID from above:"
        read -r block_id
        
        if ! validate_uuid "$block_id"; then
            echo -e "${RED}Invalid UUID format. Please try again.${NC}"
            continue
        fi
        
        # Verify block storage exists
        if vultr-cli block-storage get "$block_id" &>/dev/null; then
            break
        else
            echo -e "${RED}Block Storage ID not found. Please verify and try again.${NC}"
        fi
    done
    
    # Update Block Storage ID in .env
    if grep -q "^VULTR_BLOCK_ID=" .env; then
        sed -i '/^VULTR_BLOCK_ID=/d' .env
    fi
    echo "VULTR_BLOCK_ID=$block_id" >> .env
    
    # Verify IDs were added and show details
    if grep -q "^VULTR_INSTANCE_ID=" .env && grep -q "^VULTR_BLOCK_ID=" .env; then
        echo -e "\n${GREEN}✓ Configuration successful${NC}"
        echo -e "\n${YELLOW}Instance Details:${NC}"
        vultr-cli instance get "$instance_id"
        echo -e "\n${YELLOW}Block Storage Details:${NC}"
        vultr-cli block-storage get "$block_id"
    else
        echo -e "${RED}Failed to update IDs${NC}"
        exit 1
    fi
}

# Function to load and export Vultr variables from .env
load_vultr_env() {
    if [ -f .env ]; then
        # Load and export API key
        api_key=$(grep "^VULTR_API_KEY=" .env | cut -d '=' -f2 | tr -d ' #' | tr -d '"')
        if [ ! -z "$api_key" ]; then
            export VULTR_API_KEY="$api_key"
            echo -e "${GREEN}✓ API key loaded${NC}"
        fi
        
        # Load and export Instance ID
        instance_id=$(grep "^VULTR_INSTANCE_ID=" .env | cut -d '=' -f2 | tr -d ' #' | tr -d '"')
        if [ ! -z "$instance_id" ]; then
            export VULTR_INSTANCE_ID="$instance_id"
            echo -e "${GREEN}✓ Instance ID loaded${NC}"
        fi
        
        # Load and export Block ID
        block_id=$(grep "^VULTR_BLOCK_ID=" .env | cut -d '=' -f2 | tr -d ' #' | tr -d '"')
        if [ ! -z "$block_id" ]; then
            export VULTR_BLOCK_ID="$block_id"
            echo -e "${GREEN}✓ Block ID loaded${NC}"
        fi
    fi
}

# Main menu
while true; do
    # Load environment variables
    load_vultr_env
    
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
            configure_instance_storage
            ;;
        4)
            echo "Performing all steps..."
            install_vultr_cli
            configure_api
            # Add a pause to show progress
            echo -e "\n${YELLOW}Vultr CLI installed and API configured.${NC}"
            echo -e "${YELLOW}Proceeding to Instance and Storage configuration...${NC}"
            echo -e "Press Enter to continue"
            read
            configure_instance_storage
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