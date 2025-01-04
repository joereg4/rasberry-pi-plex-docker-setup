# Vultr Setup Guide

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
   - Note Instance ID

2. **SSH Access**:
   ```bash
   # Using password
   ssh root@YOUR_SERVER_IP

   # Or using SSH key
   ssh -i ~/.ssh/your_key root@YOUR_SERVER_IP
   ```

## 3. Run Setup Script
1. **Clone Repository**:
   ```bash
   git clone https://github.com/joereg4/plex-docker-setup.git
   cd plex-docker-setup
   ```

2. **Make Script Executable**:
   ```bash
   chmod +x scripts/setup.sh
   ```

3. **Run Setup**:
   ```bash
   ./scripts/setup.sh
   ```

## 4. Post-Setup
1. **Enable Auto Storage**:
   ```bash
   ./scripts/manage_storage.sh auto
   ```

2. **Verify Setup**:
   ```bash
   docker ps  # Check container status
   ./scripts/check_storage.sh  # Verify storage
   ```

## Optional: Block Storage
1. Create in same region as server
2. Start with 100GB (expandable)
3. Attach to your instance
4. Note Block Storage ID

## Next Steps
- Add media files
- Configure Plex settings
- Monitor storage usage
- Set up email notifications 