# Setup Guide

## Prerequisites
- Ubuntu 22.04 LTS
- SSH access to server
- Docker installed
- Git installed

## Initial Setup
```bash
# Clone repository
git clone https://github.com/joereg4/plex-docker-setup.git
cd plex-docker-setup
chmod +x scripts/*.sh
```

## Setup Order

### 1. Plex Setup (Required)
```bash
./scripts/setup_plex.sh
```
You'll need:
- Plex claim token from https://plex.tv/claim
- Your server's IP address
- Preferred timezone

### 2. Email Setup (Optional)
```bash
./scripts/setup_email.sh
```
You'll need:
- Gmail account
- Gmail app password
- Notification email address

### 3. Vultr Setup (Optional)
```bash
./scripts/configure_vultr.sh
```
You'll need:
- Vultr API key
- Instance ID
- Block Storage ID (if using)

## Verification
After each step:
1. **Plex**:
   - Access http://YOUR_IP:32400/web
   - Verify login works
   - Check media directories

2. **Email**:
   - Check notification settings
   - Test email alerts

3. **Vultr**:
   - Verify CLI works
   - Check storage mounting
   - Test auto-expansion

## Troubleshooting
If any script fails:
1. Check prerequisites
2. Verify previous steps completed
3. Check logs in /opt/plex-docker-setup/scripts/reports/ 