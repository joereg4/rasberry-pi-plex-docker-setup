#!/bin/bash

# Source common functions
source "$(dirname "$0")/common.sh"

# Mock Vultr API responses
mock_account_info() {
    cat << EOF
{
    "account": {
        "name": "Test Account",
        "email": "test@example.com",
        "balance": -5.00
    }
}
EOF
}

mock_instance_list() {
    cat << EOF
{
    "instances": [{
        "id": "test_instance",
        "label": "plex-test",
        "status": "active"
    }]
}
EOF
}

mock_block_storage() {
    cat << EOF
{
    "blocks": [{
        "id": "test_block",
        "size_gb": 100,
        "status": "active"
    }]
}
EOF
}

# Handle mock API calls
case "$1" in
    "account")
        mock_account_info
        ;;
    "instance")
        mock_instance_list
        ;;
    "block")
        mock_block_storage
        ;;
    *)
        echo "Unknown mock API call"
        exit 1
        ;;
esac 