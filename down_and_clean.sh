set -e 

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' 

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Login App - Stop and Clean${NC}"
echo -e "${GREEN}========================================${NC}"

CLEAN_VOLUMES=false
CLEAN_IMAGES=false
CLEAN_ALL=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --volumes)
            CLEAN_VOLUMES=true
            shift
            ;;
        --images)
            CLEAN_IMAGES=true
            shift
            ;;
        --all)
            CLEAN_ALL=true
            shift
            ;;
        *)
            echo -e "${RED}Unknown option: $1${NC}"
            echo "Usage: $0 [--volumes] [--images] [--all]"
            exit 1
            ;;
    esac
done

echo -e "${YELLOW}Stopping containers...${NC}"
if [ "$CLEAN_VOLUMES" = true ] || [ "$CLEAN_ALL" = true ]; then
    docker-compose down -v
    echo -e "${GREEN}✓ Containers stopped and volumes removed${NC}"
else
    docker-compose down
    echo -e "${GREEN}✓ Containers stopped${NC}"
fi

if [ "$CLEAN_IMAGES" = true ] || [ "$CLEAN_ALL" = true ]; then
    echo -e "${YELLOW}Removing images...${NC}"
    docker-compose down --rmi all || true
    echo -e "${GREEN}✓ Images removed${NC}"
fi

if [ "$CLEAN_ALL" = true ]; then
    echo -e "${YELLOW}Cleaning up Docker system...${NC}"
    read -p "This will remove all unused containers, networks, images, and build cache. Continue? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        docker system prune -af --volumes
        echo -e "${GREEN}✓ Docker system cleaned${NC}"
    else
        echo -e "${YELLOW}Skipped system cleanup${NC}"
    fi
fi

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Cleanup complete!${NC}"
echo -e "${GREEN}========================================${NC}"

if [ "$CLEAN_VOLUMES" = false ] && [ "$CLEAN_ALL" = false ]; then
    echo -e "${YELLOW}Note: Volumes were preserved (database data remains)${NC}"
    echo -e "${YELLOW}Use --volumes to remove volumes, or --all for complete cleanup${NC}"
fi

