#!/bin/bash

# Exit on any error
set -e

# Colors and formatting
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'
BOLD='\033[1m'

# Progress indicator function
progress() {
    local duration=$1
    local message=$2
    local elapsed=0
    echo -n -e "${message} ["
    while [ $elapsed -lt $duration ]; do
        echo -n "▓"
        sleep 1
        elapsed=$((elapsed + 1))
        # Print dots every 5 seconds
        [ $((elapsed % 5)) -eq 0 ] && echo -n "."
    done
    echo -e "] ${GREEN}Done${NC}"
}

# Parse arguments
DRY_RUN=0
while [[ "$#" -gt 0 ]]; do
    case $1 in
        --dry-run) DRY_RUN=1 ;;
        *) echo "Unknown parameter: $1"; exit 1 ;;
    esac
    shift
done

# Source .env
set -a
source .env
set +a

# Verify required variables
if [ -z "$VULTR_API_KEY" ] || [ -z "$VULTR_BLOCK_ID" ] || [ -z "$VULTR_INSTANCE_ID" ]; then
    echo "Error: Missing required environment variables"
    echo "Please ensure VULTR_API_KEY, VULTR_BLOCK_ID, and VULTR_INSTANCE_ID are set"
    exit 1
fi

# Check if running as root
if [ "$(id -u)" != "0" ]; then
    echo "Error: This script must be run as root"
    exit 1
fi

# Check if block device exists
if [ ! -b "/dev/vdb" ]; then
    echo "Error: Block device /dev/vdb not found"
    exit 1
fi

# Check if mounted
if ! mountpoint -q /mnt/blockstore; then
    echo "Error: /mnt/blockstore is not mounted"
    exit 1
fi

# Function to cleanup on error
cleanup() {
    echo "Error occurred, restoring fstab..."
    if [ -f /etc/fstab.bak ]; then
        mv /etc/fstab.bak /etc/fstab
    fi
    exit 1
}

# Set error handler
trap cleanup ERR

echo -e "${BOLD}=== Block Storage Expansion Test ===${NC}"
[ $DRY_RUN -eq 1 ] && echo -e "${YELLOW}DRY RUN MODE - No changes will be made${NC}\n"

# 1. Check current size
echo -e "${BOLD}1. Current Storage Status${NC}"
df -h /mnt/blockstore

# Remove from fstab temporarily
echo -e "\n${BOLD}2. Backup and Modify fstab${NC}"
if [ $DRY_RUN -eq 1 ]; then
    echo "Would modify: /etc/fstab"
else
cp /etc/fstab /etc/fstab.bak
sed -i '/\/dev\/vdb/d' /etc/fstab
fi

# Verify API connectivity before proceeding
echo -e "\nVerifying Vultr API access..."
if ! curl -s -H "Authorization: Bearer ${VULTR_API_KEY}" \
    "https://api.vultr.com/v2/account" | grep -q "email"; then
    echo "Error: Cannot connect to Vultr API"
    cleanup
fi

# 2. Detach block storage
echo -e "\n${BOLD}3. Detach Block Storage${NC}"
if [ $DRY_RUN -eq 1 ]; then
    echo "Would detach block storage: ${VULTR_BLOCK_ID}"
else
    curl -s -X POST \
        -H "Authorization: Bearer ${VULTR_API_KEY}" \
        "https://api.vultr.com/v2/blocks/${VULTR_BLOCK_ID}/detach"
    
    [ $DRY_RUN -eq 0 ] && progress 30 "Waiting for detachment"
    
    # Only verify if not in dry-run
    echo -e "\nVerifying detachment..."
    BLOCK_STATUS=$(curl -s -H "Authorization: Bearer ${VULTR_API_KEY}" \
        "https://api.vultr.com/v2/blocks/${VULTR_BLOCK_ID}")
    if ! echo "$BLOCK_STATUS" | jq -r '.block.status' | grep -q "detached"; then
        echo "Error: Block storage did not detach properly"
        cleanup
    fi
fi

# 3. Resize to 150GB
echo -e "\nResizing to 150GB..."
if [ $DRY_RUN -eq 1 ]; then
    echo "Would resize block storage to 150GB"
else
    curl -s -X PATCH \
        -H "Authorization: Bearer ${VULTR_API_KEY}" \
        -H "Content-Type: application/json" \
        -d '{"size_gb": 150}' \
        "https://api.vultr.com/v2/blocks/${VULTR_BLOCK_ID}"
    
    [ $DRY_RUN -eq 0 ] && progress 30 "Waiting for resize"
fi

# 4. Reattach
echo -e "\nReattaching block storage..."
if [ $DRY_RUN -eq 1 ]; then
    echo "Would reattach block storage to instance: ${VULTR_INSTANCE_ID}"
else
    curl -s -X POST \
        -H "Authorization: Bearer ${VULTR_API_KEY}" \
        -H "Content-Type: application/json" \
        -d "{\"instance_id\":\"${VULTR_INSTANCE_ID}\"}" \
        "https://api.vultr.com/v2/blocks/${VULTR_BLOCK_ID}/attach"
    
    [ $DRY_RUN -eq 0 ] && progress 30 "Waiting for reattachment"
fi

# 5. Resize filesystem
echo -e "\nResizing filesystem..."
if [ $DRY_RUN -eq 1 ]; then
    echo "Would resize filesystem on /dev/vdb"
else
    resize2fs /dev/vdb
fi

# 6. Verify
echo -e "\nNew size:"
if [ $DRY_RUN -eq 1 ]; then
    echo "Would show new size after resize"
else
    df -h /mnt/blockstore
fi

# Restore fstab
echo -e "\nRestoring fstab..."
if [ $DRY_RUN -eq 1 ]; then
    echo "Would restore fstab from backup"
else
    mv /etc/fstab.bak /etc/fstab
fi

# Show summary in dry-run mode
if [ $DRY_RUN -eq 1 ]; then
    echo -e "\n${BOLD}Operations that would be performed:${NC}"
    echo "1. Backup and remove mount from fstab"
    echo "2. Detach block storage"
    echo "3. Resize to 150GB"
    echo "4. Reattach block storage"
    echo "5. Resize filesystem"
    echo "6. Restore fstab"
    echo -e "\n${YELLOW}No changes were made - this was a dry run${NC}"
else
    echo -e "\n${GREEN}Storage expansion completed successfully${NC}"
fi