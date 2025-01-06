#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Configuration
ALERT_THRESHOLD=75  # Percentage
CRITICAL_THRESHOLD=90
BLOCK_INCREMENT=100  # GB

# Vultr API configuration
# Debug: Show current directory and .env location
echo "Current directory: $(pwd)"
echo "Looking for .env in: $(pwd)/.env"

# Load environment variables
if [ -f ".env" ]; then
    set -a
    . ".env"
    set +a
elif [ -f "../.env" ]; then
    set -a
    . "../.env"
    set +a
else
    echo -e "${RED}Error: .env file not found${NC}"
    exit 1
fi

if [ -z "$VULTR_API_KEY" ] || [ -z "$VULTR_BLOCK_ID" ]; then
    echo -e "${RED}Vultr API configuration missing in .env${NC}"
    exit 1
fi

# Function to get current usage percentage
get_usage() {
    local mount=$1
    df -h $mount | awk 'NR==2 {sub(/%/,"",$5); print $5}'
}

# Function to get block device size
get_block_size() {
    lsblk -b /dev/vdb | awk 'NR==2 {print $4/1024/1024/1024}'  # Convert to GB
}

# Function to check if block storage exists
check_block_storage() {
    if [ ! -b "/dev/vdb" ]; then
        echo -e "${RED}No block storage device found${NC}"
        return 1
    fi
    return 0
}

# Function to expand block storage using Vultr API
expand_storage() {
    local current_size=$(get_block_size)
    local new_size=$((current_size + BLOCK_INCREMENT))
    
    echo -e "${YELLOW}Expanding block storage from ${current_size}GB to ${new_size}GB${NC}"
    
    # Call Vultr API
    curl -s -H "Authorization: Bearer ${VULTR_API_KEY}" \
         -H "Content-Type: application/json" \
         -X PATCH \
         -d "{\"size_gb\": ${new_size}}" \
         "https://api.vultr.com/v2/blocks/${VULTR_BLOCK_ID}"
    
    if [ $? -eq 0 ]; then
        echo "Waiting for resize to complete..."
        sleep 30  # Give Vultr time to process
        
        # Grow the filesystem
        echo "Growing filesystem..."
        resize2fs /dev/sdb
        
        echo -e "${GREEN}Storage expansion complete${NC}"
    else
        echo -e "${RED}Failed to expand storage via Vultr API${NC}"
        exit 1
    fi
}

# Main logic
case "$1" in
    "check")
        if check_block_storage; then
            usage=$(get_usage "/mnt/blockstore")
            echo -e "Current block storage usage: ${YELLOW}${usage}%${NC}"
            
            if [ $usage -gt $CRITICAL_THRESHOLD ]; then
                echo -e "${RED}CRITICAL: Storage usage above ${CRITICAL_THRESHOLD}%${NC}"
            elif [ $usage -gt $ALERT_THRESHOLD ]; then
                echo -e "${YELLOW}WARNING: Storage usage above ${ALERT_THRESHOLD}%${NC}"
            fi
        fi
        ;;
        
    "expand")
        if check_block_storage; then
            expand_storage
        fi
        ;;
        
    "auto")
        if check_block_storage; then
            usage=$(get_usage "/mnt/blockstore")
            if [ $usage -gt $ALERT_THRESHOLD ]; then
                echo -e "${YELLOW}Usage above threshold, expanding storage...${NC}"
                expand_storage
            else
                echo -e "${GREEN}Storage usage normal (${usage}%)${NC}"
            fi
        fi
        ;;
        
    *)
        echo "Usage: $0 {check|expand|auto}"
        echo "  check  - Check current storage usage"
        echo "  expand - Manually expand block storage"
        echo "  auto   - Automatically expand if above threshold"
        ;;
esac 