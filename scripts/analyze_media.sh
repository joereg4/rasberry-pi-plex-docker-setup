#!/bin/bash

# Source common functions
source "$(dirname "$0")/common.sh"

echo "=== Media Analysis ==="

# Function to convert size to GB
to_gb() {
    local size=$1
    echo "scale=2; $size/1024/1024/1024" | bc
}

echo -e "\n${GREEN}Analyzing large files...${NC}"

# Find and analyze files over 4GB
find "$1" -type f \( -name "*.mp4" -o -name "*.mkv" -o -name "*.avi" \) -size +4G -exec sh -c '
    for file do
        size=$(stat -c %s "$file")
        size_gb=$(echo "scale=2; $size/1024/1024/1024" | bc)
        bitrate=$(ffprobe -v error -select_streams v:0 -show_entries stream=bit_rate -of default=noprint_wrappers=1:nokey=1 "$file")
        
        if [ ! -z "$bitrate" ]; then
            echo "File: $(basename "$file")"
            echo "Size: ${size_gb}GB"
            echo "Bitrate: $((bitrate/1000000))Mbps"
            echo "---"
        fi
    done
' sh {} + 