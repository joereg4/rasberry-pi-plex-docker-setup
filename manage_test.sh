#!/bin/bash

# Source .env
set -a
source .env
set +a

echo "=== Block Storage Expansion Test ==="

# 1. Check current size
echo -e "\nInitial size:"
df -h /mnt/blockstore

# 2. Detach block storage
echo -e "\nDetaching block storage..."
curl -s -X POST \
    -H "Authorization: Bearer ${VULTR_API_KEY}" \
    "https://api.vultr.com/v2/blocks/${VULTR_BLOCK_ID}/detach"

echo "Waiting for detachment (30s)..."
sleep 30

# 3. Resize to 150GB
echo -e "\nResizing to 150GB..."
curl -s -X PATCH \
    -H "Authorization: Bearer ${VULTR_API_KEY}" \
    -H "Content-Type: application/json" \
    -d '{"size_gb": 150}' \
    "https://api.vultr.com/v2/blocks/${VULTR_BLOCK_ID}"

echo "Waiting for resize (30s)..."
sleep 30

# 4. Reattach
echo -e "\nReattaching block storage..."
curl -s -X POST \
    -H "Authorization: Bearer ${VULTR_API_KEY}" \
    -H "Content-Type: application/json" \
    -d "{\"instance_id\":\"${VULTR_INSTANCE_ID}\"}" \
    "https://api.vultr.com/v2/blocks/${VULTR_BLOCK_ID}/attach"

echo "Waiting for reattachment (30s)..."
sleep 30

# 5. Resize filesystem
echo -e "\nResizing filesystem..."
resize2fs /dev/vdb

# 6. Verify
echo -e "\nNew size:"
df -h /mnt/blockstore