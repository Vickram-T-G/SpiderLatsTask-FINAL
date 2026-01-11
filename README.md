# Login App - Complete DevOps Implementation (**AI tools were used**)

> **Spider DevOps Induction Project**  
> Full-stack application with containerization, CI/CD automation, and AWS cloud deployment

## 📋 Table of Contents

- [Overview](#overview)
- [Architecture](#architecture)
- [Tech Stack](#tech-stack)
- [Project Structure](#project-structure)
- [Level 1: Containerization](#level-1-containerization)
- [Level 2: CI/CD Pipeline](#level-2-cicd-pipeline)
- [Level 3: AWS EC2 Deployment](#level-3-aws-ec2-deployment)
- [Quick Start](#quick-start)
- [Troubleshooting](#troubleshooting)
- [Verification Checklist](#verification-checklist)

---

## Overview

This project demonstrates a complete DevOps pipeline for a full-stack login application:

- **Level 1**: Docker containerization with Nginx reverse proxy
- **Level 2**: Jenkins CI/CD pipeline with automated builds and deployments
- **Level 3**: AWS EC2 cloud deployment with automated provisioning

The application consists of:

- **Backend**: Rust (Actix-Web) REST API
- **Frontend**: React single-page application
- **Database**: PostgreSQL
- **Reverse Proxy**: Nginx with security headers and caching

---

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                         Developer                                │
│                    (Git Push to Main)                            │
└──────────────────────────┬──────────────────────────────────────┘
                           │
                           ▼
                    ┌──────────────┐
                    │   Jenkins    │
                    │   Pipeline   │
                    └──────┬───────┘
                           │
        ┌──────────────────┼──────────────────┐
        │                  │                  │
        ▼                  ▼                  ▼
┌──────────────┐   ┌──────────────┐   ┌──────────────┐
│   Build      │   │   Test       │   │   Push       │
│   Images     │   │   Images     │   │   to GHCR    │
└──────┬───────┘   └──────────────┘   └──────┬───────┘
       │                                      │
       └──────────────────┬──────────────────┘
                          │
                          ▼
              ┌───────────────────────┐
              │  Container Registry  │
              │  (GHCR/Docker Hub)   │
              └───────────┬───────────┘
                          │
                          ▼
              ┌───────────────────────┐
              │   AWS EC2 Instance   │
              │   (Ubuntu 22.04)     │
              │                       │
              │  ┌─────────────────┐ │
              │  │  Nginx (80)     │ │◄─── Internet
              │  └────────┬────────┘ │
              │           │          │
              │  ┌────────▼────────┐ │
              │  │  Frontend       │ │
              │  │  Backend (8080) │ │
              │  │  PostgreSQL     │ │
              │  └─────────────────┘ │
              └───────────────────────┘
```

### Service Architecture

```
Internet → Nginx (Port 80)
            ├── / → Frontend (React SPA)
            └── /api/* → Backend (Actix-Web :8080)
                           └── PostgreSQL (:5432)
```

---

## Tech Stack

| Component          | Technology        | Version          |
| ------------------ | ----------------- | ---------------- |
| Backend            | Rust (Actix-Web)  | 1.70+            |
| Frontend           | React (Node.js)   | 18.x             |
| Database           | PostgreSQL        | 15               |
| Reverse Proxy      | Nginx             | stable-alpine    |
| CI/CD              | Jenkins           | 2.400+           |
| Cloud              | AWS EC2           | Ubuntu 22.04 LTS |
| Container Registry | GHCR / Docker Hub | -                |

---

## Project Structure

```
.
├── Backend/                    # Rust backend source code
│   ├── src/
│   ├── migrations/
│   └── Cargo.toml
├── Frontend/                   # React frontend source code
│   ├── src/
│   └── package.json
├── cloud/                      # Cloud provisioning files
│   └── aws-cloud-init.txt      # EC2 bootstrap script
├── scripts/                     # Deployment and utility scripts
│   ├── deploy.sh               # Generic deployment script
│   ├── deploy_cloud.sh          # AWS EC2 deployment script
│   ├── bootstrap_ec2.sh         # Manual EC2 bootstrap
│   └── create_swap.sh          # Swap creation utility
├── nginx/                      # Nginx configuration
│   ├── nginx.conf              # Main configuration
│   └── default.conf            # Server block
├── docs/                       # Documentation
│   └── reviewer_test_plan.md   # Reviewer test plan
├── Dockerfile.backend          # Backend Dockerfile
├── Dockerfile.frontend         # Frontend Dockerfile
├── docker-compose.yml          # Development compose
├── docker-compose.prod.yml     # Production compose
├── Jenkinsfile                 # CI/CD pipeline
├── .env.sample                 # Environment variables template
└── README.md                   # This file
```

---

## Level 1: Containerization

### Overview

Multi-stage Dockerfiles with Nginx reverse proxy, health checks, and security best practices.

### Key Features

- ✅ Multi-stage builds (minimal image sizes)
- ✅ Non-root user in containers
- ✅ Health checks for all services
- ✅ Nginx reverse proxy with security headers
- ✅ Static asset caching
- ✅ Gzip compression

### Local Development

```bash
# 1. Clone repository
git clone <repository-url>
cd DevOps-laterals-task-main

# 2. Set up environment
cp .env.sample .env
# Edit .env if needed (defaults work for local testing)

# 3. CRITICAL: Fix backend binding
# Edit Backend/src/main.rs (line ~66)
# Change: .bind("127.0.0.1:8080")?
# To:     .bind("0.0.0.0:8080")?

# 4. Build and start
docker compose build
docker compose up -d

# 5. Verify
curl http://localhost/health
# Expected: "healthy"
```

### Files

- `Dockerfile.backend` - Rust backend multi-stage build
- `Dockerfile.frontend` - React frontend multi-stage build
- `docker-compose.yml` - Service orchestration
- `nginx/nginx.conf` - Nginx main configuration
- `nginx/default.conf` - Server block with reverse proxy rules

---

## Level 2: CI/CD Pipeline

### Overview

Jenkins declarative pipeline that builds, tests, tags, and pushes Docker images to a container registry.

### Pipeline Stages

1. **Checkout** - Clone repository from SCM
2. **Lint & Static Checks** - Code quality checks (optional)
3. **Build Backend Image** - Multi-stage Rust build
4. **Build Frontend Image** - Multi-stage React build
5. **Test Images** - Smoke tests on built images
6. **Push Images** - Push to registry with `:latest` and `:<git-sha>` tags
7. **Deploy to Production** - SSH to EC2 and run deployment script
8. **Verify Deployment** - Health check verification

### Jenkins Setup

#### 1. Install Required Plugins

- Pipeline
- Docker Pipeline
- SSH Pipeline Steps
- Credentials Binding
- Git

#### 2. Configure Credentials

Navigate to **Manage Jenkins** → **Credentials** → **System** → **Global credentials**

| Credential ID          | Type                          | Description                                |
| ---------------------- | ----------------------------- | ------------------------------------------ |
| `DOCKER_REGISTRY_CRED` | Username/Password             | Docker registry login (GHCR or Docker Hub) |
| `SSH_DEPLOY_KEY`       | SSH Username with private key | SSH key for EC2 deployment                 |

**For GitHub Container Registry (GHCR)**:

- Username: Your GitHub username
- Password: Personal Access Token (PAT) with `write:packages` scope

**For Docker Hub**:

- Username: Your Docker Hub username
- Password: Your Docker Hub password or access token

#### 3. Create Pipeline Job

1. **New Item** → **Pipeline** → Name: `login-app-cicd`
2. **Pipeline** section:
   - **Definition**: Pipeline script from SCM
   - **SCM**: Git
   - **Repository URL**: Your repository URL
   - **Branches**: `*/main`
   - **Script Path**: `Jenkinsfile`
3. **Save**

#### 4. Configure Environment Variables

Edit `Jenkinsfile` environment section (lines 16-25):

```groovy
environment {
    DOCKER_REGISTRY = 'ghcr.io'  // or 'docker.io'
    DOCKER_ORG = 'your-github-username'
    DEPLOY_HOST = 'your-ec2-elastic-ip'
    DEPLOY_USER = 'deploy'
    DEPLOY_PATH = '/home/deploy/app'
}
```

### Image Tagging Strategy

- `:latest` - Always updated to most recent build
- `:<git-short-sha>` - Specific commit (e.g., `:abc1234`)

Enables easy rollback to specific versions.

---

## Level 3: AWS EC2 Deployment

### Overview

Automated AWS EC2 deployment with cloud-init bootstrap, swap creation, and secure Jenkins SSH deployment.

### Prerequisites

- AWS account with EC2 access
- EC2 key pair for SSH access
- Elastic IP (recommended for static IP)

### Step 1: Create EC2 Instance

#### Using AWS Console

1. **Launch Instance**:

   - **Name**: `login-app-production`
   - **AMI**: Ubuntu 22.04 LTS (free tier eligible)
   - **Instance Type**: `t2.micro` (free tier) or `t3.small` (recommended for production)
   - **Key Pair**: Select or create a key pair
   - **Network Settings**:
     - Create security group or select existing
     - Allow SSH (22), HTTP (80), HTTPS (443) from anywhere (or restricted IPs)

2. **Advanced Details** → **User Data**:

   - Copy contents of `cloud/aws-cloud-init.txt`
   - Paste into User Data field
   - **Important**: Add your Jenkins SSH public key in the `ssh_authorized_keys` section

3. **Launch Instance**

#### Instance Type Recommendations

| Use Case            | Instance Type | RAM  | vCPU | Notes               |
| ------------------- | ------------- | ---- | ---- | ------------------- |
| Free Tier / Testing | `t2.micro`    | 1 GB | 1    | Requires swap (2GB) |
| Production (Small)  | `t3.small`    | 2 GB | 2    | Recommended minimum |
| Production (Medium) | `t3.medium`   | 4 GB | 2    | Better performance  |

**⚠️ Important**: `t2.micro` has only 1GB RAM. The cloud-init script automatically creates 2GB swap to prevent OOM (Out of Memory) kills. See [Troubleshooting](#troubleshooting) for details.

### Step 2: Allocate Elastic IP

1. **EC2 Console** → **Elastic IPs** → **Allocate Elastic IP address**
2. **Actions** → **Associate Elastic IP address**
3. Select your EC2 instance
4. **Associate**

**Note**: Use the Elastic IP as `DEPLOY_HOST` in Jenkinsfile.

### Step 3: Verify Bootstrap

SSH into the instance:

```bash
# Using your EC2 key pair
ssh -i your-key.pem ubuntu@<elastic-ip>

# Check cloud-init status
sudo tail -f /var/log/cloud-init-output.log

# Verify installations
docker --version
docker compose version
swapon --show  # Should show 2GB swap
free -h        # Should show swap in use

# Check deploy user
sudo su - deploy
whoami  # Should output: deploy
```

### Step 4: Add Jenkins SSH Key

```bash
# On Jenkins server or local machine
# Generate SSH key if not exists
ssh-keygen -t ed25519 -C "jenkins-deploy" -f ~/.ssh/jenkins_deploy

# Copy public key to EC2 instance
ssh-copy-id -i ~/.ssh/jenkins_deploy.pub deploy@<elastic-ip>

# Or manually add to EC2:
ssh -i your-key.pem ubuntu@<elastic-ip>
sudo su - deploy
mkdir -p ~/.ssh
chmod 700 ~/.ssh
echo "YOUR_JENKINS_PUBLIC_KEY" >> ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys
```

### Step 5: Configure Jenkins

1. **Add SSH Credential**:

   - **Manage Jenkins** → **Credentials** → **Add Credentials**
   - **Kind**: SSH Username with private key
   - **ID**: `SSH_DEPLOY_KEY`
   - **Username**: `deploy`
   - **Private Key**: Paste Jenkins private key (`~/.ssh/jenkins_deploy`)
   - **Save**

2. **Update Jenkinsfile**:
   - Set `DEPLOY_HOST` to your Elastic IP
   - Verify `DEPLOY_USER` is `deploy`
   - Verify `DEPLOY_PATH` is `/home/deploy/app`

### Step 6: First Deployment

#### Manual Deployment (for testing)

```bash
# SSH to EC2 instance
ssh -i your-key.pem deploy@<elastic-ip>

# Clone repository
cd /home/deploy/app
git clone <repository-url> .

# Copy .env.sample to .env and configure
cp .env.sample .env
nano .env  # Edit with production values

# Run deployment script
export IMAGE_TAG=latest
export DOCKER_REGISTRY=ghcr.io
export DOCKER_ORG=your-org
bash scripts/deploy_cloud.sh
```

#### Automated Deployment via Jenkins

1. Push to `main` branch (or trigger Jenkins build)
2. Monitor Jenkins console output
3. Verify deployment completes successfully

### Step 7: Verify Public Access

```bash
# Test from local machine
curl http://<elastic-ip>/health
# Expected: "healthy"

curl -I http://<elastic-ip>/
# Expected: HTTP/1.1 200 OK

# Check security headers
curl -I http://<elastic-ip>/ | grep -i "x-frame-options"
# Expected: X-Frame-Options: SAMEORIGIN
```

---

## Quick Start

### Complete Setup (All Levels)

```bash
# 1. Local Development
git clone <repo>
cd DevOps-laterals-task-main
cp .env.sample .env
# Fix backend binding in Backend/src/main.rs
docker compose build && docker compose up -d
curl http://localhost/health

# 2. Jenkins Setup
# Install Jenkins and plugins
# Create credentials: DOCKER_REGISTRY_CRED, SSH_DEPLOY_KEY
# Create pipeline job from Jenkinsfile
# Configure environment variables

# 3. AWS EC2 Setup
# Launch EC2 instance with cloud-init
# Allocate Elastic IP
# Add Jenkins SSH key
# Update Jenkinsfile with Elastic IP
# Run Jenkins pipeline
```

---

## Troubleshooting

### The t2.micro OOM Trap

**Problem**: `t2.micro` instances have only 1GB RAM. Running Jenkins builds, Docker, and the application can cause Out of Memory (OOM) kills, leading to:

- Container crashes
- Service hangs
- System instability

**Professional Fix**: Create swap space (2GB) during bootstrap.

**How it works**: Swap uses disk space as virtual memory. While slower than RAM, it prevents OOM kills and allows the system to continue operating.

**Verification**:

```bash
# Check swap status
swapon --show
# Expected: /swapfile  partition  2G  0B  2G

# Check memory usage
free -h
# Should show swap in "Swap" row
```

**If swap is missing**:

```bash
# Run swap creation script
sudo bash scripts/create_swap.sh

# Or manually:
sudo fallocate -l 2G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab
```

**Pros/Cons**:

- ✅ Prevents OOM kills
- ✅ Allows system to continue operating
- ⚠️ Slower than RAM (disk I/O)
- ⚠️ May reduce performance under heavy load

**Recommendation**: For production, use `t3.small` (2GB RAM) or larger to avoid swap dependency.

### Common Issues

#### Issue: Cloud-init failed

**Symptoms**: Docker not installed, swap not created

**Solution**:

```bash
# Check cloud-init logs
sudo tail -f /var/log/cloud-init-output.log

# Run bootstrap script manually
sudo bash scripts/bootstrap_ec2.sh
```

#### Issue: SSH permission denied

**Symptoms**: Jenkins cannot SSH to EC2

**Solution**:

```bash
# Verify SSH key in authorized_keys
ssh -i your-key.pem ubuntu@<elastic-ip>
sudo su - deploy
cat ~/.ssh/authorized_keys

# Check permissions
chmod 700 ~/.ssh
chmod 600 ~/.ssh/authorized_keys

# Test SSH from Jenkins server
ssh -i ~/.ssh/jenkins_deploy deploy@<elastic-ip>
```

#### Issue: Docker login fails

**Symptoms**: Cannot pull private images

**Solution**:

```bash
# Verify credentials in Jenkins
# Check DOCKER_REGISTRY_CRED credential

# Test login manually on EC2
docker login ghcr.io -u <username> -p <token>
```

#### Issue: Containers not starting

**Symptoms**: `docker compose ps` shows unhealthy or exited

**Solution**:

```bash
# Check logs
docker compose logs backend
docker compose logs frontend
docker compose logs postgres

# Check resource usage
docker stats

# Verify .env file
cat .env | grep -v PASSWORD

# Check swap (if t2.micro)
free -h
swapon --show
```

#### Issue: Application not accessible

**Symptoms**: `curl http://<ip>/` returns connection refused

**Solution**:

```bash
# Check Security Group
# Ensure ports 80, 443 are open

# Check Nginx
docker compose logs nginx
docker compose exec nginx nginx -t

# Test from within EC2
curl http://localhost/health
```

#### Issue: Jenkins pipeline fails at deploy stage

**Symptoms**: SSH connection timeout or permission denied

**Solution**:

1. Verify `SSH_DEPLOY_KEY` credential in Jenkins
2. Test SSH manually: `ssh -i key deploy@<ip>`
3. Check EC2 Security Group allows SSH (port 22)
4. Verify `DEPLOY_HOST` in Jenkinsfile matches Elastic IP

---

## Verification Checklist

### Level 1: Local Development

- [ ] Services start: `docker compose ps` shows all healthy
- [ ] Health endpoint: `curl http://localhost/health` returns "healthy"
- [ ] Frontend: `curl -I http://localhost/` returns 200 OK
- [ ] Backend API: `curl -I http://localhost/api/` returns 200 OK
- [ ] Security headers: `curl -I http://localhost/ | grep X-Frame-Options`

### Level 2: CI/CD Pipeline

- [ ] Jenkins pipeline completes all stages (green ✓)
- [ ] Images built and tagged (`:latest` and `:<git-sha>`)
- [ ] Images pushed to container registry
- [ ] No errors in Jenkins console output

### Level 3: AWS EC2 Deployment

- [ ] EC2 instance bootstrapped (Docker, swap, deploy user)
- [ ] Elastic IP allocated and associated
- [ ] Security Group allows 22, 80, 443
- [ ] Jenkins SSH key added to `~deploy/.ssh/authorized_keys`
- [ ] Jenkins pipeline deploys successfully
- [ ] Public endpoint accessible: `curl http://<elastic-ip>/health`
- [ ] Services healthy: `docker compose ps` on EC2
- [ ] Swap active: `swapon --show` shows 2GB swap

---

## Files Reference

### Core Files

| File                      | Purpose                           |
| ------------------------- | --------------------------------- |
| `Dockerfile.backend`      | Rust backend multi-stage build    |
| `Dockerfile.frontend`     | React frontend multi-stage build  |
| `docker-compose.yml`      | Development service orchestration |
| `docker-compose.prod.yml` | Production service orchestration  |
| `Jenkinsfile`             | CI/CD pipeline definition         |
| `.env.sample`             | Environment variables template    |

### Cloud Files

| File                       | Purpose                                         |
| -------------------------- | ----------------------------------------------- |
| `cloud/aws-cloud-init.txt` | EC2 bootstrap script (paste into User Data)     |
| `scripts/bootstrap_ec2.sh` | Manual EC2 bootstrap alternative                |
| `scripts/deploy_cloud.sh`  | AWS EC2 deployment script (executed by Jenkins) |
| `scripts/create_swap.sh`   | Idempotent swap creation utility                |

### Configuration Files

| File                 | Purpose                               |
| -------------------- | ------------------------------------- |
| `nginx/nginx.conf`   | Nginx main configuration              |
| `nginx/default.conf` | Server block with reverse proxy rules |

---

## Security Best Practices

- ✅ No secrets in repository (all in Jenkins credentials)
- ✅ Non-root containers (backend runs as `appuser`)
- ✅ Security headers (CSP, X-Frame-Options, etc.)
- ✅ Rate limiting on API endpoints
- ✅ Network isolation via Docker networks
- ✅ SSH key-based authentication (no passwords)
- ✅ Least privilege (deploy user with sudo)

---

## Rollback Procedure

If deployment fails:

```bash
# SSH to EC2
ssh -i key deploy@<elastic-ip>
cd /home/deploy/app

# Stop current deployment
docker compose -f docker-compose.yml -f docker-compose.prod.yml down

# Deploy previous image tag
export IMAGE_TAG=previous-git-sha
docker compose -f docker-compose.yml -f docker-compose.prod.yml pull
docker compose -f docker-compose.yml -f docker-compose.prod.yml up -d

# Verify
curl http://localhost/health
```

---

## Next Steps

- **Monitoring**: Add Prometheus + Grafana
- **Logging**: Centralized logging (ELK stack)
- **TLS/HTTPS**: SSL certificates and HTTPS configuration
- **Infrastructure as Code**: Terraform for EC2 provisioning
- **Blue-Green Deployment**: Zero-downtime deployments
- **Auto-scaling**: EC2 Auto Scaling Groups

---

## Support

For issues or questions:

1. Review service logs: `docker compose logs`
2. Check cloud-init logs: `sudo tail -f /var/log/cloud-init-output.log`
3. Verify Jenkins console output

---

**Project Status**: ✅ Complete (Levels 1-3)  
**Ready for**: Spider DevOps Induction Review
