# After getting VULTR_BLOCK_ID

# If block storage is configured, set it up
if [ ! -z "$VULTR_BLOCK_ID" ]; then
    echo -e "\n${YELLOW}Setting up block storage for media...${NC}"
    
    # Create directory structure
    mkdir -p /mnt/blockstore/plex/media/{Movies,TV\ Shows,Music,Photos,Home\ Videos}
    chown -R 1000:1000 /mnt/blockstore/plex/media
    chmod -R 755 /mnt/blockstore/plex/media
    
    # Update docker-compose.yml to use block storage
    sed -i 's|/opt/plex/media:|/mnt/blockstore/plex/media:|' docker-compose.yml
    
    # Restart Plex to use new storage
    docker-compose down
    docker-compose up -d
    
    echo -e "${GREEN}✓ Block storage configured for media${NC}"
fi