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
    fi
    
    # Create .env from example if it doesn't exist
    if [ ! -f ".env" ] && [ -f ".env.example" ]; then
        echo -e "${YELLOW}Creating .env from example...${NC}"
        cp .env.example .env
        # Set secure permissions for sensitive data
        chmod 600 .env
        echo -e "${GREEN}✓ Created .env file${NC}"
    fi
} 

# Function to export all variables from .env file
export_env_vars() {
    if [ -f ".env" ]; then
        echo -e "${YELLOW}Exporting environment variables...${NC}"
        
        # Read each line from .env
        while IFS= read -r line || [ -n "$line" ]; do
            # Skip comments and empty lines
            if [[ $line =~ ^[^#].+=.+ ]]; then
                # Extract variable name and value
                var_name=$(echo "$line" | cut -d '=' -f 1)
                var_value=$(echo "$line" | cut -d '=' -f 2-)
                
                # Export the variable
                export "$var_name"="$var_value"
                echo -e "${GREEN}✓ Exported${NC} $var_name"
            fi
        done < ".env"
        
        echo -e "${GREEN}Environment variables exported successfully${NC}"
    else
        echo -e "${RED}Error: .env file not found${NC}"
        return 1
    fi
} 