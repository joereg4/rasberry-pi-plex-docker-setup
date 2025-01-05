#!/bin/bash

# Colors for output
export RED='\033[0;31m'
export GREEN='\033[0;32m'
export YELLOW='\033[1;33m'
export NC='\033[0m'

echo "=== Media Optimization ==="

# Parse arguments
while getopts "i:o:q:" opt; do
    case $opt in
        i) INPUT_FILE="$OPTARG" ;;
        o) OUTPUT_FILE="$OPTARG" ;;
        q) CRF_VALUE="$OPTARG" ;;
        *) echo "Invalid option"; exit 1 ;;
    esac
done

# Verify input file exists
if [ ! -f "$INPUT_FILE" ]; then
    echo -e "${RED}Input file does not exist: $INPUT_FILE${NC}"
    exit 1
fi

# Create output directory if needed
mkdir -p "$(dirname "$OUTPUT_FILE")"

# Show file sizes
input_size=$(ls -lh "$INPUT_FILE" | awk '{print $5}')
echo -e "Input size: $input_size"

# Optimize video
echo -e "${YELLOW}Optimizing: $INPUT_FILE${NC}"

# Check if ffmpeg is installed
if ! command -v ffmpeg &> /dev/null; then
    echo -e "${RED}ffmpeg not found. Installing...${NC}"
    brew install ffmpeg
fi

# Run optimization
ffmpeg -i "$INPUT_FILE" \
       -c:v libx264 \
       -crf "$CRF_VALUE" \
       -preset fast \
       -c:a copy \
       -c:s copy \
       "$OUTPUT_FILE"

# Show output size if successful
if [ -f "$OUTPUT_FILE" ]; then
    output_size=$(ls -lh "$OUTPUT_FILE" | awk '{print $5}')
    echo -e "${GREEN}Success! Output size: $output_size${NC}"
else
    echo -e "${RED}Failed to create output file${NC}"
fi 