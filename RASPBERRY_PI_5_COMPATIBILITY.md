# Raspberry Pi 5 Setup and Script Compatibility Analysis

*Created: January 14, 2025*

## Overview

This document analyzes the compatibility of the existing Ubuntu-based Plex Docker setup script with Raspberry Pi 5 hardware (16GB RAM + 2TB USB SSD). The original script was designed for VPS deployments and needs assessment for ARM64 architecture and different storage configurations.

## Hardware Specifications

### Target Raspberry Pi 5 Setup
- **CPU**: ARM Cortex-A76 quad-core 64-bit
- **RAM**: 16GB LPDDR4X
- **Storage**: 2TB SSD via USB (USB-C or USB-A)
- **OS**: Ubuntu 22.04 LTS ARM64
- **Architecture**: ARM64 (aarch64)

### Original VPS Setup
- **CPU**: x86_64 architecture
- **Storage**: Block storage devices (`/dev/vdb`, `/dev/vdc`)
- **Hardware**: Intel Quick Sync for transcoding

## Compatibility Analysis

### ✅ **Components That Will Work**

1. **Docker Installation**
   - `apt-get install docker.io docker-compose` works on ARM64
   - Docker Compose syntax is architecture-agnostic
   - Plex Docker image supports ARM64 architecture

2. **Basic System Setup**
   - User creation and permissions
   - Directory structure creation
   - Environment variable configuration
   - Firewall (UFW) configuration

3. **Plex Configuration**
   - Media library paths
   - Database and transcode directories
   - Network port configuration (32400)

### ⚠️ **Components Requiring Modification**

1. **Storage Device Detection**
   ```bash
   # Current (VPS block storage)
   BLOCK_DEVICE="/dev/vdc"
   
   # Needed for Pi 5 (USB SSD)
   BLOCK_DEVICE="/dev/sda"  # or /dev/sdb, /dev/sdc, etc.
   ```

2. **Hardware Transcoding**
   ```yaml
   # Current (Intel Quick Sync)
   devices:
     - /dev/dri:/dev/dri
   
   # Pi 5 (VideoCore VII GPU)
   # May need different configuration or removal
   ```

3. **Performance Optimizations**
   - ARM64-specific Docker image tags
   - Pi 5 GPU acceleration settings
   - USB storage performance tuning

### ❌ **Components That Won't Work**

1. **Intel Quick Sync Hardware Transcoding**
   - Pi 5 uses VideoCore VII GPU
   - Different transcoding capabilities
   - May need software transcoding fallback

2. **x86_64 Specific Optimizations**
   - Any CPU-specific flags
   - Intel-specific hardware detection

## USB Connection Analysis

### USB-C vs USB-A

| Feature | USB-C | USB-A |
|---------|-------|-------|
| **Speed** | Up to 10 Gbps (USB 3.2 Gen 2) | Up to 5 Gbps (USB 3.0) |
| **Power Delivery** | Yes (up to 100W) | Limited |
| **Reliability** | Better connection stability | Good |
| **Compatibility** | Modern standard | Universal |
| **Recommendation** | **Preferred** | Acceptable |

### Storage Performance Considerations

- **USB 3.0/3.1**: Sufficient for 4K media streaming
- **USB-C**: Better for sustained high-bandwidth operations
- **SSD vs HDD**: SSD recommended for better random access

## Required Modifications

### 1. Storage Detection Script Update

```bash
# Current script logic
if [ -b "/dev/vdc" ]; then
    BLOCK_DEVICE="/dev/vdc"
elif [ -b "/dev/vdb" ]; then
    BLOCK_DEVICE="/dev/vdb"
fi

# Updated for Pi 5
detect_usb_storage() {
    for device in /dev/sda /dev/sdb /dev/sdc /dev/sdd; do
        if [ -b "$device" ]; then
            # Check if it's a USB device
            if udevadm info --query=property --name="$device" | grep -q "ID_BUS=usb"; then
                BLOCK_DEVICE="$device"
                return 0
            fi
        fi
    done
    return 1
}
```

### 2. Docker Compose Modifications

```yaml
# Remove or modify hardware transcoding
services:
  plex:
    image: plexinc/pms-docker:latest
    # Remove: devices: - /dev/dri:/dev/dri
    # Add Pi 5 specific optimizations
    environment:
      - PLEX_CLAIM=${PLEX_CLAIM}
      - TZ=${TIMEZONE}
      # Add ARM64 specific variables if needed
```

### 3. Performance Tuning

```bash
# Add Pi 5 specific optimizations
echo "vm.swappiness=10" >> /etc/sysctl.conf
echo "vm.vfs_cache_pressure=50" >> /etc/sysctl.conf

# USB storage optimization
echo 'ACTION=="add", SUBSYSTEM=="usb", ATTR{idVendor}=="*", ATTR{idProduct}=="*", RUN+="/bin/sh -c 'echo noop > /sys/block/%k/queue/scheduler'"' > /etc/udev/rules.d/60-usb-storage.rules
```

## Implementation Options

### Option 1: Modify Existing Script (Recommended)

**Pros:**
- Leverage existing tested code
- Maintain consistency with original setup
- Faster implementation

**Cons:**
- May have legacy VPS-specific code
- Less optimized for Pi 5 hardware

**Implementation Steps:**
1. Fork current repository
2. Create Pi 5 branch
3. Update storage detection logic
4. Remove/modify hardware transcoding
5. Add ARM64 optimizations
6. Test on Pi 5 hardware

### Option 2: Create New Pi-Specific Repository

**Pros:**
- Clean, optimized codebase
- Pi 5 specific features
- Better performance tuning

**Cons:**
- More development time
- Need to maintain separate codebase
- Potential feature divergence

**Implementation Steps:**
1. Create new repository
2. Port essential functionality
3. Add Pi 5 specific optimizations
4. Include Pi-specific documentation
5. Test thoroughly on hardware

## Testing Strategy

### Phase 1: Basic Compatibility
- [ ] Test Docker installation on Pi 5
- [ ] Verify Plex Docker image compatibility
- [ ] Test basic script execution

### Phase 2: Storage Integration
- [ ] Test USB SSD detection
- [ ] Verify filesystem creation
- [ ] Test media directory setup

### Phase 3: Performance Testing
- [ ] Benchmark transcoding performance
- [ ] Test concurrent stream handling
- [ ] Monitor resource usage

### Phase 4: Production Readiness
- [ ] Long-term stability testing
- [ ] Update mechanism testing
- [ ] Backup/restore procedures

## Recommended Next Steps

1. **Immediate Actions:**
   - [ ] Test current script on Pi 5 (identify breaking points)
   - [ ] Document specific error messages
   - [ ] Assess storage detection issues

2. **Short-term (1-2 weeks):**
   - [ ] Create Pi 5 compatibility branch
   - [ ] Implement storage detection fixes
   - [ ] Remove hardware transcoding dependencies

3. **Medium-term (1 month):**
   - [ ] Add Pi 5 specific optimizations
   - [ ] Create comprehensive testing suite
   - [ ] Document Pi 5 specific setup procedures

4. **Long-term (ongoing):**
   - [ ] Monitor Pi 5 specific issues
   - [ ] Optimize for ARM64 performance
   - [ ] Maintain compatibility with Pi OS updates

## Risk Assessment

### Low Risk
- Basic Docker functionality
- Plex media server operation
- Network configuration

### Medium Risk
- Storage performance optimization
- Hardware transcoding alternatives
- USB connection stability

### High Risk
- ARM64 specific performance issues
- VideoCore VII GPU utilization
- Long-term hardware compatibility

## Conclusion

The existing script has **good compatibility** with Raspberry Pi 5, requiring **moderate modifications** primarily around storage detection and hardware transcoding. The **recommended approach** is to modify the existing script rather than create a new repository, as most functionality will work with minimal changes.

**Key Success Factors:**
- Proper USB storage detection
- ARM64 optimized Docker configuration
- Appropriate transcoding settings for VideoCore VII
- USB-C connection for optimal performance

---

*This analysis is based on the current script structure and Raspberry Pi 5 specifications. Actual implementation may require additional modifications based on testing results.*
