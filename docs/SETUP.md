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
- Access method:
  * Server IP address (auto-detected)
  * Custom domain (DNS must be configured)
  * Localhost (for local access only)
- Preferred timezone

### Custom Domain Setup
If using a custom domain:
1. Add DNS Records:
   ```
   Type  Name              Content
   A     plex              YOUR_SERVER_IP
   ```

2. Wait for DNS Propagation:
   - Can take 5-60 minutes
   - Script will verify DNS resolution

3. Firewall Configuration:
   - Port 80 (HTTP)
   - Port 443 (HTTPS)
   - Plex handles SSL certificates automatically

4. SSL/Security:
   - Plex generates its own certificates
   - No need for Certbot/Let's Encrypt
   - Certificates auto-renew

5. Domain Tips:
   - Use a dedicated subdomain (e.g., plex.yourdomain.com)
   - Avoid using Cloudflare proxy (use DNS only)
   - Keep DNS TTL low during setup (300s/5min)

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