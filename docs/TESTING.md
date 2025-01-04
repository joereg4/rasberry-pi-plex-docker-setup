# Testing Environment Guide

## Quick Start

```bash
# In your Plex directory
cd ~/Plex

# Create test management script
./manage_test.sh setup

# Enter test container
docker exec -it plex-setup-test bash

# Run setup script inside container
./scripts/setup.sh
```

## Test Management Commands

```bash
# Create fresh test environment
./manage_test.sh setup

# Clean up test environment
./manage_test.sh clean

# Update test files from main project
./manage_test.sh update

# Restart test environment (clean + setup)
./manage_test.sh restart
```

## Test Environment Structure

```
plex-test/
├── Dockerfile          # Ubuntu test container
├── docker-compose.test.yml
├── scripts/           # Copied from main project
├── docs/             # Documentation
└── .env.example      # Environment template
```

## Testing Different Scenarios

1. **Fresh Installation**:
   ```bash
   ./manage_test.sh restart
   docker exec -it plex-setup-test bash
   ./scripts/setup.sh
   ```

2. **Configuration Updates**:
   ```bash
   ./manage_test.sh update
   docker exec -it plex-setup-test bash
   ```

3. **Storage Management**:
   ```bash
   # Inside container
   ./scripts/manage_storage.sh check
   ./scripts/optimize_media.sh
   ```

## Best Practices

1. Always test in container before deploying
2. Use `manage_test.sh update` after local changes
3. Test all configuration options
4. Verify script permissions after updates

## Troubleshooting

1. **Permission Issues**:
   ```bash
   chmod +x scripts/*.sh
   ```

2. **Container Access**:
   ```bash
   # Check container status
   docker ps
   
   # Restart if needed
   docker-compose -f docker-compose.test.yml restart
   ```

3. **Clean Start**:
   ```bash
   ./manage_test.sh restart
   ``` 