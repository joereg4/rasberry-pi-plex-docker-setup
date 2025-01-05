#!/bin/bash

# Source common functions using absolute path
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../common/common.sh"

echo "=== Plex Cleanup ==="

# Verify we're in the correct directory
if [ ! -f "docker-compose.yml" ]; then
    echo -e "${RED}Error: Must be run from plex-docker-setup directory${NC}"
    exit 1
fi

# Clean up Plex cache
echo -e "${YELLOW}Cleaning Plex cache...${NC}"
docker exec plex rm -rf "/config/Library/Application Support/Plex Media Server/Cache/PhotoTranscoder"
docker exec plex rm -rf "/config/Library/Application Support/Plex Media Server/Cache/Transcode"

# Remove unused Docker resources
echo -e "${YELLOW}Cleaning Docker resources...${NC}"
docker system prune -f

echo -e "${GREEN}✓ Cleanup complete${NC}" 