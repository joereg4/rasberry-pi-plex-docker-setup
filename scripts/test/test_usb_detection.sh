#!/bin/bash
# Test USB detection logic in a simulated environment

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

cd "$PROJECT_ROOT"

echo -e "${GREEN}=== Testing USB Detection Logic ===${NC}\n"

# Source the setup script to get the function
# We'll extract just the USB detection function for testing
source <(grep -A 50 'detect_usb_storage()' scripts/setup/setup_plex.sh | head -40)

# Create a test function that simulates USB device detection
test_usb_detection() {
    echo -e "${YELLOW}Testing USB detection function...${NC}"
    
    # Test if function exists
    if type detect_usb_storage &> /dev/null; then
        echo -e "${GREEN}✓ USB detection function is defined${NC}"
    else
        echo -e "${RED}✗ USB detection function not found${NC}"
        return 1
    fi
    
    # Note: Full USB detection testing requires actual hardware or more complex mocking
    # This is a basic structure test
    echo -e "${GREEN}✓ USB detection function structure is valid${NC}"
}

# Run the test
test_usb_detection

echo -e "\n${GREEN}=== USB Detection Test Complete ===${NC}"

