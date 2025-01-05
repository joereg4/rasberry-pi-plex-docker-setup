#!/bin/bash
# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "=== Batch Media Optimization ==="

# Parse arguments
while getopts "s:d:q:" opt; do
    case $opt in
        s) SOURCE_DIR="$OPTARG" ;;
        d) OUTPUT_DIR="$OPTARG" ;;
        q) QUALITY="$OPTARG" ;;
        *) echo "Invalid option"; exit 1 ;;
    esac
done

# Verify directories exist
if [ ! -d "$SOURCE_DIR" ]; then
    echo -e "${RED}Source directory does not exist: $SOURCE_DIR${NC}"
    exit 1
fi

if [ ! -d "$OUTPUT_DIR" ]; then
    echo -e "${YELLOW}Creating output directory: $OUTPUT_DIR${NC}"
    mkdir -p "$OUTPUT_DIR"
fi

echo "Source: $SOURCE_DIR"
echo "Output: $OUTPUT_DIR"
echo "Quality: $QUALITY"

# Process all video files
echo -e "\n${YELLOW}Starting batch optimization...${NC}"
echo -e "Looking for video files in: $SOURCE_DIR"

find "$SOURCE_DIR" -type f \( -name "*.mp4" -o -name "*.mkv" -o -name "*.avi" \) -size +4G | while read -r video; do
    filename=$(basename "$video")
    output="$OUTPUT_DIR/${filename%.*}_optimized.mp4"
    
    echo -e "\n${GREEN}Processing: $filename${NC}"
    echo "Full input path: $video"
    echo "Full output path: $output"
    
    # Skip if output already exists
    if [ -f "$output" ]; then
        echo -e "${YELLOW}Output file already exists, skipping: $output${NC}"
        continue
    fi
    
    # Run optimize_local with verbose output
    set -x
    ./scripts/optimize_local.sh -i "$video" -o "$output" -q "$QUALITY"
    set +x
    
    # Check if output file was created
    if [ -f "$output" ]; then
        echo -e "${GREEN}Successfully created: $output${NC}"
        # Show size comparison
        input_size=$(ls -lh "$video" | awk '{print $5}')
        output_size=$(ls -lh "$output" | awk '{print $5}')
        echo -e "Input size: $input_size"
        echo -e "Output size: $output_size"
    else
        echo -e "${RED}Failed to create: $output${NC}"
    fi
    
    echo -e "\n${YELLOW}Moving to next file...${NC}"
done

echo -e "\n${GREEN}Batch processing complete!${NC}"
echo -e "Check optimized files in: $OUTPUT_DIR" 