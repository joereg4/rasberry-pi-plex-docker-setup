#!/bin/bash

# Colors for output
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
NC='\033[0m'

# Check disk space
echo "=== Storage Usage ==="
df -h /opt/plex/media | awk 'NR==2 {
    used=$3
    avail=$4
    total=$2
    percent=$5
    printf "Media Storage: %s used of %s (%s available)\n", used, total, avail
    if (int(percent) > 90) {
        printf "'$RED'WARNING: Storage is almost full (%s)!'$NC'\n", percent
    } else if (int(percent) > 75) {
        printf "'$YELLOW'Notice: Storage is getting high (%s)'$NC'\n", percent
    }
}'

# Check largest files
echo -e "\n=== Largest Files ==="
find /opt/plex/media -type f -exec du -h {} + | sort -rh | head -n 10

# Check directory sizes
echo -e "\n=== Directory Sizes ==="
du -h --max-depth=1 /opt/plex/media | sort -rh

# Check Plex metadata size
echo -e "\n=== Plex Metadata ==="
du -h --max-depth=1 /opt/plex/config 