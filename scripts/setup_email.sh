#!/bin/bash
# Source common functions
source "$(dirname "$0")/common.sh"

echo "=== Email Setup ==="

# Ensure .env is ready
setup_env_file

# Check for .env file
if [ ! -f ".env" ]; then
    echo -e "${RED}Error: .env file not found${NC}"
    echo "Please run setup_plex.sh first"
    exit 1
fi

# Check Plex is running
if ! docker ps | grep -q plex; then
    echo -e "${RED}Error: Please run setup_plex.sh first${NC}"
    exit 1
fi

echo "Using Gmail for notifications"
echo "Enter your Gmail app password (create at https://myaccount.google.com/apppasswords):"
read -r email_pass
sed -i "s/SMTP_PASS=.*/SMTP_PASS=$email_pass/" .env

echo "Enter notification email address:"
read -r notify_email
sed -i "s/NOTIFY_EMAIL=.*/NOTIFY_EMAIL=$notify_email/" .env

echo "Enter Gmail address:"
read -r smtp_user
sed -i "s/SMTP_USER=.*/SMTP_USER=$smtp_user/" .env

echo -e "${GREEN}✓ Email setup complete!${NC}" 