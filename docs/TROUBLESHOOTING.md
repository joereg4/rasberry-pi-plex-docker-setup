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
   docker compose exec plex ls -l /media
   ```

3. Scan library:
   - Plex Web -> Libraries -> Scan Library Files

### Container Issues

1. Check container status:
   ```bash
   docker ps
   docker compose logs plex
   ```

2. Verify environment:
   ```bash
   docker compose config
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

## Wi-Fi Issues

### Kernel Log Spam (brcmfmac errors)

If you see repeated errors in your kernel log like:
```
brcmfmac: brcmf_set_channel: set chanspec 0xd02e failed, reason -52
```

This is a known issue with the Raspberry Pi 5's Broadcom Wi-Fi driver, especially with 5GHz networks. The driver repeatedly fails to set the Wi-Fi channel, spamming the kernel log and potentially causing performance issues.

**Solution: Disable Wi-Fi (Recommended for Plex servers)**

Since Ethernet is faster and more reliable for a Plex server anyway, the best solution is to disable Wi-Fi entirely:

```bash
# Add to boot config to disable Wi-Fi at firmware level
echo 'dtoverlay=disable-wifi' | sudo tee -a /boot/firmware/config.txt

# Optional: Also disable Bluetooth if not needed
echo 'dtoverlay=disable-bt' | sudo tee -a /boot/firmware/config.txt

# Reboot for changes to take effect
sudo reboot
```

After reboot, verify Wi-Fi is disabled:
```bash
rfkill list      # Should not show "Wireless LAN"
ip link show     # Should not show "wlan0"
```

**If you need Wi-Fi working:**

1. Try using 2.4GHz instead of 5GHz (more compatible)
2. Ensure the correct country code is set:
   ```bash
   sudo raspi-config  # → Localisation → WLAN Country
   ```
3. Check if your router uses DFS channels (try disabling them)

**Why this happens:**
- The brcmfmac driver has regulatory domain issues
- 5GHz DFS channels require special handling
- Some router channel configurations aren't compatible

**Why Ethernet is better for Plex:**
- Gigabit speed (vs ~100Mbps Wi-Fi)
- More reliable for streaming
- Lower latency
- No driver issues

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