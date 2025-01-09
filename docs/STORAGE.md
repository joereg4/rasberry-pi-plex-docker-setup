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

The script will:
- Monitor storage usage
- Automatically expand when usage > 75%
- Grow filesystem after expansion
- Log all operations

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

## Block Storage Operations

Block storage is managed using the Vultr API directly.

### Storage Expansion Process

When storage usage exceeds the critical threshold (90%), the system will:

1. Stop Plex container
2. Unmount block storage
3. Use Vultr API to:
   - Detach storage: `POST /v2/blocks/{block-id}/detach`
   - Resize volume: `PATCH /v2/blocks/{block-id}`
   - Reattach storage: `POST /v2/blocks/{block-id}/attach`
4. Resize filesystem
5. Remount storage
6. Restart Plex container

### API Endpoints Used

```bash
# List block storage volumes
GET https://api.vultr.com/v2/blocks

# Get block storage details
GET https://api.vultr.com/v2/blocks/{block-id}

# Detach block storage
POST https://api.vultr.com/v2/blocks/{block-id}/detach

# Resize block storage
PATCH https://api.vultr.com/v2/blocks/{block-id}
{
  "size_gb": new_size
}

# Attach block storage
POST https://api.vultr.com/v2/blocks/{block-id}/attach
{
  "instance_id": "instance-id"
}
```

### Error Handling

The system will:
- Check API response codes and error messages
- Ensure device is available after reattachment
- Verify filesystem resize
- Confirm mount is successful 