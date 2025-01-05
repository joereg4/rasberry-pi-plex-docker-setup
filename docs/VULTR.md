# Vultr Configuration Guide

## Prerequisites
- Vultr API Key
- Instance created and running
- Block storage attached

## Configuration Steps
1. **Install Vultr CLI**:
   ```bash
   ./scripts/configure_vultr.sh
   # Choose option 1
   ```

2. **Configure API**:
   ```bash
   # Choose option 2
   # Enter your API key when prompted
   ```

3. **Configure Instance/Storage**:
   ```bash
   # Choose option 3
   # Select from available instances and storage
   ```

4. **Or Do All Steps**:
   ```bash
   # Choose option 4 for guided setup
   ```

## Available Resources
- Lists instances by Label and ID
- Shows block storage volumes
- Validates all IDs before saving

## Environment Variables
- VULTR_API_KEY
- VULTR_INSTANCE_ID
- VULTR_BLOCK_ID

All stored in .env file 