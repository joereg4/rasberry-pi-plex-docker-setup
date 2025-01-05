#!/bin/bash
# Source common functions
source "$(dirname "$0")/common.sh"

echo "=== Email Setup ==="

# Pre-configure Postfix to avoid prompts
echo "postfix postfix/mailname string $(hostname)" | debconf-set-selections
echo "postfix postfix/main_mailer_type string 'Internet Site'" | debconf-set-selections

# Install required packages non-interactively
export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y mailutils postfix

# Ensure .env is ready
setup_env_file

# Check for .env file
if [ ! -f ".env" ]; then
    echo -e "${RED}Error: .env file not found${NC}"
    echo "Please run setup_plex.sh first"
    exit 1
fi

# Configure Postfix for Gmail SMTP
echo -e "${YELLOW}Configuring Postfix for Gmail SMTP...${NC}"
postconf -e "relayhost = [smtp.gmail.com]:587"
postconf -e "smtp_sasl_auth_enable = yes"
postconf -e "smtp_sasl_security_options = noanonymous"
postconf -e "smtp_sasl_password_maps = hash:/etc/postfix/sasl_passwd"
postconf -e "smtp_use_tls = yes"
postconf -e "smtp_tls_security_level = encrypt"
postconf -e "smtp_tls_CAfile = /etc/ssl/certs/ca-certificates.crt"

# Verify configuration
echo -e "${YELLOW}Verifying Postfix configuration...${NC}"
postconf -n | grep "smtp_"

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

# Update Postfix SASL password file
echo "[smtp.gmail.com]:587 $smtp_user:$email_pass" > /etc/postfix/sasl_passwd
chmod 600 /etc/postfix/sasl_passwd
postmap /etc/postfix/sasl_passwd

# Restart Postfix using service command
service postfix restart

# Test email
echo "Sending test email..."
echo "Test email from Plex server at $(date)" | mail -s "Plex Email Test" "$notify_email"

echo -e "${GREEN}✓ Email setup complete!${NC}"
echo "A test email has been sent to $notify_email"
echo "Please check your inbox to verify the setup"