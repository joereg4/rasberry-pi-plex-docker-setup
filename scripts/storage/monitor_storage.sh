#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "=== Plex Storage Monitor ==="

# Function to check storage
check_storage() {
    local mount=$1
    local name=$2
    
    if [ -e "$mount" ]; then
        echo -e "\n${GREEN}$name Storage:${NC}"
        df -h $mount | awk 'NR==2 {
            used=$3
            avail=$4
            total=$2
            percent=$5
            printf "Usage: %s of %s (%s available)\n", used, total, avail
            if (int(percent) > 90) {
                printf "'$RED'WARNING: Storage critical (%s)!'$NC'\n", percent
            } else if (int(percent) > 75) {
                printf "'$YELLOW'Notice: Storage getting high (%s)'$NC'\n", percent
            }
        }'
        
        # Show largest directories
        echo -e "\nLargest directories in $name:"
        du -h $mount --max-depth=1 | sort -rh | head -n 5
    fi
}

# Check both storage types
check_storage "/opt/plex/media" "Local"
[ -d "/mnt/blockstore" ] && check_storage "/mnt/blockstore" "Block"

# Show mount points
echo -e "\n${GREEN}Storage Mount Points:${NC}"
mount | grep -E "(/opt/plex|/mnt/blockstore)"

# Check for potential issues
echo -e "\n${YELLOW}Storage Health Check:${NC}"
if [ -b "/dev/sdb" ]; then
    smartctl -H /dev/sdb || echo "smartctl not installed"
fi

# Show IO stats
echo -e "\n${GREEN}IO Statistics:${NC}"
iostat -x 1 1 | grep -E "Device|sda|sdb" 