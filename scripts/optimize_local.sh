#!/bin/bash

# Colors for output
export RED='\033[0;31m'
export GREEN='\033[0;32m'
export YELLOW='\033[1;33m'
export NC='\033[0m'

# Get the media directory from command line or use default
MEDIA_DIR="${1:-$HOME/media/movies}"

echo "=== Media Optimization Analysis ==="
echo "Analyzing directory: $MEDIA_DIR"

# Function to suggest optimization command
suggest_optimization() {
    local file="$1"
    local size=$(stat -f %z "$file")
    local size_gb=$(echo "scale=2; $size/1024/1024/1024" | bc)
    local bitrate=$(ffprobe -v error -select_streams v:0 -show_entries stream=bit_rate -of default=noprint_wrappers=1:nokey=1 "$file")
    
    echo -e "${YELLOW}File: $file${NC}"
    echo "Size: ${size_gb}GB"
    
    if [ ! -z "$bitrate" ]; then
        echo "Bitrate: $((bitrate/1000000))Mbps"
        if [ "$bitrate" -gt 20000000 ]; then
            echo -e "${RED}Recommendation: High bitrate detected${NC}"
            echo "Optimize command:"
            echo "ffmpeg -i \"$file\" -c:v libx264 -crf 22 -c:a copy \"${file%.*}_optimized.mp4\""
        fi
    fi
    echo "---"
}

# Check if ffmpeg is installed
if ! command -v ffmpeg &> /dev/null; then
    echo "ffmpeg not found. Install with: brew install ffmpeg"
    exit 1
fi

# Find and analyze video files
echo -e "\n${GREEN}Analyzing video files...${NC}"
export -f suggest_optimization  # Make function available to subshell
find "$MEDIA_DIR" -type f \( -name "*.mp4" -o -name "*.mkv" -o -name "*.avi" \) -size +1G -exec bash -c 'suggest_optimization "$1"' _ {} \;

echo -e "\n${GREEN}Optimization Tips:${NC}"
echo "1. CRF value ranges from 0 (lossless) to 51 (worst quality)"
echo "2. Recommended CRF values:"
echo "   - 18-22: High quality, larger file size"
echo "   - 23-26: Good quality, reasonable file size"
echo "3. Test command (5 min sample):"
echo "   ffmpeg -ss 00:00:00 -t 00:05:00 -i input.mp4 -c:v libx264 -crf 23 -c:a copy test_output.mp4" 