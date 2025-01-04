# Plex Docker Setup

Docker-based Plex Media Server setup with easy deployment options.

## Local Setup

1. Clone the repository:
   ```bash
   git clone https://github.com/joereg4/plex-docker-setup.git
   cd plex-docker-setup
   ```

2. Create environment file:
   ```bash
   cp .env.example .env
   ```

3. Update `.env` file:
   - Get your claim token from [plex.tv/claim](https://plex.tv/claim)
   - Set PLEX_HOST to `localhost`
   - Verify timezone is correct

4. Start Plex:
   ```bash
   docker-compose up -d
   ```

## Cloud Deployment

This setup can be deployed to any VPS provider. We recommend [Vultr](https://www.vultr.com/?ref=9448061) for their:
- Global network of data centers
- High-performance SSD servers
- Competitive pricing
- Simple setup process

1. SSH into your server:
   ```bash
   ssh root@YOUR_SERVER_IP
   ```

2. Run the setup script:
   ```bash
   curl -s https://raw.githubusercontent.com/joereg4/plex-docker-setup/main/scripts/setup.sh | bash
   ```

3. Update `.env` file:
   ```bash
   cd plex-docker-setup
   nano .env
   ```
   - Get a new claim token from [plex.tv/claim](https://plex.tv/claim)
   - Update PLEX_HOST to your server IP
   - Comment out the localhost line

4. Start Plex:
   ```bash
   docker-compose up -d
   ```

## Security Recommendations

Basic security measures for your server:
- Use SSH key authentication (strongly recommended)
- Enable basic firewall rules
- Keep system and Docker images updated
- Use strong passwords

For detailed security setup, see [SECURITY.md](docs/SECURITY.md)

## Troubleshooting

Common issues and solutions are documented in [TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md)

## Custom Domain Setup

If you want to use a custom domain (e.g., plex.yourdomain.com):

1. Add DNS record:
   - Create an A record pointing to your server IP
   - Example: `plex.yourdomain.com -> YOUR_SERVER_IP`
   - For Cloudflare users, see [DOMAIN_SETUP.md](docs/DOMAIN_SETUP.md)

2. Update `.env`:
   ```bash
   PLEX_HOST=plex.yourdomain.com
   ```

Note: For security reasons, it's recommended to:
- Use HTTPS (Plex handles this automatically)
- Keep your server updated
- Use strong passwords
- Configure your firewall appropriately

## Directory Structure

```
/opt/plex/
├── config/    # Plex configuration
└── media/     # Media files

# When using block storage
/mnt/blockstore/
└── plex/
    └── media/     # Media files on block storage
```

## Environment Variables

- `PLEX_CLAIM`: Your Plex claim token (get from plex.tv/claim)
- `PLEX_HOST`: Server IP/hostname or custom domain
- `TZ`: Timezone (default: America/Chicago)

## Storage Management

Monitor and optimize your Plex storage:

```bash
# Check storage usage
./scripts/check_storage.sh

# Find optimization opportunities
./scripts/optimize_media.sh

# Monitor all storage types
./scripts/monitor_storage.sh

# Migrate between storage types
./scripts/migrate_storage.sh to-block    # Move to block storage
./scripts/migrate_storage.sh to-local    # Move to local storage
```

The scripts will help you:
- Track storage usage
- Identify large files
- Find optimization candidates
- Monitor metadata growth
- Migrate between storage types
- Monitor storage health

### Block Storage vs Local Storage

**Local Storage**:
- Included with your instance
- Better performance
- Fixed size

**Block Storage**:
- Can be expanded as needed
- Movable between instances
- Additional cost ($1/10GB/month)
- Slightly lower performance

Choose block storage if you:
- Need flexible storage sizing
- Plan to upgrade/migrate servers
- Want to separate media from system

## Security Note

This is a public repository. Never commit sensitive information like:
- Claim tokens
- Passwords
- API keys
- Server IPs

## Contributing

Feel free to open issues or submit pull requests! 

## Server Requirements

### Network Configuration

#### IPv6 (Recommended)
- Enable IPv6 during Vultr instance creation
- Use IPv6 address in `.env` configuration
- Better future-proofing
- Often better performance on modern networks

#### IPv4 (Alternative)
- Still fully supported
- Use IPv4 address in `.env` configuration
- Might be required for some legacy networks

Configure in `.env`:
```bash
# For IPv6
PLEX_HOST=YOUR_IPV6_ADDRESS

# For IPv4
PLEX_HOST=YOUR_IPV4_ADDRESS
```

Both address types will work with the setup script and Plex server.
Choose based on your network requirements and preferences. 