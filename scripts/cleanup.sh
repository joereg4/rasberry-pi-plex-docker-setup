#!/bin/bash

# Source common functions
source "$(dirname "$0")/common.sh"

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

# Send notification if email is configured
if [ -f ".env" ] && grep -q "SMTP_USER" .env && grep -q "SMTP_PASS" .env; then
    notify_email=$(grep "NOTIFY_EMAIL" .env | cut -d '=' -f2)
    if [ ! -z "$notify_email" ]; then
        echo "Cleanup completed at $(date)" | mail -s "Plex Cleanup Complete" "$notify_email"
    fi
fi 