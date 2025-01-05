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
chmod +x scripts/setup/setup_plex.sh
```

## Setup Order

### 1. Plex Setup (Required)
```bash
./scripts/setup/setup_plex.sh
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

### Accessing Plex
1. **Recommended Access**:
   - https://app.plex.tv/desktop
     * Sign in with your Plex account
     * Server automatically appears
     * No ports or IP needed

2. **Alternative Access**:
   - Custom domain: http://plex.yourdomain.com:32400/web
   - Direct IP: http://YOUR_SERVER_IP:32400/web

3. **Mobile Apps**:
   - Official Plex app
   - Sign in with same account
   - Auto-discovers server

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

## Setup Process

### Order of Setup
1. First, set up Plex:
   ```bash
   ./scripts/setup/setup_plex.sh
   ```

2. Then configure email (optional):
   ```bash
   ./scripts/setup_email.sh
   ```

3. Configure Vultr:
   ```bash
   ./scripts/configure_vultr.sh
   ```

4. Set up automated tasks:
   ```bash
   ./scripts/setup_cron.sh
   ```
   This sets up:
   - Storage monitoring (5-minute intervals)
   - Media optimization (nightly)
   - Weekly cleanup

### Vultr Configuration
- Choose option 4 for guided setup
- Requires API key from Vultr dashboard
- Will detect existing instance and storage
- Validates all settings before saving 

### Authorization Issues
If you see "You do not have permission to access this server" or "No soup for you":

1. **Stop Plex Server**:
```bash
docker stop plex
```

2. **Edit Preferences File**:
```bash
nano /opt/plex/Library/Application\ Support/Plex\ Media\ Server/Preferences.xml
```

3. **Remove these lines**:
```xml
PlexOnlineHome="1"
PlexOnlineMail="your-email@example.com"
PlexOnlineToken="your-token"
PlexOnlineUsername="your-username"
```

4. **Restart Plex**:
```bash
docker start plex
```

5. **Access Local Web Interface**:
- Go to `http://YOUR_SERVER_IP:32400/web`
- Sign in with your Plex account
- Server should now be claimable 