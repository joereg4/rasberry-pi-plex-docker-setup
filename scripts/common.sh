#!/bin/bash

# Colors for output
export RED='\033[0;31m'
export GREEN='\033[0;32m'
export YELLOW='\033[1;33m'
export NC='\033[0m'

# Function to ensure .env exists with correct permissions
setup_env_file() {
    # Create .env if it doesn't exist
    if [ ! -f .env ]; then
        echo -e "${YELLOW}Creating .env file...${NC}"
        touch .env
    fi
    
    # Fix permissions
    current_perms=$(stat -c %a .env)
    if [ "$current_perms" != "600" ]; then
        echo -e "${YELLOW}Fixing .env permissions...${NC}"
        chmod 600 .env
    fi
    
    # Verify
    if [ ! -w .env ]; then
        echo -e "${RED}Cannot write to .env file${NC}"
        exit 1
    fi
} 