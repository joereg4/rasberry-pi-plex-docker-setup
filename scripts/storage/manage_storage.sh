#!/bin/bash

# Source .env if it exists
if [ -f ".env" ]; then
    set -a  # automatically export all variables
    source .env
    set +a
elif [ -f "../.env" ]; then
    set -a
    source "../.env"
    set +a
fi

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Configuration
ALERT_THRESHOLD=75      # Percentage - Warning email
CRITICAL_THRESHOLD=90   # Percentage - Auto expand
BLOCK_INCREMENT=50      # GB - Smaller increments
EXPANSION_LOCK="/tmp/storage_expansion.lock"  # Lock file for expansion
MAX_WAIT=300           # Maximum seconds to wait for operations


# Debug: Show current directory and .env location
echo "Current directory: $(pwd)"

# Verify required environment variables
if [ -z "$VULTR_API_KEY" ]; then
    echo -e "${RED}Error: VULTR_API_KEY not found in .env${NC}"
    exit 1
fi

if [ -z "$VULTR_BLOCK_ID" ]; then
    echo -e "${YELLOW}Warning: VULTR_BLOCK_ID not found in .env${NC}"
    echo -e "${YELLOW}Block storage monitoring will be disabled${NC}"
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

# Function to check if block storage exists and is mounted
check_block_storage() {
    if [ ! -b "/dev/vdb" ]; then
        echo -e "${RED}Error: Block storage device (/dev/vdb) not found${NC}"
        echo -e "${YELLOW}Possible issues:${NC}"
        echo "1. Block storage not attached in Vultr dashboard"
        echo "2. Block storage not properly configured"
        echo -e "Run ${GREEN}setup_monitoring.sh${NC} to configure block storage"
        return 1
    fi

    if ! mountpoint -q "/mnt/blockstore"; then
        echo -e "${RED}Error: Block storage not mounted at /mnt/blockstore${NC}"
        echo -e "${YELLOW}To fix:${NC}"
        echo "1. Create mount point: mkdir -p /mnt/blockstore"
        echo "2. Mount device: mount /dev/vdb /mnt/blockstore"
        echo "3. Add to fstab for persistence"
        echo -e "Or run ${GREEN}setup_monitoring.sh${NC} to configure automatically"
        return 1
    fi

    return 0
}

# Function to expand block storage using Vultr API
expand_storage() {
    # Check if expansion is already in progress
    if [ -f "$EXPANSION_LOCK" ]; then
        echo -e "${YELLOW}Storage expansion already in progress${NC}"
        exit 0
    fi

    # Create lock file
    touch "$EXPANSION_LOCK"

    local current_size=$(get_block_size)
    local new_size=$((current_size + BLOCK_INCREMENT))
    
    echo -e "\n${YELLOW}=== Starting Block Storage Expansion ===${NC}" >> /var/log/plex-storage.log
    
    # 1. Stop Plex and unmount storage
    docker-compose down >> /var/log/plex-storage.log 2>&1
    umount /dev/vdb >> /var/log/plex-storage.log 2>&1
    
    # 2. Detach and wait for completion
    DETACH_RESPONSE=$(curl -s -X POST \
        -H "Authorization: Bearer ${VULTR_API_KEY}" \
        "https://api.vultr.com/v2/blocks/${VULTR_BLOCK_ID}/detach")
    
    # Wait for detachment to complete
    for i in $(seq 1 $MAX_WAIT); do
        BLOCK_STATUS=$(curl -s -H "Authorization: Bearer ${VULTR_API_KEY}" \
            "https://api.vultr.com/v2/blocks/${VULTR_BLOCK_ID}")
        if echo "$BLOCK_STATUS" | jq -r '.block.status' | grep -q "detached"; then
            break
        fi
        sleep 1
    done
    
    # 3. Resize block storage
    echo -e "${YELLOW}Resizing block storage...${NC}"
    RESIZE_RESPONSE=$(curl -s -X PATCH \
        -H "Authorization: Bearer ${VULTR_API_KEY}" \
        -H "Content-Type: application/json" \
        -d "{\"size_gb\": ${new_size}}" \
        "https://api.vultr.com/v2/blocks/${VULTR_BLOCK_ID}")
    
    if ! echo "$RESIZE_RESPONSE" | jq -e '.error' > /dev/null; then
        echo -e "${GREEN}✓ Resize initiated${NC}"
    else
        ERROR_MSG=$(echo "$RESIZE_RESPONSE" | jq -r '.error.message')
        echo -e "${RED}Error resizing block storage: $ERROR_MSG${NC}"
        exit 1
    fi
    
    # 4. Reattach block storage
    echo -e "${YELLOW}Reattaching block storage...${NC}"
    ATTACH_RESPONSE=$(curl -s -X POST \
        -H "Authorization: Bearer ${VULTR_API_KEY}" \
        -H "Content-Type: application/json" \
        -d "{\"instance_id\":\"${VULTR_INSTANCE_ID}\"}" \
        "https://api.vultr.com/v2/blocks/${VULTR_BLOCK_ID}/attach")
    
    if ! echo "$ATTACH_RESPONSE" | jq -e '.error' > /dev/null; then
        echo -e "${GREEN}✓ Attachment initiated${NC}"
    else
        ERROR_MSG=$(echo "$ATTACH_RESPONSE" | jq -r '.error.message')
        echo -e "${RED}Error attaching block storage: $ERROR_MSG${NC}"
        exit 1
    fi
    
    sleep 20
    
    # 5. Expand filesystem
    echo -e "${YELLOW}Verifying block device...${NC}"
    lsblk
    
    echo -e "${YELLOW}Expanding filesystem...${NC}"
    e2fsck -f /dev/vdb
    resize2fs -f /dev/vdb
    
    # 6. Remount and verify
    echo -e "${YELLOW}Remounting block storage...${NC}"
    mount /dev/vdb /mnt/blockstore
    
    echo -e "${YELLOW}Verifying new size:${NC}"
    df -h /mnt/blockstore
    
    # 7. Restart Docker and Plex
    echo -e "${YELLOW}Restarting Docker containers...${NC}"
    docker-compose up -d
    
    echo -e "\n${GREEN}=== Block Storage Expansion Complete ===${NC}"
    
    # Cleanup
    rm -f "$EXPANSION_LOCK"
    
    # Notify of completion
    echo "Block storage expansion completed. New size: ${new_size}GB" | \
        mail -s "Storage Expansion Complete - Plex Server" "$NOTIFY_EMAIL"
}

# Function to resume expansion after disconnect
resume_expansion() {
    if [ ! -f "/tmp/storage_expansion_state" ]; then
        echo -e "${RED}No expansion state found${NC}"
        exit 1
    fi
    
    # Load saved state
    source /tmp/storage_expansion_state
    
    echo -e "${YELLOW}Resuming expansion to ${size}GB...${NC}"
    
    # Continue with resize
    RESIZE_RESPONSE=$(curl -s -X PATCH \
        -H "Authorization: Bearer ${VULTR_API_KEY}" \
        -H "Content-Type: application/json" \
        -d "{\"size_gb\": ${size}}" \
        "https://api.vultr.com/v2/blocks/${VULTR_BLOCK_ID}")
    
    # ... rest of expansion process ...
}

# Main logic
case "$1" in
    "resume")
        resume_expansion
        ;;
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
            
            if [ $usage -gt $CRITICAL_THRESHOLD ]; then
                echo -e "${RED}Usage critical (${usage}%), expanding storage...${NC}"
                expand_storage
                # Send email notification about expansion
                echo "Block storage was automatically expanded due to reaching ${usage}% usage." | mail -s "Storage Expanded - Plex Server" "$NOTIFY_EMAIL"
            elif [ $usage -gt $ALERT_THRESHOLD ]; then
                echo -e "${YELLOW}WARNING: Usage at ${usage}%${NC}"
                # Send warning email
                echo "Block storage usage is at ${usage}%. It will be automatically expanded if it exceeds ${CRITICAL_THRESHOLD}%." | mail -s "Storage Warning - Plex Server" "$NOTIFY_EMAIL"
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