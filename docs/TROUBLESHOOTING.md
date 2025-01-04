# Troubleshooting Guide

## Common Issues

### Remote Access Not Working

1. Check firewall settings:
   ```bash
   ufw status
   ```

2. Verify port forwarding:
   - Ensure port 32400 is forwarded to your server
   - Check Plex settings -> Remote Access

3. Domain issues:
   - Verify DNS records
   - Check PLEX_HOST in .env

### Media Not Showing Up

1. Check permissions:
   ```bash
   ls -l /opt/plex/media
   ```

2. Verify mount points:
   ```bash
   docker-compose exec plex ls -l /media
   ```

3. Scan library:
   - Plex Web -> Libraries -> Scan Library Files

### Container Issues

1. Check container status:
   ```bash
   docker ps
   docker-compose logs plex
   ```

2. Verify environment:
   ```bash
   docker-compose config
   ```

### Performance Issues

1. Check system resources:
   ```bash
   htop
   docker stats
   ```

2. Monitor transcoding:
   - Plex Dashboard -> Now Playing
   - Check CPU usage during playback

## Migration Issues

1. Backup before migration:
   ```bash
   tar -czf plex-config-backup.tar.gz /opt/plex/config
   ```

2. Restore after migration:
   ```bash
   tar xzf plex-config-backup.tar.gz -C /opt/plex/config
   chown -R 1000:1000 /opt/plex/config
   ``` 