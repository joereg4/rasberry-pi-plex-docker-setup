#!/bin/bash

# Source common functions
source "$(dirname "$0")/common.sh"

echo "=== Cron Jobs Setup ==="

# Ensure scripts are executable
chmod +x scripts/*.sh

# Create temporary crontab file
TEMP_CRON=$(mktemp)
crontab -l > "$TEMP_CRON" 2>/dev/null

# Add storage monitoring (every 5 minutes)
if ! grep -q "manage_storage.sh check" "$TEMP_CRON"; then
    echo "*/5 * * * * $(pwd)/scripts/manage_storage.sh check" >> "$TEMP_CRON"
    echo -e "${GREEN}✓ Added storage monitoring${NC}"
fi

# Install new crontab
crontab "$TEMP_CRON"
rm "$TEMP_CRON"

# Verify cron jobs
echo -e "\n${YELLOW}Current cron jobs:${NC}"
crontab -l

echo -e "${GREEN}✓ Cron jobs setup complete!${NC}"
echo "Jobs will run automatically at scheduled times:"
echo "- Storage check: Every 5 minutes"
echo "- Cleanup: Weekly on Sunday at 3 AM" 