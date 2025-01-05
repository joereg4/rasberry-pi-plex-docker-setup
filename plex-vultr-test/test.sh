#!/bin/bash
echo "=== Testing Vultr CLI ==="
echo "Setting up API key..."
echo "api-key: $VULTR_API_KEY" > ~/.vultr-cli/config.yaml
echo "Testing connection..."
vultr-cli account info
