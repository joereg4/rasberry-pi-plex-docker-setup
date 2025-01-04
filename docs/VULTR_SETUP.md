# Vultr Setup Guide

## Initial Setup

### Install Vultr CLI
The setup script will automatically install Vultr CLI, but you can also install manually:
```bash
curl -fsSL https://raw.githubusercontent.com/vultr/vultr-cli/master/scripts/installer.sh | bash
```

### Configure Vultr CLI
```bash
# Create config directory
mkdir -p ~/.vultr-cli

# Add API key to config
echo "api-key: YOUR_API_KEY" > ~/.vultr-cli/config.yaml

# Verify configuration
vultr-cli account info
```

1. **Create API Key**:
   - Go to [Vultr API Settings](https://my.vultr.com/settings/#settingsapi)
   - Generate new API key
   - Add to `.env`: `VULTR_API_KEY=your-key`

2. **Create Block Storage**:
   ```bash
   # Using vultr-cli
   vultr-cli block-storage create \
     --region ewr \
     --size 100 \
     --attached-to your-instance-id
   ```
   - Note the Block ID
   - Add to `.env`: `VULTR_BLOCK_ID=your-block-id`

3. **Get Instance ID**:
   ```bash
   vultr-cli instance list
   ```
   - Add to `.env`: `VULTR_INSTANCE_ID=your-instance-id`

## Storage Management

### Manual Expansion
```bash
./scripts/manage_storage.sh expand
```

### Automatic Expansion
The system will automatically expand storage when usage exceeds 75%

### Monitoring
```bash
./scripts/manage_storage.sh check
```

## Cost Management

1. **Block Storage Pricing**:
   - $1/10GB/month
   - Billed hourly
   - Minimum size: 10GB
   - Maximum size: 10TB

2. **Expansion Strategy**:
   - Default increment: 100GB
   - Can be modified in script
   - Set alerts at 75% and 90%

## Best Practices

1. **API Security**:
   - Use restricted API keys
   - Regular key rotation
   - Never commit keys to git

2. **Cost Control**:
   - Monitor expansion logs
   - Set up billing alerts
   - Review usage patterns 