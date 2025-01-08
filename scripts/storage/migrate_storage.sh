#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Function to check available space
check_space() {
    local source=$1
    local target=$2
    local source_space=$(df -B1 $source | awk 'NR==2 {print $4}')
    local target_space=$(df -B1 $target | awk 'NR==2 {print $4}')
    local used_space=$(du -sb $source | awk '{print $1}')

    if [ $used_space -gt $target_space ]; then
        echo -e "${RED}Error: Not enough space in target location${NC}"
        echo "Required: $(numfmt --to=iec-i --suffix=B $used_space)"
        echo "Available: $(numfmt --to=iec-i --suffix=B $target_space)"
        exit 1
    fi
}

# Function to migrate data
migrate_data() {
    local source=$1
    local target=$2
    
    echo -e "${YELLOW}Starting migration from $source to $target${NC}"
    
    # Create target directory structure
    echo -e "${YELLOW}Creating directory structure...${NC}"
    mkdir -p "$target"
    
    # Stop Plex
    docker-compose down
    
    # Sync data with progress
    rsync -ah --progress --info=progress2 $source/ $target/
    
    # Verify data
    if diff -r $source $target >/dev/null; then
        echo -e "${GREEN}Migration successful!${NC}"
    else
        echo -e "${RED}Warning: Migration verification failed${NC}"
        exit 1
    fi
}

# Main migration logic
if [ "$1" = "to-block" ]; then
    if [ ! -b "/dev/vdb" ]; then
        echo -e "${RED}Error: Block storage not found${NC}"
        exit 1
    fi
    
    check_space "/opt/plex/media" "/mnt/blockstore"
    migrate_data "/opt/plex/media" "/mnt/blockstore/plex/media"
    
    # Update docker-compose.yml
    echo -e "${YELLOW}Updating docker configuration...${NC}"
    cat > docker-compose.override.yml << EOF
services:
  plex:
    volumes:
      - /mnt/blockstore/plex/media:/media
EOF
    
    # Update symlink
    rm -f /opt/plex/media
    ln -s /mnt/blockstore/plex/media /opt/plex/media
    
    # Verify docker config
    echo -e "${YELLOW}Verifying configuration...${NC}"
    docker-compose config

elif [ "$1" = "to-local" ]; then
    check_space "/mnt/blockstore/plex/media" "/opt/plex/media.new"
    migrate_data "/mnt/blockstore/plex/media" "/opt/plex/media.new"
    
    # Remove override file to revert to default configuration
    rm -f docker-compose.override.yml
    
    # Update paths
    rm -f /opt/plex/media
    mv /opt/plex/media.new /opt/plex/media
    
    # Verify docker config
    echo -e "${YELLOW}Verifying configuration...${NC}"
    docker-compose config
else
    echo "Usage: $0 [to-block|to-local]"
    exit 1
fi

# Restart Plex
docker-compose up -d 