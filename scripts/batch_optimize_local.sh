#!/bin/bash

# Colors for output
export RED='\033[0;31m'
export GREEN='\033[0;32m'
export YELLOW='\033[1;33m'
export NC='\033[0m'

# Default directories - will be overridden by command line arguments
SOURCE_DIR="${1:-$HOME/Media/Movies}"
OUTPUT_DIR="${2:-$HOME/Media/test_optimized}"
CRF_VALUE="${3:-18}"  # Default to 18 if not specified

# Create output directory if it doesn't exist
mkdir -p "$OUTPUT_DIR"

echo "=== Batch Media Optimization ==="
echo "Source: $SOURCE_DIR"
echo "Output: $OUTPUT_DIR"
echo "CRF Value: $CRF_VALUE"

# Function to optimize a single file
optimize_file() {
    local input="$1"
    local filename=$(basename "$input")
    local output="$OUTPUT_DIR/${filename%.*}_optimized.mp4"
    
    echo -e "\n${GREEN}Processing: $filename${NC}"
    echo "Input size: $(stat -f %z "$input" | numfmt --to=iec-i --suffix=B)"
    
    ffmpeg -i "$input" -c:v libx264 -crf "$CRF_VALUE" -c:a copy "$output"
    
    echo "Output size: $(stat -f %z "$output" | numfmt --to=iec-i --suffix=B)"
    echo -e "${GREEN}Completed: $filename${NC}"
}

# Process all video files
echo -e "\n${YELLOW}Starting batch optimization...${NC}"
find "$SOURCE_DIR" -type f \( -name "*.mp4" -o -name "*.mkv" -o -name "*.avi" \) -size +1G | while read -r file; do
    optimize_file "$file"
done

echo -e "\n${GREEN}Batch optimization complete!${NC}"
echo "Optimized files are in: $OUTPUT_DIR" 