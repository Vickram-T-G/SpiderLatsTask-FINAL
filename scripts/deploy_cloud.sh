
set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

DEPLOY_PATH="${DEPLOY_PATH:-/home/deploy/app}"
IMAGE_TAG="${IMAGE_TAG:-latest}"
DOCKER_REGISTRY="${DOCKER_REGISTRY:-ghcr.io}"
DOCKER_ORG="${DOCKER_ORG:-your-org}"
DOCKER_USER="${DOCKER_USER:-}"
DOCKER_PASS="${DOCKER_PASS:-}"

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Login App - Cloud Deployment${NC}"
echo -e "${GREEN}========================================${NC}"
echo "Deploy path: ${DEPLOY_PATH}"
echo "Image tag: ${IMAGE_TAG}"
echo "Registry: ${DOCKER_REGISTRY}/${DOCKER_ORG}"
echo ""

cd "${DEPLOY_PATH}" || {
    echo -e "${RED}Error: Cannot access ${DEPLOY_PATH}${NC}"
    exit 1
}


echo -e "${YELLOW}[1/7] Running pre-deployment checks...${NC}"

if ! command -v docker &> /dev/null; then
    echo -e "${RED}Error: Docker is not installed${NC}"
    exit 1
fi

if ! docker info &> /dev/null; then
    echo -e "${RED}Error: Docker daemon is not running${NC}"
    exit 1
fi

if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
    echo -e "${RED}Error: docker-compose is not installed${NC}"
    exit 1
fi

if command -v docker-compose &> /dev/null; then
    COMPOSE_CMD="docker-compose"
else
    COMPOSE_CMD="docker compose"
fi

SWAP_SIZE=$(swapon --show | awk 'NR>1 {sum+=$3} END {print sum+0}')
if [ "${SWAP_SIZE:-0}" -lt 1000 ]; then
    echo -e "${YELLOW}⚠ Warning: Swap size is less than 1GB (${SWAP_SIZE}MB)${NC}"
    echo -e "${YELLOW}  Consider running: sudo bash scripts/create_swap.sh${NC}"
fi

echo -e "${GREEN}✓ Pre-deployment checks passed${NC}"


echo -e "${YELLOW}[2/7] Logging into Docker registry...${NC}"

if [ -n "${DOCKER_USER}" ] && [ -n "${DOCKER_PASS}" ]; then
    echo "${DOCKER_PASS}" | docker login "${DOCKER_REGISTRY}" -u "${DOCKER_USER}" --password-stdin || {
        echo -e "${YELLOW}⚠ Docker login failed, continuing (images may be public)${NC}"
    }
else
    echo -e "${YELLOW}⚠ Docker credentials not provided, assuming public images${NC}"
fi

echo -e "${GREEN}✓ Registry login completed${NC}"


echo -e "${YELLOW}[3/7] Creating backup of current deployment...${NC}"

if [ -f docker-compose.yml ]; then
    CURRENT_BACKEND_TAG=$(grep -oP 'image:\s*\K[^:]+:[^ ]+' docker-compose.yml 2>/dev/null | head -1 || echo "none")
    CURRENT_FRONTEND_TAG=$(grep -oP 'image:\s*\K[^:]+:[^ ]+' docker-compose.yml 2>/dev/null | tail -1 || echo "none")
    
    echo "Current backend tag: ${CURRENT_BACKEND_TAG}"
    echo "Current frontend tag: ${CURRENT_FRONTEND_TAG}"
    
    if [ -d logs ]; then
        find logs -name "*.log" -type f -mtime +7 -delete || true
    fi
    mkdir -p logs
    
    echo -e "${GREEN}✓ Backup information recorded${NC}"
else
    echo -e "${YELLOW}⚠ No existing deployment found (first deployment)${NC}"
fi


echo -e "${YELLOW}[4/7] Updating environment configuration...${NC}"

if [ -f .env ]; then
    if grep -q "^IMAGE_TAG=" .env; then
        sed -i "s|^IMAGE_TAG=.*|IMAGE_TAG=${IMAGE_TAG}|" .env
    else
        echo "IMAGE_TAG=${IMAGE_TAG}" >> .env
    fi
    
    if grep -q "^DOCKER_REGISTRY=" .env; then
        sed -i "s|^DOCKER_REGISTRY=.*|DOCKER_REGISTRY=${DOCKER_REGISTRY}|" .env
    else
        echo "DOCKER_REGISTRY=${DOCKER_REGISTRY}" >> .env
    fi
    
    if grep -q "^DOCKER_ORG=" .env; then
        sed -i "s|^DOCKER_ORG=.*|DOCKER_ORG=${DOCKER_ORG}|" .env
    else
        echo "DOCKER_ORG=${DOCKER_ORG}" >> .env
    fi
    
    echo -e "${GREEN}✓ Environment file updated${NC}"
else
    echo -e "${YELLOW}⚠ .env file not found, creating from sample...${NC}"
    if [ -f .env.sample ]; then
        cp .env.sample .env
        echo "IMAGE_TAG=${IMAGE_TAG}" >> .env
        echo "DOCKER_REGISTRY=${DOCKER_REGISTRY}" >> .env
        echo "DOCKER_ORG=${DOCKER_ORG}" >> .env
        echo -e "${YELLOW}⚠ Please review and update .env with production values${NC}"
    fi
fi

export IMAGE_TAG
export DOCKER_REGISTRY
export DOCKER_ORG


echo -e "${YELLOW}[5/7] Pulling new Docker images...${NC}"

echo "Pulling images with tag: ${IMAGE_TAG}"
${COMPOSE_CMD} -f docker-compose.yml -f docker-compose.prod.yml pull || {
    echo -e "${RED}Error: Failed to pull images${NC}"
    exit 1
}

echo -e "${GREEN}✓ Images pulled successfully${NC}"


echo -e "${YELLOW}[6/7] Deploying new containers...${NC}"

echo "Stopping old containers..."
${COMPOSE_CMD} -f docker-compose.yml -f docker-compose.prod.yml down --timeout 30 || true

echo "Starting new containers..."
${COMPOSE_CMD} -f docker-compose.yml -f docker-compose.prod.yml up -d --remove-orphans || {
    echo -e "${RED}Error: Failed to start containers${NC}"
    echo "Attempting rollback..."
    exit 1
}

echo -e "${GREEN}✓ Containers started${NC}"


echo -e "${YELLOW}[7/7] Verifying deployment health...${NC}"

echo "Waiting for services to start (max 90 seconds)..."
MAX_WAIT=90
ELAPSED=0
HEALTHY=false

while [ $ELAPSED -lt $MAX_WAIT ]; do
    if ${COMPOSE_CMD} -f docker-compose.yml -f docker-compose.prod.yml ps | grep -q "healthy"; then
        HEALTHY=true
        break
    fi
    
    sleep 5
    ELAPSED=$((ELAPSED + 5))
    echo "  Waiting... (${ELAPSED}s/${MAX_WAIT}s)"
done

echo ""
echo "Service Status:"
${COMPOSE_CMD} -f docker-compose.yml -f docker-compose.prod.yml ps

echo ""
echo "Testing health endpoint..."
HEALTH_CHECK_RETRIES=5
HEALTH_CHECK_INTERVAL=3

for i in $(seq 1 $HEALTH_CHECK_RETRIES); do
    if curl -f -s -m 10 http://localhost/health > /dev/null 2>&1; then
        echo -e "${GREEN}✓ Health endpoint is responding${NC}"
        HEALTHY=true
        break
    else
        if [ $i -lt $HEALTH_CHECK_RETRIES ]; then
            echo "  Health check attempt $i/$HEALTH_CHECK_RETRIES failed, retrying..."
            sleep $HEALTH_CHECK_INTERVAL
        fi
    fi
done

if [ "$HEALTHY" = false ]; then
    echo -e "${RED}✗ Health check failed after ${MAX_WAIT} seconds${NC}"
    echo "Container logs:"
    ${COMPOSE_CMD} -f docker-compose.yml -f docker-compose.prod.yml logs --tail=50
    exit 1
fi

echo ""
echo "Recent logs (last 20 lines):"
${COMPOSE_CMD} -f docker-compose.yml -f docker-compose.prod.yml logs --tail=20


echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Deployment Complete!${NC}"
echo -e "${GREEN}========================================${NC}"
echo "Deployed image tag: ${IMAGE_TAG}"
echo "Registry: ${DOCKER_REGISTRY}/${DOCKER_ORG}"
echo ""
echo "Useful commands:"
echo "  View logs:     ${COMPOSE_CMD} -f docker-compose.yml -f docker-compose.prod.yml logs -f"
echo "  Check status:  ${COMPOSE_CMD} -f docker-compose.yml -f docker-compose.prod.yml ps"
echo "  Stop services: ${COMPOSE_CMD} -f docker-compose.yml -f docker-compose.prod.yml down"
echo ""

