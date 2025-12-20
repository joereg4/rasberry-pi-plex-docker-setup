#!/bin/bash
# Test runner script for Raspberry Pi 5 Plex setup
# Can be run directly or inside Docker

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

cd "$PROJECT_ROOT"

echo -e "${GREEN}=== Running Plex Setup Tests ===${NC}\n"

# Test counter
TESTS_PASSED=0
TESTS_FAILED=0

# Function to run a test
run_test() {
    local test_name="$1"
    local test_command="$2"
    
    echo -e "${YELLOW}Running: $test_name${NC}"
    if eval "$test_command"; then
        echo -e "${GREEN}✓ PASSED: $test_name${NC}\n"
        ((TESTS_PASSED++))
        return 0
    else
        echo -e "${RED}✗ FAILED: $test_name${NC}\n"
        ((TESTS_FAILED++))
        return 1
    fi
}

# Test 1: Check if scripts are executable
run_test "Scripts are executable" "
    find scripts/ -type f -name '*.sh' | while read script; do
        [ -x \"\$script\" ] || exit 1
    done
"

# Test 2: Check if docker-compose.yml is valid
run_test "docker-compose.yml is valid" "
    docker-compose -f docker-compose.yml config > /dev/null
"

# Test 3: Check if .env.example exists and has required variables
run_test ".env.example has required variables" "
    [ -f .env.example ] && \
    grep -q 'PLEX_CLAIM' .env.example && \
    grep -q 'PLEX_HOST' .env.example && \
    grep -q 'TZ' .env.example
"

# Test 4: Check if common.sh functions are available
run_test "common.sh functions are defined" "
    source scripts/common/common.sh && \
    type setup_env_file > /dev/null && \
    type export_env_vars > /dev/null
"

# Test 5: Check if setup script has USB detection logic
run_test "Setup script has USB detection" "
    grep -q 'detect_usb_storage' scripts/setup/setup_plex.sh
"

# Test 6: Check if hardware transcoding is removed from docker-compose
run_test "Hardware transcoding removed from docker-compose" "
    ! grep -q '/dev/dri' docker-compose.yml || \
    (grep -q '# Hardware transcoding removed' docker-compose.yml)
"

# Test 7: Check if required directories are mentioned in setup script
run_test "Required directories are defined" "
    grep -q '/mnt/blockstore/plex' scripts/setup/setup_plex.sh && \
    grep -q '/opt/plex' scripts/setup/setup_plex.sh
"

# Test 8: Validate shell script syntax
run_test "Shell scripts have valid syntax" "
    find scripts/ -type f -name '*.sh' | while read script; do
        bash -n \"\$script\" || exit 1
    done
"

# Test 9: Check if documentation files exist
run_test "Documentation files exist" "
    [ -f README.md ] && \
    [ -f docs/GETTING_STARTED.md ] && \
    [ -f docs/SETUP.md ]
"

# Test 10: Check if USB device detection function is properly structured
run_test "USB detection function is properly structured" "
    grep -A 5 'detect_usb_storage()' scripts/setup/setup_plex.sh | grep -q 'local usb_device'
"

# Summary
echo -e "${GREEN}=== Test Summary ===${NC}"
echo -e "Passed: ${GREEN}$TESTS_PASSED${NC}"
echo -e "Failed: ${RED}$TESTS_FAILED${NC}"
echo ""

if [ $TESTS_FAILED -eq 0 ]; then
    echo -e "${GREEN}✓ All tests passed!${NC}"
    exit 0
else
    echo -e "${RED}✗ Some tests failed${NC}"
    exit 1
fi

