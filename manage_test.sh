#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Function to show usage
show_usage() {
    echo -e "${GREEN}Usage:${NC}"
    echo "  ./manage_test.sh [command]"
    echo ""
    echo "Commands:"
    echo "  clean    - Clean test environment"
    echo "  start    - Start test container"
    echo "  rebuild  - Clean and start fresh"
    echo ""
}

# Clean function
clean_test() {
    echo -e "${YELLOW}Cleaning test environment...${NC}"
    # Remove old containers
    docker ps -a | grep plex-test | awk '{print $1}' | xargs -r docker rm -f
    # Remove old images
    docker images | grep plex-test | awk '{print $3}' | xargs -r docker rmi -f
    # Remove test data
    rm -rf test_data
}

# Start function
start_test() {
    echo -e "${YELLOW}Starting test container...${NC}"
    # Build and run test container
    docker build -t plex-test -f Dockerfile.test .
    docker run -it --rm \
        -v /var/run/docker.sock:/var/run/docker.sock \
        plex-test /bin/bash
}

# Main script
case "$1" in
    "clean")
        clean_test
        ;;
    "start")
        start_test
        ;;
    "rebuild")
        clean_test
        start_test
        ;;
    *)
        show_usage
        exit 1
        ;;
esac