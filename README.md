# Plex Docker Setup for Raspberry Pi 5

A streamlined Docker setup for Plex Media Server optimized for Raspberry Pi 5 with USB storage support.

## Features

- Docker-based Plex Media Server
- USB storage support for media files (Samsung USB drive)
- Automated setup script with USB device detection
- Proper permissions handling
- Easy updates and maintenance
- Optimized for ARM64 architecture

## Prerequisites

- Raspberry Pi 5 (16GB RAM recommended)
- Ubuntu 22.04 LTS ARM64
- Docker installed (or will be installed by script)
- Git installed
- Samsung USB drive (2TB recommended) connected

## Quick Start

> **New to Raspberry Pi?** Start with the [Getting Started Guide](docs/GETTING_STARTED.md) for complete instructions from unboxing to running Plex.

If you already have Ubuntu 22.04 LTS installed on your Raspberry Pi 5:

1. **Connect USB Drive**
   - Connect your Samsung USB drive to the Raspberry Pi 5
   - Verify it's detected: `lsblk`

2. **Clone & Setup**
   ```bash
   git clone https://github.com/joereg4/rasberry-pi-plex-docker-setup.git
   cd rasberry-pi-plex-docker-setup
   chmod +x scripts/setup/*.sh
   sudo ./scripts/setup/setup_plex.sh
   ```
   The script will:
   - Detect your USB drive automatically
   - Offer to format and mount if needed
   - Set up all required directories
   - Configure Plex with proper permissions

3. **Configure Plex**
   - Access Plex at `http://YOUR_SERVER_IP:32400/web`
   - Sign in with your Plex account
   - Add libraries using these paths:
     * Movies: `/data/Movies`
     * TV Shows: `/data/TV Shows`
     * Music: `/data/Music`
     * Photos: `/data/Photos`

## Documentation

- [Getting Started](docs/GETTING_STARTED.md) - **Start here!** Complete guide from unboxing to running Plex
- [Setup Guide](docs/SETUP.md) - Detailed installation instructions
- [Domain Setup](docs/DOMAIN_SETUP.md) - Configure custom domain
- [Troubleshooting](docs/TROUBLESHOOTING.md) - Common issues and solutions

## Directory Structure

```
/mnt/blockstore/plex/media/  # Media storage (on USB drive)
├── Movies
├── TV Shows
├── Music
└── Photos

/opt/plex/  # Plex configuration (on microSD)
├── database
└── transcode
```

**Note**: Media files are stored on the USB drive for better performance and capacity, while Plex configuration stays on the microSD card.

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