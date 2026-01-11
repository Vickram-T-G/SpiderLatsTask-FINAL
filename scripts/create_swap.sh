
set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

SWAP_SIZE="2G"
SWAP_FILE="/swapfile"

echo -e "${GREEN}Checking for existing swap...${NC}"

if swapon --show | grep -q "${SWAP_FILE}"; then
    echo -e "${YELLOW}⚠ Swap file ${SWAP_FILE} already exists and is active${NC}"
    echo "Current swap status:"
    swapon --show
    exit 0
fi

if [ -f "${SWAP_FILE}" ]; then
    echo -e "${YELLOW}⚠ Swap file ${SWAP_FILE} exists but is not active${NC}"
    echo "Activating existing swap file..."
    swapon "${SWAP_FILE}"
    echo -e "${GREEN}✓ Swap activated${NC}"
    exit 0
fi

echo -e "${YELLOW}Creating ${SWAP_SIZE} swap file at ${SWAP_FILE}...${NC}"

if command -v fallocate &> /dev/null; then
    fallocate -l "${SWAP_SIZE}" "${SWAP_FILE}"
else
    echo "fallocate not available, using dd (this may take a moment)..."
    dd if=/dev/zero of="${SWAP_FILE}" bs=1M count=2048
fi

chmod 600 "${SWAP_FILE}"

echo "Formatting swap file..."
mkswap "${SWAP_FILE}"

echo "Enabling swap..."
swapon "${SWAP_FILE}"

if ! grep -q "${SWAP_FILE}" /etc/fstab; then
    echo "Adding swap to /etc/fstab..."
    echo "${SWAP_FILE} none swap sw 0 0" >> /etc/fstab
    echo -e "${GREEN}✓ Swap added to /etc/fstab${NC}"
else
    echo -e "${YELLOW}⚠ Swap already in /etc/fstab${NC}"
fi

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Swap Creation Complete!${NC}"
echo -e "${GREEN}========================================${NC}"
echo "Swap status:"
swapon --show
echo ""
echo "Memory and swap usage:"
free -h
echo ""
echo -e "${GREEN}✓ Swap file created and activated successfully${NC}"

