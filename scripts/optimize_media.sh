#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "=== Media Optimization Analysis ==="

# Function to convert size to GB
to_gb() {
    local size=$1
    echo "scale=2; $size/1024/1024/1024" | bc
}

# Function to suggest optimization command
suggest_optimization() {
    local file="$1"
    local bitrate="$2"
    local size="$3"
    
    echo -e "${YELLOW}File: $file${NC}"
    echo "Current Size: ${size}GB"
    echo "Current Bitrate: $((bitrate/1000000))Mbps"
    
    if [ "$bitrate" -gt 20000000 ]; then
        echo -e "${RED}Recommendation: High bitrate detected, can be optimized${NC}"
        echo "Suggested command:"
        echo "ffmpeg -i \"$file\" -c:v libx264 -crf 22 -c:a copy \"${file%.*}_optimized.mp4\""
        echo "Expected size reduction: ~40-50%"
    elif [ "$size" -gt 10 ]; then
        echo -e "${YELLOW}Recommendation: Large file, moderate optimization possible${NC}"
        echo "Suggested command:"
        echo "ffmpeg -i \"$file\" -c:v libx264 -crf 23 -c:a copy \"${file%.*}_optimized.mp4\""
        echo "Expected size reduction: ~30-40%"
    fi
    echo "---"
}

echo -e "\n${GREEN}Analyzing large files...${NC}"

# Find and analyze large files
find ~/Media -type f -size +4G -exec sh -c '
    for file do
        size=$(stat -f %z "$file")
        size_gb=$(echo "scale=2; $size/1024/1024/1024" | bc)
        bitrate=$(ffprobe -v error -select_streams v:0 -show_entries stream=bit_rate -of default=noprint_wrappers=1:nokey=1 "$file")
        
        if [ ! -z "$bitrate" ]; then
            echo "FILE:$file|SIZE:$size_gb|BITRATE:$bitrate"
        fi
    done
' sh {} + | while IFS="|" read -r file_info size_info bitrate_info; do
    file=${file_info#FILE:}
    size=${size_info#SIZE:}
    bitrate=${bitrate_info#BITRATE:}
    suggest_optimization "$file" "$bitrate" "$size"
done

echo -e "\n${GREEN}Optimization Tips:${NC}"
echo "1. CRF value ranges from 0 (lossless) to 51 (worst quality)"
echo "2. Recommended CRF values:"
echo "   - 18-22: High quality, larger file size"
echo "   - 23-26: Good quality, reasonable file size"
echo "   - 27-30: Acceptable quality, smaller file size"
echo "3. Test a small segment first:"
echo "   ffmpeg -ss 00:00:00 -t 00:05:00 -i input.mp4 -c:v libx264 -crf 23 -c:a copy test_output.mp4"

echo -e "\n${YELLOW}To optimize a specific file:${NC}"
echo "./optimize_media.sh --optimize \"path/to/file.mp4\" 23" 