# Vultr Setup Guide

## Overview
Vultr configuration is optional and can be done separately from the main setup.
You can configure Vultr either during initial setup or later using the dedicated script.

## 1. Server Creation
1. **Choose Server Type**:
   - Regular Cloud Compute
   - 4 vCPU
   - 8 GB RAM
   - 160 GB SSD

2. **Server Location**:
   - Choose nearest datacenter
   - Note: Block storage must be in same location

3. **Server Image**:
   - Select Ubuntu 22.04 x64 LTS

4. **Network Options**:
   - Enable IPv6 (recommended)
   - Enable VPC Network

5. **SSH Keys**:
   - Add your SSH key
   - Or note the root password

## 2. Initial Access
1. **Get Server Details**:
   - Note IPv4/IPv6 addresses
   ```bash
   # Get server IP address (any of these methods)
   hostname -I
   ip addr show
   curl ifconfig.me
   ```
   - Note Instance ID (UUID from URL: .../instance/id=xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx)

2. **SSH Access**:
   ```bash
   # Using password
   ssh root@YOUR_SERVER_IP

   # Or using SSH key
   ssh -i ~/.ssh/your_key root@YOUR_SERVER_IP
   ```

3. **Setup Repository**:
   ```bash
   # Clone repository
   git clone https://github.com/joereg4/plex-docker-setup.git
   cd plex-docker-setup
   
   # Make scripts executable
   chmod +x scripts/*.sh
   ```

## 3. Configure Vultr
You have two options to configure Vultr:

### Option 0: Manual CLI Installation
```bash
# Install Go 1.20+
wget https://go.dev/dl/go1.20.14.linux-amd64.tar.gz
rm -rf /usr/local/go && tar -C /usr/local -xzf go1.20.14.linux-amd64.tar.gz
export PATH=$PATH:/usr/local/go/bin
rm go1.20.14.linux-amd64.tar.gz

# Setup Go workspace
mkdir -p ~/go/{bin,pkg,src}
export GOPATH=$HOME/go
export PATH=$PATH:$GOPATH/bin
export GO111MODULE=on

# Install Vultr CLI
go install github.com/vultr/vultr-cli/v3@v3.3.0

# Verify installation
vultr-cli version
```

### Option 1: Using Configuration Script
```bash
# Run Vultr configuration separately
./scripts/configure_vultr.sh
```

The configuration script provides these options:
1. Install Vultr CLI
2. Configure Vultr API
3. Configure Instance/Storage
4. Do all steps
5. Exit

## 4. Post-Setup
1. **Enable Auto Storage**:
   ```bash
   ./scripts/manage_storage.sh auto
   ```

2. **Verify Setup**:
   ```bash
   docker ps  # Check container status
   ./scripts/storage/check_storage.sh  # Verify storage
   ```

## Optional: Block Storage
1. Create in same region as server
2. Start with 100GB (expandable)
3. Attach to your instance
4. Note Block Storage ID (UUID from URL: .../block-storage/id=xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx)

## Next Steps
- Add media files
- Configure Plex settings
- Monitor storage usage
- Set up email notifications 

## Setup Process

### Order of Setup
1. First, set up Plex:
   ```bash
   ./scripts/setup_plex.sh
   ```

2. Then configure email (optional):
   ```bash
   ./scripts/setup_email.sh
   ```

3. Finally, configure Vultr:
   ```bash
   ./scripts/configure_vultr.sh
   ```

Each script can be run independently, but they should be run in this order. 

## Configuration

## Testing
To test Vultr configuration:
```bash
# 1. Start test environment
./manage_test.sh rebuild

# 2. Inside container
cd /plex-docker-setup
./scripts/configure_vultr.sh

# 3. Verify configuration
vultr-cli account info
vultr-cli instance list
vultr-cli block-storage list
```

## Troubleshooting 