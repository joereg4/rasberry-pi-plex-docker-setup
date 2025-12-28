# Domain Setup Guide

## DNS Configuration

1. Access your DNS provider's control panel (Cloudflare, Namecheap, GoDaddy, etc.)
2. Create DNS record:
   - Type: A
   - Name: plex (or your subdomain)
   - Content: YOUR_SERVER_IP
   - TTL: Automatic or 3600
   - If using Cloudflare: Set to DNS only (Gray cloud)

## Environment Configuration

Update your `.env` file:
```bash
PLEX_HOST=plex.yourdomain.com
```

## SSL/Security Settings

1. SSL/TLS:
   - Plex handles its own SSL certificates
   - No additional SSL configuration needed
   - If using Cloudflare, set SSL/TLS encryption mode to "Full"

2. DNS Provider Settings:
   - Do not enable proxy/CDN features for Plex
   - Direct connection is required for optimal performance

## Verifying Setup

1. DNS Propagation:
   ```bash
   # Check if DNS is resolving
   dig plex.yourdomain.com
   
   # Test connection
   curl -I https://plex.yourdomain.com:32400/web
   ```

2. Plex Connection:
   - Open https://plex.yourdomain.com:32400/web
   - Check Settings -> Remote Access
   - Verify "Fully accessible outside your network"

3. SSL Certificate:
   - Click the padlock in your browser
   - Verify certificate is issued by Plex

## Troubleshooting

### Common Issues

1. DNS Not Resolving:
   ```bash
   # Check DNS propagation
   dig plex.yourdomain.com
   
   # Check from different location
   nslookup plex.yourdomain.com 8.8.8.8
   ```

2. Cannot Access Plex:
   - Verify firewall allows port 32400
   ```bash
   # Check firewall status
   ufw status
   
   # Test port connectivity
   nc -zv plex.yourdomain.com 32400
   ```

3. SSL Certificate Issues:
   - Clear browser cache
   - Wait up to 15 minutes for Plex to issue certificate
   - Verify PLEX_HOST is correct in .env

4. Remote Access Issues:
   - Check Plex Settings -> Remote Access
   - Verify no proxy/CDN is between server and internet
   - Test direct IP access first: http://YOUR_SERVER_IP:32400/web

### Quick Fixes

1. Domain Issues:
   ```bash
   # Restart Plex container
   docker compose restart plex
   
   # Check logs
   docker compose logs plex
   ```

2. Reset DNS Cache:
   ```bash
   # On macOS
   sudo dscacheutil -flushcache; sudo killall -HUP mDNSResponder
   
   # On Linux
   sudo systemd-resolve --flush-caches
   ```

## Best Practices

1. Use a dedicated subdomain for Plex
2. Allow direct connections (no proxy)
3. Keep DNS TTL low during initial setup
4. Document your DNS settings

Need more help? Check [TROUBLESHOOTING.md](TROUBLESHOOTING.md) for general issues. 