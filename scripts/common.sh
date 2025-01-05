#!/bin/bash

# Colors for output
export RED='\033[0;31m'
export GREEN='\033[0;32m'
export YELLOW='\033[1;33m'
export NC='\033[0m'

# Function to setup .env file
setup_env_file() {
    # Verify we're in the correct directory
    if [ ! -f "docker-compose.yml" ]; then
        echo -e "${RED}Error: Must be run from plex-docker-setup directory${NC}"
        exit 1
    }
    
    # Create .env from example if it doesn't exist
    if [ ! -f ".env" ] && [ -f ".env.example" ]; then
        echo -e "${YELLOW}Creating .env from example...${NC}"
        cp .env.example .env
        # Set secure permissions for sensitive data
        chmod 600 .env
        echo -e "${GREEN}✓ Created .env file${NC}"
    fi
} 