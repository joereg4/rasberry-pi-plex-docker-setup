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

# Function to get current usage percentage
get_usage() {
    local mount=$1
    df -h $mount | awk 'NR==2 {sub(/%/,"",$5); print $5}'
}

# Function to get block device size
get_block_size() {
    lsblk -b /dev/sdb | awk 'NR==2 {print $4/1024/1024/1024}'  # Convert to GB
}

# Function to check if block storage exists
check_block_storage() {
    if [ ! -b "/dev/sdb" ]; then
        echo -e "${RED}No block storage device found${NC}"
        return 1
    fi
    return 0
}

# Function to expand block storage
expand_storage() {
    local current_size=$(get_block_size)
    local new_size=$((current_size + BLOCK_INCREMENT))
    
    echo -e "${YELLOW}Expanding block storage from ${current_size}GB to ${new_size}GB${NC}"
    
    # Here you would integrate with your cloud provider's API
    # Example for Vultr (requires vultr-cli):
    # vultr-cli block-storage resize $BLOCK_ID $new_size
    
    # After expansion, grow the filesystem
    echo "Growing filesystem..."
    resize2fs /dev/sdb
    
    echo -e "${GREEN}Storage expansion complete${NC}"
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