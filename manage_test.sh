#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Function to setup test environment
setup_test() {
    echo -e "${GREEN}Setting up test environment...${NC}"
    
    echo -e "${YELLOW}1. Creating test directory...${NC}"
    mkdir -p ~/plex-test
    cd ~/plex-test
    
    echo -e "${YELLOW}2. Creating Dockerfile...${NC}"
    # Create Dockerfile
    cat << 'EOF' > Dockerfile
FROM ubuntu:22.04
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y \
    sudo curl wget nano systemd cron \
    && rm -rf /var/lib/apt/lists/*
WORKDIR /opt/plex-docker-setup
CMD ["tail", "-f", "/dev/null"]
EOF

    echo -e "${YELLOW}3. Creating docker-compose.test.yml...${NC}"
    # Create docker-compose.test.yml
    cat << 'EOF' > docker-compose.test.yml
version: "3.8"
services:
  ubuntu-test:
    build: .
    container_name: plex-setup-test
    privileged: true  # Needed for systemd
    volumes:
      - ./:/opt/plex-docker-setup
    ports:
      - "32400:32400"
EOF

    echo -e "${YELLOW}4. Copying project files...${NC}"
    cp -r ~/Plex/{docker-compose.yml,.env.example,scripts,docs,README.md,.gitignore} .
    mkdir -p scripts/reports
    
    echo -e "${YELLOW}5. Setting permissions...${NC}"
    chmod +x scripts/*.sh
    
    echo -e "${YELLOW}6. Building and starting container...${NC}"
    docker-compose -f docker-compose.test.yml up -d --build
    
    echo -e "${GREEN}Setup complete!${NC}"
    echo ""
    echo "To enter the test container:"
    echo "docker exec -it plex-setup-test bash"
    echo ""
    echo "Then run the setup script:"
    echo "./scripts/setup.sh"
}

# Function to clean test environment
clean_test() {
    echo -e "${YELLOW}Cleaning test environment...${NC}"
    cd ~/plex-test
    docker-compose -f docker-compose.test.yml down
    docker rmi plex-test-ubuntu-test
    cd ~
    rm -rf plex-test
}

# Function to update test environment
update_test() {
    echo -e "${GREEN}Updating test environment...${NC}"
    cd ~/plex-test
    cp -r ~/Plex/{docker-compose.yml,.env.example,scripts,docs,README.md,.gitignore} .
    chmod +x scripts/*.sh
}

# Main script
case "$1" in
    "setup")
        setup_test
        ;;
    "clean")
        clean_test
        ;;
    "update")
        update_test
        ;;
    "restart")
        clean_test
        setup_test
        ;;
    *)
        echo "Usage: $0 {setup|clean|update|restart}"
        echo "  setup   - Create new test environment"
        echo "  clean   - Remove test environment"
        echo "  update  - Update test files from main project"
        echo "  restart - Clean and recreate test environment"
        exit 1
        ;;
esac 