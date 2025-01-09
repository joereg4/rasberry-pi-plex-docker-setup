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

### 2. Monitoring Setup (Required for automation)
```bash
./scripts/setup/setup_monitoring.sh
```
You'll need:
- Gmail account & app password (create at https://myaccount.google.com/apppasswords)
- Vultr API key (from https://my.vultr.com/settings/#settingsapi)

The script will:
1. Configure email notifications:
   - Sets up SMTP for Gmail
   - Configures notification email
   - Tests email delivery

2. Setup Vultr CLI and storage:
   - Installs and configures Vultr CLI
   - Automatically retrieves available instances
   - Shows available block storage volumes
   - Guides you through selection

3. Configure automated monitoring:
   - Sets up storage monitoring (every 5 minutes)
   - Configures email alerts
   - Enables auto-expansion when needed

Note: The script will automatically retrieve and display your available Vultr instances and block storage volumes for selection.

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

## Block Storage Operations

When performing block storage operations (detach, resize, reattach), SSH connections may be interrupted. Here's how to handle it:

1. If disconnected during detach:
   - Wait 30 seconds
   - Reconnect via SSH
   - Check Vultr dashboard to confirm detachment

2. If disconnected during reattach:
   - Wait 30 seconds
   - Reconnect via SSH
   - Run these commands to complete the process:
   ```bash
   # Resize filesystem (works while mounted)
   resize2fs /dev/vdb
  
   # Verify new size
   df -h /mnt/blockstore
  
   # Start Plex
   cd ~/plex-docker-setup
   docker-compose up -d
   ```

Note: The filesystem can be resized while mounted, no need to unmount/remount.

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

## Block Storage Operations

When performing block storage operations (detach, resize, reattach), SSH connections may be interrupted. Here's how to handle it:

1. If disconnected during detach:
   - Wait 30 seconds
   - Reconnect via SSH
   - Check Vultr dashboard to confirm detachment

2. If disconnected during reattach:
   - Wait 30 seconds
   - Reconnect via SSH
   - Run these commands to complete the process:
   ```bash
   # Resize filesystem (works while mounted)
   resize2fs /dev/vdb
  
   # Verify new size
   df -h /mnt/blockstore
  
   # Start Plex
   cd ~/plex-docker-setup
   docker-compose up -d
   ```

Note: The filesystem can be resized while mounted, no need to unmount/remount.

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

## Block Storage Operations

When performing block storage operations (detach, resize, reattach), SSH connections may be interrupted. Here's how to handle it:

1. If disconnected during detach:
   - Wait 30 seconds
   - Reconnect via SSH
   - Check Vultr dashboard to confirm detachment

2. If disconnected during reattach:
   - Wait 30 seconds
   - Reconnect via SSH
   - Run these commands to complete the process:
   ```bash
   # Resize filesystem (works while mounted)
   resize2fs /dev/vdb
  
   # Verify new size
   df -h /mnt/blockstore
  
   # Start Plex
   cd ~/plex-docker-setup
   docker-compose up -d
   ```

Note: The filesystem can be resized while mounted, no need to unmount/remount.

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

## Block Storage Operations

When performing block storage operations (detach, resize, reattach), SSH connections may be interrupted. Here's how to handle it:

1. If disconnected during detach:
   - Wait 30 seconds
   - Reconnect via SSH
   - Check Vultr dashboard to confirm detachment

2. If disconnected during reattach:
   - Wait 30 seconds
   - Reconnect via SSH
   - Run these commands to complete the process:
   ```bash
   # Resize filesystem (works while mounted)
   resize2fs /dev/vdb
  
   # Verify new size
   df -h /mnt/blockstore
  
   # Start Plex
   cd ~/plex-docker-setup
   docker-compose up -d
   ```

Note: The filesystem can be resized while mounted, no need to unmount/remount.

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

## Block Storage Operations

When performing block storage operations (detach, resize, reattach), SSH connections may be interrupted. Here's how to handle it:

1. If disconnected during detach:
   - Wait 30 seconds
   - Reconnect via SSH
   - Check Vultr dashboard to confirm detachment

2. If disconnected during reattach:
   - Wait 30 seconds
   - Reconnect via SSH
   - Run these commands to complete the process:
   ```bash
   # Resize filesystem (works while mounted)
   resize2fs /dev/vdb
  
   # Verify new size
   df -h /mnt/blockstore
  
   # Start Plex
   cd ~/plex-docker-setup
   docker-compose up -d
   ```

Note: The filesystem can be resized while mounted, no need to unmount/remount.

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

## Block Storage Operations

When performing block storage operations (detach, resize, reattach), SSH connections may be interrupted. Here's how to handle it:

1. If disconnected during detach:
   - Wait 30 seconds
   - Reconnect via SSH
   - Check Vultr dashboard to confirm detachment

2. If disconnected during reattach:
   - Wait 30 seconds
   - Reconnect via SSH
   - Run these commands to complete the process:
   ```bash
   # Resize filesystem (works while mounted)
   resize2fs /dev/vdb
  
   # Verify new size
   df -h /mnt/blockstore
  
   # Start Plex
   cd ~/plex-docker-setup
   docker-compose up -d
   ```

Note: The filesystem can be resized while mounted, no need to unmount/remount.

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

## Block Storage Operations

When performing block storage operations (detach, resize, reattach), SSH connections may be interrupted. Here's how to handle it:

1. If disconnected during detach:
   - Wait 30 seconds
   - Reconnect via SSH
   - Check Vultr dashboard to confirm detachment

2. If disconnected during reattach:
   - Wait 30 seconds
   - Reconnect via SSH
   - Run these commands to complete the process:
   ```bash
   # Resize filesystem (works while mounted)
   resize2fs /dev/vdb
  
   # Verify new size
   df -h /mnt/blockstore
  
   # Start Plex
   cd ~/plex-docker-setup
   docker-compose up -d
   ```

Note: The filesystem can be resized while mounted, no need to unmount/remount.

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

## Block Storage Operations

When performing block storage operations (detach, resize, reattach), SSH connections may be interrupted. Here's how to handle it:

1. If disconnected during detach:
   - Wait 30 seconds
   - Reconnect via SSH
   - Check Vultr dashboard to confirm detachment

2. If disconnected during reattach:
   - Wait 30 seconds
   - Reconnect via SSH
   - Run these commands to complete the process:
   ```bash
   # Resize filesystem (works while mounted)
   resize2fs /dev/vdb
  
   # Verify new size
   df -h /mnt/blockstore
  
   # Start Plex
   cd ~/plex-docker-setup
   docker-compose up -d
   ```

Note: The filesystem can be resized while mounted, no need to unmount/remount.

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

## Block Storage Operations

When performing block storage operations (detach, resize, reattach), SSH connections may be interrupted. Here's how to handle it:

1. If disconnected during detach:
   - Wait 30 seconds
   - Reconnect via SSH
   - Check Vultr dashboard to confirm detachment

2. If disconnected during reattach:
   - Wait 30 seconds
   - Reconnect via SSH
   - Run these commands to complete the process:
   ```bash
   # Resize filesystem (works while mounted)
   resize2fs /dev/vdb
  
   # Verify new size
   df -h /mnt/blockstore
  
   # Start Plex
   cd ~/plex-docker-setup
   docker-compose up -d
   ```

Note: The filesystem can be resized while mounted, no need to unmount/remount.

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

## Block Storage Operations

When performing block storage operations (detach, resize, reattach), SSH connections may be interrupted. Here's how to handle it:

1. If disconnected during detach:
   - Wait 30 seconds
   - Reconnect via SSH
   - Check Vultr dashboard to confirm detachment

2. If disconnected during reattach:
   - Wait 30 seconds
   - Reconnect via SSH
   - Run these commands to complete the process:
   ```bash
   # Resize filesystem (works while mounted)
   resize2fs /dev/vdb
  
   # Verify new size
   df -h /mnt/blockstore
  
   # Start Plex
   cd ~/plex-docker-setup
   docker-compose up -d
   ```

Note: The filesystem can be resized while mounted, no need to unmount/remount.

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

## Block Storage Operations

When performing block storage operations (detach, resize, reattach), SSH connections may be interrupted. Here's how to handle it:

1. If disconnected during detach:
   - Wait 30 seconds
   - Reconnect via SSH
   - Check Vultr dashboard to confirm detachment

2. If disconnected during reattach:
   - Wait 30 seconds
   - Reconnect via SSH
   - Run these commands to complete the process:
   ```bash
   # Resize filesystem (works while mounted)
   resize2fs /dev/vdb
  
   # Verify new size
   df -h /mnt/blockstore
  
   # Start Plex
   cd ~/plex-docker-setup
   docker-compose up -d
   ```

Note: The filesystem can be resized while mounted, no need to unmount/remount.

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

## Block Storage Operations

When performing block storage operations (detach, resize, reattach), SSH connections may be interrupted. Here's how to handle it:

1. If disconnected during detach:
   - Wait 30 seconds
   - Reconnect via SSH
   - Check Vultr dashboard to confirm detachment

2. If disconnected during reattach:
   - Wait 30 seconds
   - Reconnect via SSH
   - Run these commands to complete the process:
   ```bash
   # Resize filesystem (works while mounted)
   resize2fs /dev/vdb
  
   # Verify new size
   df -h /mnt/blockstore
  
   # Start Plex
   cd ~/plex-docker-setup
   docker-compose up -d
   ```

Note: The filesystem can be resized while mounted, no need to unmount/remount.

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

## Block Storage Operations

When performing block storage operations (detach, resize, reattach), SSH connections may be interrupted. Here's how to handle it:

1. If disconnected during detach:
   - Wait 30 seconds
   - Reconnect via SSH
   - Check Vultr dashboard to confirm detachment

2. If disconnected during reattach:
   - Wait 30 seconds
   - Reconnect via SSH
   - Run these commands to complete the process:
   ```bash
   # Resize filesystem (works while mounted)
   resize2fs /dev/vdb
  
   # Verify new size
   df -h /mnt/blockstore
  
   # Start Plex
   cd ~/plex-docker-setup
   docker-compose up -d
   ```

Note: The filesystem can be resized while mounted, no need to unmount/remount.

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

## Block Storage Operations

When performing block storage operations (detach, resize, reattach), SSH connections may be interrupted. Here's how to handle it:

1. If disconnected during detach:
   - Wait 30 seconds
   - Reconnect via SSH
   - Check Vultr dashboard to confirm detachment

2. If disconnected during reattach:
   - Wait 30 seconds
   - Reconnect via SSH
   - Run these commands to complete the process:
   ```bash
   # Resize filesystem (works while mounted)
   resize2fs /dev/vdb
  
   # Verify new size
   df -h /mnt/blockstore
  
   # Start Plex
   cd ~/plex-docker-setup
   docker-compose up -d
   ```

Note: The filesystem can be resized while mounted, no need to unmount/remount.

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

## Block Storage Operations

When performing block storage operations (detach, resize, reattach), SSH connections may be interrupted. Here's how to handle it:

1. If disconnected during detach:
   - Wait 30 seconds
   - Reconnect via SSH
   - Check Vultr dashboard to confirm detachment

2. If disconnected during reattach:
   - Wait 30 seconds
   - Reconnect via SSH
   - Run these commands to complete the process:
   ```bash
   # Resize filesystem (works while mounted)
   resize2fs /dev/vdb
  
   # Verify new size
   df -h /mnt/blockstore
  
   # Start Plex
   cd ~/plex-docker-setup
   docker-compose up -d
   ```

Note: The filesystem can be resized while mounted, no need to unmount/remount.

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

## Block Storage Operations

When performing block storage operations (detach, resize, reattach), SSH connections may be interrupted. Here's how to handle it:

1. If disconnected during detach:
   - Wait 30 seconds
   - Reconnect via SSH
   - Check Vultr dashboard to confirm detachment

2. If disconnected during reattach:
   - Wait 30 seconds
   - Reconnect via SSH
   - Run these commands to complete the process:
   ```bash
   # Resize filesystem (works while mounted)
   resize2fs /dev/vdb
  
   # Verify new size
   df -h /mnt/blockstore
  
   # Start Plex
   cd ~/plex-docker-setup
   docker-compose up -d
   ```

Note: The filesystem can be resized while mounted, no need to unmount/remount.

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

## Block Storage Operations

When performing block storage operations (detach, resize, reattach), SSH connections may be interrupted. Here's how to handle it:

1. If disconnected during detach:
   - Wait 30 seconds
   - Reconnect via SSH
   - Check Vultr dashboard to confirm detachment

2. If disconnected during reattach:
   - Wait 30 seconds
   - Reconnect via SSH
   - Run these commands to complete the process:
   ```bash
   # Resize filesystem (works while mounted)
   resize2fs /dev/vdb
  
   # Verify new size
   df -h /mnt/blockstore
  
   # Start Plex
   cd ~/plex-docker-setup
   docker-compose up -d
   ```

Note: The filesystem can be resized while mounted, no need to unmount/remount.

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

## Block Storage Operations

When performing block storage operations (detach, resize, reattach), SSH connections may be interrupted. Here's how to handle it:

1. If disconnected during detach:
   - Wait 30 seconds
   - Reconnect via SSH
   - Check Vultr dashboard to confirm detachment

2. If disconnected during reattach:
   - Wait 30 seconds
   - Reconnect via SSH
   - Run these commands to complete the process:
   ```bash
   # Resize filesystem (works while mounted)
   resize2fs /dev/vdb
  
   # Verify new size
   df -h /mnt/blockstore
  
   # Start Plex
   cd ~/plex-docker-setup
   docker-compose up -d
   ```

Note: The filesystem can be resized while mounted, no need to unmount/remount.

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

## Block Storage Operations

When performing block storage operations (detach, resize, reattach), SSH connections may be interrupted. Here's how to handle it:

1. If disconnected during detach:
   - Wait 30 seconds
   - Reconnect via SSH
   - Check Vultr dashboard to confirm detachment

2. If disconnected during reattach:
   - Wait 30 seconds
   - Reconnect via SSH
   - Run these commands to complete the process:
   ```bash
   # Resize filesystem (works while mounted)
   resize2fs /dev/vdb
  
   # Verify new size
   df -h /mnt/blockstore
  
   # Start Plex
   cd ~/plex-docker-setup
   docker-compose up -d
   ```

Note: The filesystem can be resized while mounted, no need to unmount/remount.

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

## Block Storage Operations

When performing block storage operations (detach, resize, reattach), SSH connections may be interrupted. Here's how to handle it:

1. If disconnected during detach:
   - Wait 30 seconds
   - Reconnect via SSH
   - Check Vultr dashboard to confirm detachment

2. If disconnected during reattach:
   - Wait 30 seconds
   - Reconnect via SSH
   - Run these commands to complete the process:
   ```bash
   # Resize filesystem (works while mounted)
   resize2fs /dev/vdb
  
   # Verify new size
   df -h /mnt/blockstore
  
   # Start Plex
   cd ~/plex-docker-setup
   docker-compose up -d
   ```

Note: The filesystem can be resized while mounted, no need to unmount/remount.

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

## Block Storage Operations

When performing block storage operations (detach, resize, reattach), SSH connections may be interrupted. Here's how to handle it:

1. If disconnected during detach:
   - Wait 30 seconds
   - Reconnect via SSH
   - Check Vultr dashboard to confirm detachment

2. If disconnected during reattach:
   - Wait 30 seconds
   - Reconnect via SSH
   - Run these commands to complete the process:
   ```bash
   # Resize filesystem (works while mounted)
   resize2fs /dev/vdb
  
   # Verify new size
   df -h /mnt/blockstore
  
   # Start Plex
   cd ~/plex-docker-setup
   docker-compose up -d
   ```

Note: The filesystem can be resized while mounted, no need to unmount/remount.

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

## Block Storage Operations

When performing block storage operations (detach, resize, reattach), SSH connections may be interrupted. Here's how to handle it:

1. If disconnected during detach:
   - Wait 30 seconds
   - Reconnect via SSH
   - Check Vultr dashboard to confirm detachment

2. If disconnected during reattach:
   - Wait 30 seconds
   - Reconnect via SSH
   - Run these commands to complete the process:
   ```bash
   # Resize filesystem (works while mounted)
   resize2fs /dev/vdb
  
   # Verify new size
   df -h /mnt/blockstore
  
   # Start Plex
   cd ~/plex-docker-setup
   docker-compose up -d
   ```

Note: The filesystem can be resized while mounted, no need to unmount/remount.

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

## Block Storage Operations

When performing block storage operations (detach, resize, reattach), SSH connections may be interrupted. Here's how to handle it:

1. If disconnected during detach:
   - Wait 30 seconds
   - Reconnect via SSH
   - Check Vultr dashboard to confirm detachment

2. If disconnected during reattach:
   - Wait 30 seconds
   - Reconnect via SSH
   - Run these commands to complete the process:
   ```bash
   # Resize filesystem (works while mounted)
   resize2fs /dev/vdb
  
   # Verify new size
   df -h /mnt/blockstore
  
   # Start Plex
   cd ~/plex-docker-setup
   docker-compose up -d
   ```

Note: The filesystem can be resized while mounted, no need to unmount/remount.

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

## Block Storage Operations

When performing block storage operations (detach, resize, reattach), SSH connections may be interrupted. Here's how to handle it:

1. If disconnected during detach:
   - Wait 30 seconds
   - Reconnect via SSH
   - Check Vultr dashboard to confirm detachment

2. If disconnected during reattach:
   - Wait 30 seconds
   - Reconnect via SSH
   - Run these commands to complete the process:
   ```bash
   # Resize filesystem (works while mounted)
   resize2fs /dev/vdb
  
   # Verify new size
   df -h /mnt/blockstore
  
   # Start Plex
   cd ~/plex-docker-setup
   docker-compose up -d
   ```

Note: The filesystem can be resized while mounted, no need to unmount/remount.

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

## Block Storage Operations

When performing block storage operations (detach, resize, reattach), SSH connections may be interrupted. Here's how to handle it:

1. If disconnected during detach:
   - Wait 30 seconds
   - Reconnect via SSH
   - Check Vultr dashboard to confirm detachment

2. If disconnected during reattach:
   - Wait 30 seconds
   - Reconnect via SSH
   - Run these commands to complete the process:
   ```bash
   # Resize filesystem (works while mounted)
   resize2fs /dev/vdb
  
   # Verify new size
   df -h /mnt/blockstore
  
   # Start Plex
   cd ~/plex-docker-setup
   docker-compose up -d
   ```

Note: The filesystem can be resized while mounted, no need to unmount/remount.

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

## Block Storage Operations

When performing block storage operations (detach, resize, reattach), SSH connections may be interrupted. Here's how to handle it:

1. If disconnected during detach:
   - Wait 30 seconds
   - Reconnect via SSH
   - Check Vultr dashboard to confirm detachment

2. If disconnected during reattach:
   - Wait 30 seconds
   - Reconnect via SSH
   - Run these commands to complete the process:
   ```bash
   # Resize filesystem (works while mounted)
   resize2fs /dev/vdb
  
   # Verify new size
   df -h /mnt/blockstore
  
   # Start Plex
   cd ~/plex-docker-setup
   docker-compose up -d
   ```

Note: The filesystem can be resized while mounted, no need to unmount/remount.

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

## Block Storage Operations

When performing block storage operations (detach, resize, reattach), SSH connections may be interrupted. Here's how to handle it:

1. If disconnected during detach:
   - Wait 30 seconds
   - Reconnect via SSH
   - Check Vultr dashboard to confirm detachment

2. If disconnected during reattach:
   - Wait 30 seconds
   - Reconnect via SSH
   - Run these commands to complete the process:
   ```bash
   # Resize filesystem (works while mounted)
   resize2fs /dev/vdb
  
   # Verify new size
   df -h /mnt/blockstore
  
   # Start Plex
   cd ~/plex-docker-setup
   docker-compose up -d
   ```

Note: The filesystem can be resized while mounted, no need to unmount/remount.

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

## Block Storage Operations

When performing block storage operations (detach, resize, reattach), SSH connections may be interrupted. Here's how to handle it:

1. If disconnected during detach:
   - Wait 30 seconds
   - Reconnect via SSH
   - Check Vultr dashboard to confirm detachment

2. If disconnected during reattach:
   - Wait 30 seconds
   - Reconnect via SSH
   - Run these commands to complete the process:
   ```bash
   # Resize filesystem (works while mounted)
   resize2fs /dev/vdb
  
   # Verify new size
   df -h /mnt/blockstore
  
   # Start Plex
   cd ~/plex-docker-setup
   docker-compose up -d
   ```

Note: The filesystem can be resized while mounted, no need to unmount/remount.

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

## Block Storage Operations

When performing block storage operations (detach, resize, reattach), SSH connections may be interrupted. Here's how to handle it:

1. If disconnected during detach:
   - Wait 30 seconds
   - Reconnect via SSH
   - Check Vultr dashboard to confirm detachment

2. If disconnected during reattach:
   - Wait 30 seconds
   - Reconnect via SSH
   - Run these commands to complete the process:
   ```bash
   # Resize filesystem (works while mounted)
   resize2fs /dev/vdb
  
   # Verify new size
   df -h /mnt/blockstore
  
   # Start Plex
   cd ~/plex-docker-setup
   docker-compose up -d
   ```

Note: The filesystem can be resized while mounted, no need to unmount/remount.

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

## Block Storage Operations

When performing block storage operations (detach, resize, reattach), SSH connections may be interrupted. Here's how to handle it:

1. If disconnected during detach:
   - Wait 30 seconds
   - Reconnect via SSH
   - Check Vultr dashboard to confirm detachment

2. If disconnected during reattach:
   - Wait 30 seconds
   - Reconnect via SSH
   - Run these commands to complete the process:
   ```bash
   # Resize filesystem (works while mounted)
   resize2fs /dev/vdb
  
   # Verify new size
   df -h /mnt/blockstore
  
   # Start Plex
   cd ~/plex-docker-setup
   docker-compose up -d
   ```

Note: The filesystem can be resized while mounted, no need to unmount/remount.

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

## Block Storage Operations

When performing block storage operations (detach, resize, reattach), SSH connections may be interrupted. Here's how to handle it:

1. If disconnected during detach:
   - Wait 30 seconds
   - Reconnect via SSH
   - Check Vultr dashboard to confirm detachment

2. If disconnected during reattach:
   - Wait 30 seconds
   - Reconnect via SSH
   - Run these commands to complete the process:
   ```bash
   # Resize filesystem (works while mounted)
   resize2fs /dev/vdb
  
   # Verify new size
   df -h /mnt/blockstore
  
   # Start Plex
   cd ~/plex-docker-setup
   docker-compose up -d
   ```

Note: The filesystem can be resized while mounted, no need to unmount/remount.

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

## Block Storage Operations

When performing block storage operations (detach, resize, reattach), SSH connections may be interrupted. Here's how to handle it:

1. If disconnected during detach:
   - Wait 30 seconds
   - Reconnect via SSH
   - Check Vultr dashboard to confirm detachment

2. If disconnected during reattach:
   - Wait 30 seconds
   - Reconnect via SSH
   - Run these commands to complete the process:
   ```bash
   # Resize filesystem (works while mounted)
   resize2fs /dev/vdb
  
   # Verify new size
   df -h /mnt/blockstore
  
   # Start Plex
   cd ~/plex-docker-setup
   docker-compose up -d
   ```

Note: The filesystem can be resized while mounted, no need to unmount/remount.

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

## Block Storage Operations

When performing block storage operations (detach, resize, reattach), SSH connections may be interrupted. Here's how to handle it:

1. If disconnected during detach:
   - Wait 30 seconds
   - Reconnect via SSH
   - Check Vultr dashboard to confirm detachment

2. If disconnected during reattach:
   - Wait 30 seconds
   - Reconnect via SSH
   - Run these commands to complete the process:
   ```bash
   # Resize filesystem (works while mounted)
   resize2fs /dev/vdb
  
   # Verify new size
   df -h /mnt/blockstore
  
   # Start Plex
   cd ~/plex-docker-setup
   docker-compose up -d
   ```

Note: The filesystem can be resized while mounted, no need to unmount/remount.

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

## Block Storage Operations

When performing block storage operations (detach, resize, reattach), SSH connections may be interrupted. Here's how to handle it:

1. If disconnected during detach:
   - Wait 30 seconds
   - Reconnect via SSH
   - Check Vultr dashboard to confirm detachment

2. If disconnected during reattach:
   - Wait 30 seconds
   - Reconnect via SSH
   - Run these commands to complete the process:
   ```bash
   # Resize filesystem (works while mounted)
   resize2fs /dev/vdb
  
   # Verify new size
   df -h /mnt/blockstore
  
   # Start Plex
   cd ~/plex-docker-setup
   docker-compose up -d
   ```

Note: The filesystem can be resized while mounted, no need to unmount/remount.

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

## Block Storage Operations

When performing block storage operations (detach, resize, reattach), SSH connections may be interrupted. Here's how to handle it:

1. If disconnected during detach:
   - Wait 30 seconds
   - Reconnect via SSH
   - Check Vultr dashboard to confirm detachment

2. If disconnected during reattach:
   - Wait 30 seconds
   - Reconnect via SSH
   - Run these commands to complete the process:
   ```bash
   # Resize filesystem (works while mounted)
   resize2fs /dev/vdb
  
   # Verify new size
   df -h /mnt/blockstore
  
   # Start Plex
   cd ~/plex-docker-setup
   docker-compose up -d
   ```

Note: The filesystem can be resized while mounted, no need to unmount/remount.

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

## Block Storage Operations

When performing block storage operations (detach, resize, reattach), SSH connections may be interrupted. Here's how to handle it:

1. If disconnected during detach:
   - Wait 30 seconds
   - Reconnect via SSH
   - Check Vultr dashboard to confirm detachment

2. If disconnected during reattach:
   - Wait 30 seconds
   - Reconnect via SSH
   - Run these commands to complete the process:
   ```bash
   # Resize filesystem (works while mounted)
   resize2fs /dev/vdb
  
   # Verify new size
   df -h /mnt/blockstore
  
   # Start Plex
   cd ~/plex-docker-setup
   docker-compose up -d
   ```

Note: The filesystem can be resized while mounted, no need to unmount/remount.

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

## Block Storage Operations

When performing block storage operations (detach, resize, reattach), SSH connections may be interrupted. Here's how to handle it:

1. If disconnected during detach:
   - Wait 30 seconds
   - Reconnect via SSH
   - Check Vultr dashboard to confirm detachment

2. If disconnected during reattach:
   - Wait 30 seconds
   - Reconnect via SSH
   - Run these commands to complete the process:
   ```bash
   # Resize filesystem (works while mounted)
   resize2fs /dev/vdb
  
   # Verify new size
   df -h /mnt/blockstore
  
   # Start Plex
   cd ~/plex-docker-setup
   docker-compose up -d
   ```

Note: The filesystem can be resized while mounted, no need to unmount/remount.

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

## Block Storage Operations

When performing block storage operations (detach, resize, reattach), SSH connections may be interrupted. Here's how to handle it:

1. If disconnected during detach:
   - Wait 30 seconds
   - Reconnect via SSH
   - Check Vultr dashboard to confirm detachment

2. If disconnected during reattach:
   - Wait 30 seconds
   - Reconnect via SSH
   - Run these commands to complete the process:
   ```bash
   # Resize filesystem (works while mounted)
   resize2fs /dev/vdb
  
   # Verify new size
   df -h /mnt/blockstore
  
   # Start Plex
   cd ~/plex-docker-setup
   docker-compose up -d
   ```

Note: The filesystem can be resized while mounted, no need to unmount/remount.
   ``` 