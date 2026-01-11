
set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}EC2 Bootstrap Script${NC}"
echo -e "${GREEN}========================================${NC}"

if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}Error: This script must be run as root (use sudo)${NC}"
    exit 1
fi

echo -e "${YELLOW}[1/8] Updating system packages...${NC}"
apt-get update
apt-get upgrade -y

echo -e "${YELLOW}[2/8] Installing required packages...${NC}"
apt-get install -y \
    curl \
    git \
    unzip \
    jq \
    apt-transport-https \
    ca-certificates \
    gnupg \
    lsb-release

echo -e "${YELLOW}[3/8] Installing Docker...${NC}"
if ! command -v docker &> /dev/null; then
    curl -fsSL https://get.docker.com -o /tmp/get-docker.sh
    sh /tmp/get-docker.sh
    systemctl enable docker
    systemctl start docker
    echo -e "${GREEN}✓ Docker installed${NC}"
else
    echo -e "${YELLOW}⚠ Docker already installed${NC}"
fi

echo -e "${YELLOW}[4/8] Installing Docker Compose...${NC}"
if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
    mkdir -p /usr/local/lib/docker/cli-plugins
    curl -SL https://github.com/docker/compose/releases/latest/download/docker-compose-linux-x86_64 \
        -o /usr/local/lib/docker/cli-plugins/docker-compose
    chmod +x /usr/local/lib/docker/cli-plugins/docker-compose
    ln -sf /usr/local/lib/docker/cli-plugins/docker-compose /usr/local/bin/docker-compose
    echo -e "${GREEN}✓ Docker Compose installed${NC}"
else
    echo -e "${YELLOW}⚠ Docker Compose already installed${NC}"
fi

echo -e "${YELLOW}[5/8] Creating deploy user...${NC}"
if ! id "deploy" &>/dev/null; then
    useradd -m -s /bin/bash deploy
    usermod -aG sudo,docker deploy
    echo "deploy ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/deploy
    echo -e "${GREEN}✓ Deploy user created${NC}"
else
    echo -e "${YELLOW}⚠ Deploy user already exists${NC}"
fi

echo -e "${YELLOW}[6/8] Creating swap file (2GB)...${NC}"
if ! swapon --show | grep -q swapfile; then
    fallocate -l 2G /swapfile || dd if=/dev/zero of=/swapfile bs=1M count=2048
    chmod 600 /swapfile
    mkswap /swapfile
    swapon /swapfile
    echo '/swapfile none swap sw 0 0' >> /etc/fstab
    echo -e "${GREEN}✓ Swap file created${NC}"
else
    echo -e "${YELLOW}⚠ Swap file already exists${NC}"
fi

echo -e "${YELLOW}[7/8] Configuring Docker daemon...${NC}"
mkdir -p /etc/docker
cat > /etc/docker/daemon.json << 'EOF'
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  }
}
EOF
systemctl restart docker
echo -e "${GREEN}✓ Docker daemon configured${NC}"

echo -e "${YELLOW}[8/8] Creating application directory...${NC}"
mkdir -p /home/deploy/app
chown -R deploy:deploy /home/deploy/app
echo -e "${GREEN}✓ Application directory created${NC}"

echo "vm.swappiness=10" >> /etc/sysctl.conf
sysctl vm.swappiness=10

cat > /etc/systemd/system/login-app.service << 'EOF'
[Unit]
Description=Login App Docker Compose
Requires=docker.service
After=docker.service

[Service]
Type=oneshot
RemainAfterExit=yes
WorkingDirectory=/home/deploy/app
User=deploy
ExecStart=/usr/local/bin/docker compose -f docker-compose.yml -f docker-compose.prod.yml up -d
ExecStop=/usr/local/bin/docker compose -f docker-compose.yml -f docker-compose.prod.yml down
TimeoutStartSec=0

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable login-app.service || true

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Bootstrap Complete!${NC}"
echo -e "${GREEN}========================================${NC}"
echo "Docker version: $(docker --version)"
echo "Docker Compose version: $(docker compose version)"
echo "Swap status:"
swapon --show
echo ""
echo "Next steps:"
echo "1. Add Jenkins SSH public key to ~deploy/.ssh/authorized_keys"
echo "2. Switch to deploy user: sudo su - deploy"
echo "3. Clone repository or let Jenkins deploy via SSH"
echo "4. Configure .env file with production values"

