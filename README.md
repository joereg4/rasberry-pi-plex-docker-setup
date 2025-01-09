# Plex Docker Setup

A streamlined Docker setup for Plex Media Server with block storage support.

## Features

- Docker-based Plex Media Server
- Block storage support for media files
- Automated setup script
- Proper permissions handling
- Easy updates and maintenance

## Prerequisites

- Ubuntu 22.04 LTS
- Docker installed
- Git installed
- Block storage attached to server

## Quick Start

1. **Prepare Block Storage**
   ```bash
   # Check your block storage device
   lsblk
   ```
   Look for your block storage (usually `/dev/vdc` on Vultr)

2. **Clone & Setup**
   ```bash
   git clone https://github.com/joereg4/plex-docker-setup.git
   cd plex-docker-setup
   chmod +x scripts/setup/*.sh
   sudo ./scripts/setup/setup_plex.sh
   ```

3. **Configure Plex**
   - Access Plex at `http://YOUR_SERVER_IP:32400/web`
   - Sign in with your Plex account
   - Add libraries using these paths:
     * Movies: `/data/Movies`
     * TV Shows: `/data/TV Shows`
     * Music: `/data/Music`
     * Photos: `/data/Photos`

## Documentation

- [Setup Guide](docs/SETUP.md) - Detailed installation instructions
- [Domain Setup](docs/DOMAIN_SETUP.md) - Configure custom domain
- [Troubleshooting](docs/TROUBLESHOOTING.md) - Common issues and solutions

## Directory Structure

```
/mnt/blockstore/plex/media/  # Media storage
├── Movies
├── TV Shows
├── Music
└── Photos

/opt/plex/  # Plex configuration
├── database
└── transcode
```

## Maintenance

- **Update Plex**: `docker-compose pull && docker-compose up -d`
- **Check Logs**: `docker-compose logs plex`
- **Restart Plex**: `docker-compose restart plex`

## Contributing

Contributions are welcome! Please read our [Contributing Guide](CONTRIBUTING.md).

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Support

If you encounter any issues:
1. Check the [Troubleshooting Guide](docs/TROUBLESHOOTING.md)
2. Open an issue on GitHub
3. Provide logs and system information 