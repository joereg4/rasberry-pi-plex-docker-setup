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
            gsub(/%/,"",percent)  # Remove % symbol for comparison
            printf "Usage: %s of %s (%s available) - %s%%\n", used, total, avail, percent
            if (int(percent) > 90) {
                printf "'$RED'WARNING: Storage critical (%s%%)!'$NC'\n", percent
                system("echo \"Storage critical on $name: " percent "%% used\" | mail -s \"Plex Storage Alert\" $NOTIFY_EMAIL")
            } else if (int(percent) > 75) {
                printf "'$YELLOW'Notice: Storage getting high (%s%%)!'$NC'\n", percent
                system("echo \"Storage high on $name: " percent "%% used\" | mail -s \"Plex Storage Warning\" $NOTIFY_EMAIL")
            }
        }'
        
        # Show largest directories
        echo -e "\nLargest directories in $name:"
        du -h $mount --max-depth=1 | sort -rh | head -n 5
    fi
}

# Check both storage types
check_storage "/opt/plex/media" "Local"
[ -d "/mnt/blockstore/plex/media" ] && check_storage "/mnt/blockstore/plex/media" "Block"

# Show mount points
echo -e "\n${GREEN}Storage Mount Points:${NC}"
mount | grep -E "(/opt/plex|/mnt/blockstore)"

# Check for potential issues
echo -e "\n${GREEN}Storage Health Check:${NC}"
if [ -b "/dev/vdb" ]; then
    # Use -d sat for SATA devices in virtual environments
    smartctl -H -d sat /dev/vdb || {
        if ! command -v smartctl &> /dev/null; then
            echo "smartctl not installed (apt install smartmontools)"
        else
            echo -e "${YELLOW}Unable to check device health${NC}"
        fi
    }
fi

# Show IO stats
echo -e "\n${GREEN}IO Statistics:${NC}"
if command -v iostat &> /dev/null; then
    iostat -x 1 1 | grep -E "Device|vda|vdb"
else
    echo "iostat not installed (apt install sysstat for IO statistics)"
fi 