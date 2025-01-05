#!/bin/bash
source "$(dirname "$0")/common.sh"

setup_env_file
export_env_vars

# Print exported variables for verification
echo -e "\n${YELLOW}Verifying exported variables:${NC}"
echo -e "\n${GREEN}Plex Configuration:${NC}"
echo "PLEX_CLAIM=$PLEX_CLAIM"
echo "PLEX_HOST=$PLEX_HOST"
echo "TZ=$TZ"

echo -e "\n${GREEN}Vultr Configuration:${NC}"
echo "VULTR_API_KEY=${VULTR_API_KEY:0:8}..." # Show only first 8 chars for security
echo "VULTR_BLOCK_ID=$VULTR_BLOCK_ID"
echo "VULTR_INSTANCE_ID=$VULTR_INSTANCE_ID"

echo -e "\n${GREEN}Email Configuration:${NC}"
echo "SMTP_HOST=$SMTP_HOST"
echo "SMTP_PORT=$SMTP_PORT"
echo "SMTP_USER=$SMTP_USER"
echo "SMTP_PASS=${SMTP_PASS:0:4}..." # Show only first 4 chars for security
echo "NOTIFY_EMAIL=$NOTIFY_EMAIL" 