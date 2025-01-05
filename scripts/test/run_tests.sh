#!/bin/bash

# Source common functions
source "$(dirname "$0")/common.sh"

echo "=== Running Tests ==="

# Function to check prerequisites
check_prereqs() {
    echo -e "\n${YELLOW}Checking prerequisites...${NC}"
    
    # Setup mock block storage
    echo -e "${YELLOW}Setting up mock block storage...${NC}"
    mkdir -p test_data
    dd if=/dev/zero of=test_data/block.img bs=1M count=1024
    losetup -fP test_data/block.img
    LOOP_DEV=$(losetup -j test_data/block.img | cut -d: -f1)
    mkfs.ext4 $LOOP_DEV
    mkdir -p /mnt/blockstore
    mount $LOOP_DEV /mnt/blockstore
    
    # Check .env file
    if [ ! -f .env ]; then
        echo -e "${RED}Error: .env file missing${NC}"
        echo "Creating from example..."
        cp .env.example .env
        # Add test Vultr configuration
        echo "VULTR_API_KEY=test_key" >> .env
        echo "VULTR_INSTANCE_ID=test_instance" >> .env
        echo "VULTR_BLOCK_ID=test_block" >> .env
        # Verify .env was created
        echo -e "${YELLOW}Verifying .env contents:${NC}"
        cat .env
    fi
    
    # Check email configuration
    if ! grep -q "SMTP_USER" .env || ! grep -q "SMTP_PASS" .env; then
        echo -e "${RED}Email configuration missing in .env${NC}"
        return 1
    fi
    
    # Check postfix status
    if ! service postfix status > /dev/null; then
        echo -e "${YELLOW}Starting postfix...${NC}"
        service postfix start
    fi
    
    # Check cron status
    if ! service cron status > /dev/null; then
        echo -e "${YELLOW}Starting cron...${NC}"
        service cron start
    fi
    
    # Create test data directory
    if [ ! -d "test_data/Media/Movies" ]; then
        echo -e "${YELLOW}Creating test data directory...${NC}"
        mkdir -p test_data/Media/Movies
        # Create a valid MP4 file
        ffmpeg -f lavfi -i testsrc=duration=10:size=1280x720:rate=30 \
               -c:v libx264 -b:v 1M \
               test_data/Media/Movies/test_movie.mp4
    fi
}

# Cleanup function
cleanup() {
    echo -e "${YELLOW}Cleaning up...${NC}"
    umount /mnt/blockstore 2>/dev/null
    losetup -D  # Detach all loop devices
    rm -rf test_data
}

# Set trap for cleanup
trap cleanup EXIT

# Test email setup
echo "Testing email setup..."
check_prereqs || exit 1

echo -e "\n${YELLOW}Current email configuration:${NC}"
grep "SMTP_" .env
grep "NOTIFY_EMAIL" .env

./scripts/setup_email.sh

echo -e "\n${YELLOW}Checking mail log:${NC}"
tail -n 20 /var/log/mail.log

# Test cron setup
echo "Testing cron setup..."
./scripts/setup_cron.sh

echo -e "\n${YELLOW}Verifying cron jobs:${NC}"
crontab -l

# Test storage management
echo "Testing storage management..."
echo -e "${YELLOW}Block device status:${NC}"
losetup -l
echo -e "${YELLOW}Mount points:${NC}"
mount | grep blockstore
./scripts/manage_storage.sh check

echo -e "\n${YELLOW}Storage status:${NC}"
df -h

# Test media analysis
echo "Testing media analysis..."
./scripts/analyze_media.sh "test_data/Media/Movies"

echo -e "\n${YELLOW}Test data files:${NC}"
ls -lh test_data/Media/Movies/

echo "=== Tests Complete ===" 