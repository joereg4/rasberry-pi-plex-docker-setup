# Setup Guide

## Prerequisites
- Docker installed
- Git installed
- Access to Vultr account (optional)
- Gmail account for notifications (optional)

## Initial Setup
1. **Clone Repository**:
   ```bash
   git clone https://github.com/joereg4/plex-docker-setup.git
   cd plex-docker-setup
   ```

2. **Environment Configuration**:
   - Copy example environment file:
     ```bash
     cp .env.example .env
     ```
   - Get Plex claim token from https://plex.tv/claim
   - Configure Gmail app password if using notifications
   - Set up Vultr API key if using Vultr

3. **Testing Environment** (Optional):
   ```bash
   # Setup test environment
   ./manage_test.sh setup
   
   # Enter test container
   docker exec -it plex-setup-test bash
   
   # Run setup script
   ./scripts/setup.sh
   ```

4. **Production Setup**:
   ```bash
   # Make scripts executable
   chmod +x scripts/*.sh
   
   # Run setup
   ./scripts/setup.sh
   
   # Start Plex
   docker-compose up -d
   ```

## Configuration Options

### Email Notifications
1. Enable Gmail 2FA
2. Create app password
3. Update .env with Gmail settings

### Storage Configuration
1. Choose storage type (see STORAGE_DECISION.md)
2. Configure paths in docker-compose.yml
3. Run storage checks

### Vultr Integration
1. Generate API key
2. Configure block storage
3. Update instance settings

## Verification Steps
1. Check Plex access
2. Verify storage mounts
3. Test email notifications
4. Validate Vultr configuration

## Maintenance
1. Regular updates
2. Storage monitoring
3. Log rotation
4. Backup strategy 