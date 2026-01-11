set -e 

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' 

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Login App - Build and Start${NC}"
echo -e "${GREEN}========================================${NC}"

if [ ! -f .env ]; then
    echo -e "${YELLOW}Warning: .env file not found.${NC}"
    echo -e "${YELLOW}Creating .env from env.example...${NC}"
    if [ -f env.example ]; then
        cp env.example .env
        echo -e "${YELLOW}Please edit .env with your configuration before continuing.${NC}"
        read -p "Press Enter to continue or Ctrl+C to abort..."
    else
        echo -e "${RED}Error: env.example not found. Cannot create .env${NC}"
        exit 1
    fi
fi

PULL_FLAG=""
NO_CACHE_FLAG=""

    case $1 in
        --pull)
            PULL_FLAG="--pull"
            shift
            ;;
        --no-cache)
            NO_CACHE_FLAG="--no-cache"
            shift
            ;;
        *)
            echo -e "${RED}Unknown option: $1${NC}"
            echo "Usage: $0 [--pull] [--no-cache]"
            exit 1
            ;;
    esac
done

BUILD_ARGS=""
if [ -n "$PULL_FLAG" ]; then
    BUILD_ARGS="$BUILD_ARGS $PULL_FLAG"
fi
if [ -n "$NO_CACHE_FLAG" ]; then
    BUILD_ARGS="$BUILD_ARGS $NO_CACHE_FLAG"
fi

echo -e "${YELLOW}Cleaning up existing containers...${NC}"
docker-compose down 2>/dev/null || true

echo -e "${GREEN}Building Docker images...${NC}"
docker-compose build $BUILD_ARGS

echo -e "${GREEN}Starting services...${NC}"
docker-compose up -d

echo -e "${YELLOW}Waiting for services to be healthy...${NC}"
sleep 5

echo -e "${GREEN}Service Status:${NC}"
docker-compose ps

echo -e "${GREEN}Recent logs (press Ctrl+C to exit):${NC}"
echo -e "${YELLOW}Use 'docker-compose logs -f' to follow logs${NC}"
echo ""

echo -e "${GREEN}Checking health status...${NC}"
sleep 10

if docker-compose ps | grep -q "Up"; then
    echo -e "${GREEN}✓ Services are running${NC}"
else
    echo -e "${RED}✗ Some services failed to start${NC}"
    echo -e "${YELLOW}Check logs with: docker-compose logs${NC}"
    exit 1
fi

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Application URLs:${NC}"
echo -e "${GREEN}========================================${NC}"
echo -e "Frontend: ${GREEN}http://localhost${NC}"
echo -e "Backend API: ${GREEN}http://localhost/api${NC}"
echo -e "Health Check: ${GREEN}http://localhost/health${NC}"
echo ""
echo -e "${GREEN}Useful commands:${NC}"
echo -e "  View logs:     ${YELLOW}docker-compose logs -f${NC}"
echo -e "  Stop services: ${YELLOW}docker-compose down${NC}"
echo -e "  Check status:  ${YELLOW}docker-compose ps${NC}"
echo -e "${GREEN}========================================${NC}"

