#!/bin/bash
# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "=== Vultr CLI Test ==="

# Test 1: CLI Installation
if vultr-cli version; then
    echo -e "${GREEN}✓ Vultr CLI installed${NC}"
else
    echo -e "${RED}✗ Vultr CLI not installed${NC}"
    exit 1
fi

# Test 2: API Connection
if vultr-cli account info; then
    echo -e "${GREEN}✓ API connection successful${NC}"
else
    echo -e "${RED}✗ API connection failed${NC}"
    exit 1
fi
