#!/bin/bash

# Colors for output
export RED='\033[0;31m'
export GREEN='\033[0;32m'
export YELLOW='\033[1;33m'
export BLUE='\033[0;34m'
export NC='\033[0m'

# Quality thresholds
SIZE_REDUCTION_THRESHOLD=30  # Expect at least 30% reduction
BITRATE_THRESHOLD=20000000   # 20Mbps max bitrate
VMAF_THRESHOLD=80           # Minimum acceptable VMAF score

# Get input files
ORIGINAL="$1"
OPTIMIZED="$2"

if [ -z "$ORIGINAL" ] || [ -z "$OPTIMIZED" ]; then
    echo "Usage: $0 original_file optimized_file"
    exit 1
fi

echo "=== Video Quality Comparison ==="

# Compare file sizes
ORIGINAL_SIZE=$(stat -f %z "$ORIGINAL" | numfmt --to=iec-i --suffix=B)
OPTIMIZED_SIZE=$(stat -f %z "$OPTIMIZED" | numfmt --to=iec-i --suffix=B)
ORIGINAL_BYTES=$(stat -f %z "$ORIGINAL")
OPTIMIZED_BYTES=$(stat -f %z "$OPTIMIZED")
SIZE_REDUCTION=$(( (ORIGINAL_BYTES - OPTIMIZED_BYTES) * 100 / ORIGINAL_BYTES ))

echo -e "\n${GREEN}File Sizes:${NC}"
echo "Original: $ORIGINAL_SIZE"
echo "Optimized: $OPTIMIZED_SIZE"
echo -e "Size reduction: ${BLUE}${SIZE_REDUCTION}%${NC}"
if [ $SIZE_REDUCTION -ge $SIZE_REDUCTION_THRESHOLD ]; then
    echo -e "${GREEN}✓ Good size reduction${NC}"
else
    echo -e "${YELLOW}! Size reduction below target${NC}"
fi

# Compare video bitrates
ORIGINAL_BITRATE=$(ffprobe -v error -select_streams v:0 -show_entries stream=bit_rate -of default=noprint_wrappers=1:nokey=1 "$ORIGINAL")
OPTIMIZED_BITRATE=$(ffprobe -v error -select_streams v:0 -show_entries stream=bit_rate -of default=noprint_wrappers=1:nokey=1 "$OPTIMIZED")

echo -e "\n${GREEN}Video Bitrates:${NC}"
echo "Original: $((ORIGINAL_BITRATE/1000000))Mbps"
echo "Optimized: $((OPTIMIZED_BITRATE/1000000))Mbps"
if [ $OPTIMIZED_BITRATE -le $BITRATE_THRESHOLD ]; then
    echo -e "${GREEN}✓ Bitrate within target range${NC}"
else
    echo -e "${YELLOW}! Bitrate above target${NC}"
fi

# Generate VMAF score (if installed)
if command -v ffmpeg_quality_metrics &> /dev/null; then
    echo -e "\n${GREEN}Running VMAF quality analysis...${NC}"
    VMAF_SCORE=$(ffmpeg_quality_metrics "$ORIGINAL" "$OPTIMIZED" | grep "VMAF score:" | awk '{print $3}')
    echo "VMAF Score: ${BLUE}${VMAF_SCORE}${NC}"
    if [ $(echo "$VMAF_SCORE >= $VMAF_THRESHOLD" | bc -l) -eq 1 ]; then
        echo -e "${GREEN}✓ Quality above threshold${NC}"
    else
        echo -e "${RED}✗ Quality below threshold${NC}"
    fi
else
    echo -e "\n${YELLOW}Install ffmpeg_quality_metrics for detailed quality analysis:${NC}"
    echo "brew install ffmpeg_quality_metrics"
fi

# Overall assessment
echo -e "\n${GREEN}Overall Assessment:${NC}"
if [ $SIZE_REDUCTION -ge $SIZE_REDUCTION_THRESHOLD ] && \
   [ $OPTIMIZED_BITRATE -le $BITRATE_THRESHOLD ] && \
   { ! command -v ffmpeg_quality_metrics &> /dev/null || \
     [ $(echo "$VMAF_SCORE >= $VMAF_THRESHOLD" | bc -l) -eq 1 ]; }; then
    echo -e "${GREEN}✓ Optimization successful${NC}"
else
    echo -e "${YELLOW}! Some metrics need attention${NC}"
fi 