#!/bin/bash

# Source common functions
source "$(dirname "$0")/../common/common.sh"

echo -e "${YELLOW}Recovering from storage operation...${NC}"

# Check device
if [ ! -b "/dev/vdb" ]; then
    echo -e "${RED}Block device not found. Check Vultr dashboard${NC}"
    exit 1
fi

# Online resize (no need to unmount)
resize2fs /dev/vdb

# Verify new size
df -h /mnt/blockstore

# Start Plex
cd "$(dirname "$0")/../../"  # Change to plex-docker-setup directory
docker-compose up -d

echo -e "${GREEN}Recovery complete!${NC}" 