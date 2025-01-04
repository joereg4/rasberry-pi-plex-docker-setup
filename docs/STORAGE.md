# Storage Management Guide

## Storage Types

### Local Storage
- System SSD/NVMe storage
- Included with your instance
- Located at `/opt/plex/media`
- Better performance for streaming

### Block Storage
- Attachable volume storage
- Pay per GB ($1/10GB/month)
- Located at `/mnt/blockstore/plex/media`
- More flexible for growth

## Storage Commands

### Monitor Storage
```bash
# Check all storage
./scripts/monitor_storage.sh

# View specific details
df -h /opt/plex/media          # Local storage
df -h /mnt/blockstore          # Block storage
```

### Migrate Storage
```bash
# To block storage
./scripts/migrate_storage.sh to-block

# To local storage
./scripts/migrate_storage.sh to-local
```

### Automated Storage Management
```bash
# Check storage status
./scripts/manage_storage.sh check

# Manually expand block storage
./scripts/manage_storage.sh expand

# Auto-expand if needed
./scripts/manage_storage.sh auto
```

### Storage Health
```bash
# Check storage health
smartctl -H /dev/sdb           # Block storage
smartctl -H /dev/sda           # System drive
```

## Best Practices

1. **Regular Monitoring**:
   - Check storage usage daily
   - Monitor IO performance
   - Watch for health issues

2. **Migration Safety**:
   - Always verify space before migration
   - Keep backups during migration
   - Test after migration

3. **Performance Tips**:
   - Use local storage for frequently accessed media
   - Consider block storage for archives
   - Monitor IO stats for bottlenecks 