#!/bin/bash

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' 

DEPLOY_PATH="${DEPLOY_PATH:-/opt/login-app}"
IMAGE_TAG="${IMAGE_TAG:-latest}"
DOCKER_REGISTRY="${DOCKER_REGISTRY:-ghcr.io}"
DOCKER_ORG="${DOCKER_ORG:-your-org}"

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Login App - Production Deployment${NC}"
echo -e "${GREEN}========================================${NC}"
echo "Deploy path: ${DEPLOY_PATH}"
echo "Image tag: ${IMAGE_TAG}"
echo "Registry: ${DOCKER_REGISTRY}/${DOCKER_ORG}"
echo ""

cd "${DEPLOY_PATH}" || {
    echo -e "${RED}Error: Cannot access ${DEPLOY_PATH}${NC}"
    exit 1
}


echo -e "${YELLOW}[1/6] Running pre-deployment checks...${NC}"

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

echo -e "${GREEN}✓ Pre-deployment checks passed${NC}"


echo -e "${YELLOW}[2/6] Creating backup of current deployment...${NC}"

if [ -f docker-compose.yml ]; then
    CURRENT_BACKEND_TAG=$(grep -oP 'image:\s*\K[^:]+:[^ ]+' docker-compose.yml | head -1 || echo "none")
    CURRENT_FRONTEND_TAG=$(grep -oP 'image:\s*\K[^:]+:[^ ]+' docker-compose.yml | tail -1 || echo "none")
    
    echo "Current backend tag: ${CURRENT_BACKEND_TAG}"
    echo "Current frontend tag: ${CURRENT_FRONTEND_TAG}"
    echo -e "${GREEN}✓ Backup information recorded${NC}"
else
    echo -e "${YELLOW}⚠ No existing deployment found (first deployment)${NC}"
fi


echo -e "${YELLOW}[3/6] Updating environment configuration...${NC}"

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


echo -e "${YELLOW}[4/6] Pulling new Docker images...${NC}"

export IMAGE_TAG
export DOCKER_REGISTRY
export DOCKER_ORG

if [ -f "${HOME}/.docker/config.json" ]; then
    echo "Using existing Docker credentials"
else
    echo -e "${YELLOW}⚠ Docker registry credentials not found${NC}"
    echo "If images are private, ensure you're logged in: docker login ${DOCKER_REGISTRY}"
fi

echo "Pulling images with tag: ${IMAGE_TAG}"
${COMPOSE_CMD} -f docker-compose.yml -f docker-compose.prod.yml pull || {
    echo -e "${RED}Error: Failed to pull images${NC}"
    exit 1
}

echo -e "${GREEN}✓ Images pulled successfully${NC}"


echo -e "${YELLOW}[5/6] Deploying new containers...${NC}"

echo "Stopping old containers..."
${COMPOSE_CMD} -f docker-compose.yml -f docker-compose.prod.yml down --timeout 30 || true

echo "Starting new containers..."
${COMPOSE_CMD} -f docker-compose.yml -f docker-compose.prod.yml up -d --remove-orphans || {
    echo -e "${RED}Error: Failed to start containers${NC}"
    echo "Attempting rollback..."
    exit 1
}

echo -e "${GREEN}✓ Containers started${NC}"


echo -e "${YELLOW}[6/6] Verifying deployment health...${NC}"

echo "Waiting for services to start (max 60 seconds)..."
MAX_WAIT=60
ELAPSED=0

while [ $ELAPSED -lt $MAX_WAIT ]; do
    if ${COMPOSE_CMD} -f docker-compose.yml -f docker-compose.prod.yml ps | grep -q "healthy"; then
        echo -e "${GREEN}✓ Services are healthy${NC}"
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
if curl -f -s http://localhost/health > /dev/null; then
    echo -e "${GREEN}✓ Health endpoint is responding${NC}"
else
    echo -e "${YELLOW}⚠ Health endpoint not yet available (may need more time)${NC}"
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

