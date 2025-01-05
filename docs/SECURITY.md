# Security Setup Guide

## SSH Key Authentication

1. On your local machine:
   ```bash
   # Generate SSH key if you don't have one
   ssh-keygen -t ed25519 -C "your_email@example.com"
   
   # Copy public key to server
   ssh-copy-id root@YOUR_SERVER_IP
   ```

2. Disable password authentication:
   ```bash
   # Edit SSH config
   nano /etc/ssh/sshd_config
   ```
   Set:
   ```
   PasswordAuthentication no
   ```

## Firewall Setup (UFW)

```bash
# Install UFW
apt install ufw

# Set default policies
ufw default deny incoming
ufw default allow outgoing

# Allow SSH (before enabling UFW!)
ufw allow ssh

# Allow Plex ports
ufw allow 32400/tcp  # Plex main port
ufw allow 32469/tcp  # Plex DLNA
ufw allow 1900/udp   # Plex DLNA discovery
ufw allow 32410:32414/udp  # Plex media streaming

# Enable UFW
ufw enable
```

## Regular Maintenance

1. System Updates:
   ```bash
   # Update system packages
   apt update && apt upgrade -y
   
   # Update Docker images
   docker-compose pull
   docker-compose up -d
   ```

2. Backup Strategy:
   - Regular config backups
   - Database backups
   - Keep .env file secure 

# Security Considerations

## API Keys
- Vultr API key stored in .env
- File permissions should be restricted
- Never commit .env to repository

## Email Security
- Gmail App Password used instead of account password
- Stored in .env file
- Limited to email notifications only

## File Permissions
```bash
# Set correct permissions
chmod 600 .env
chmod +x scripts/*.sh
```

## Environment Variables
- All sensitive data in .env
- Loaded only when needed
- Validated before use

## Best Practices
1. Keep .env secure
2. Don't share API keys
3. Regular security updates
4. Rotate API keys periodically
5. Monitor access logs 