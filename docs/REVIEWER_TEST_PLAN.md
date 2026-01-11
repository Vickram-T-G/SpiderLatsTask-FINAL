# Reviewer Test Plan

## Overview

This document provides a step-by-step test plan for reviewers to verify the complete Login App implementation (Levels 1-3). Estimated time: **60-90 minutes**.

---

## Prerequisites

- Docker and Docker Compose installed
- Jenkins installed (or access to Jenkins instance)
- AWS account with EC2 access
- SSH client installed

---

## Phase 1: Local Development Verification (15 minutes)

### Step 1: Clone and Setup

```bash
git clone <repository-url>
cd DevOps-laterals-task-main
cp .env.sample .env
```

### Step 2: Fix Backend Binding

**CRITICAL**: Edit `Backend/src/main.rs` (line ~66):
```rust
// Change from:
.bind("127.0.0.1:8080")?
// To:
.bind("0.0.0.0:8080")?
```

### Step 3: Build and Start

```bash
docker compose build
docker compose up -d
docker compose ps
```

**Expected**: All services show `Up (healthy)` within 60-90 seconds.

### Step 4: Verify Endpoints

```bash
# Health check
curl http://localhost/health
# Expected: "healthy"

# Frontend
curl -I http://localhost/
# Expected: HTTP/1.1 200 OK

# Backend API
curl -I http://localhost/api/
# Expected: HTTP/1.1 200 OK

# Security headers
curl -I http://localhost/ | grep -i "x-frame-options"
# Expected: X-Frame-Options: SAMEORIGIN
```

**✅ Acceptance**: All endpoints return expected responses.

---

## Phase 2: Jenkins Pipeline Verification (20 minutes)

### Step 1: Jenkins Setup

1. Install Jenkins and required plugins (Pipeline, Docker, SSH)
2. Create credentials:
   - `DOCKER_REGISTRY_CRED` (username/password for GHCR or Docker Hub)
   - `SSH_DEPLOY_KEY` (SSH private key for EC2)
3. Create pipeline job from `Jenkinsfile`
4. Configure environment variables in `Jenkinsfile` (lines 16-25)

### Step 2: Run Pipeline

1. Click **Build Now** in Jenkins
2. Monitor **Console Output**
3. Wait for all stages to complete

**Expected Pipeline Stages**:
- [x] Checkout
- [x] Lint & Static Checks
- [x] Build Backend Image
- [x] Build Frontend Image
- [x] Test Images
- [x] Push Images to Registry
- [x] Deploy to Production
- [x] Verify Deployment

**✅ Acceptance**: All stages complete successfully (green ✓).

### Step 3: Verify Images in Registry

```bash
# Check GitHub Container Registry
# Navigate to: https://github.com/users/YOUR_USERNAME/packages

# Or check Docker Hub
# Navigate to: https://hub.docker.com/r/YOUR_USERNAME/login-app-backend
```

**✅ Acceptance**: Images visible with tags `latest` and git short SHA.

---

## Phase 3: AWS EC2 Deployment (30 minutes)

### Step 1: Create EC2 Instance

1. **AWS Console** → **EC2** → **Launch Instance**
2. **AMI**: Ubuntu 22.04 LTS
3. **Instance Type**: `t2.micro` (free tier) or `t3.small` (recommended)
4. **Key Pair**: Select or create
5. **Network Settings**: Create security group allowing:
   - SSH (22) from your IP
   - HTTP (80) from anywhere (0.0.0.0/0)
   - HTTPS (443) from anywhere (0.0.0.0/0)
6. **Advanced Details** → **User Data**: Paste contents of `cloud/aws-cloud-init.txt`
7. **Launch Instance**

### Step 2: Allocate Elastic IP

1. **EC2 Console** → **Elastic IPs** → **Allocate Elastic IP address**
2. **Actions** → **Associate Elastic IP address**
3. Select your EC2 instance
4. **Associate**

**Note**: Use this Elastic IP as `DEPLOY_HOST` in Jenkinsfile.

### Step 3: Verify Bootstrap

```bash
# SSH to instance
ssh -i your-key.pem ubuntu@<elastic-ip>

# Check cloud-init status
sudo tail -f /var/log/cloud-init-output.log

# Verify installations
docker --version
# Expected: Docker version 20.10.x or higher

docker compose version
# Expected: Docker Compose version v2.x.x

# Verify swap (CRITICAL for t2.micro)
swapon --show
# Expected: /swapfile  partition  2G  0B  2G

free -h
# Expected: Shows swap in "Swap" row

# Check deploy user
sudo su - deploy
whoami
# Expected: deploy
```

**✅ Acceptance**: Docker installed, swap created (2GB), deploy user exists.

### Step 4: Add Jenkins SSH Key

```bash
# On Jenkins server or local machine
ssh-keygen -t ed25519 -C "jenkins-deploy" -f ~/.ssh/jenkins_deploy

# Copy public key to EC2
ssh-copy-id -i ~/.ssh/jenkins_deploy.pub deploy@<elastic-ip>

# Or manually:
ssh -i your-key.pem ubuntu@<elastic-ip>
sudo su - deploy
mkdir -p ~/.ssh
chmod 700 ~/.ssh
echo "YOUR_JENKINS_PUBLIC_KEY" >> ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys
```

### Step 5: Configure Jenkins

1. **Add SSH Credential**:
   - **ID**: `SSH_DEPLOY_KEY`
   - **Username**: `deploy`
   - **Private Key**: Paste `~/.ssh/jenkins_deploy` private key

2. **Update Jenkinsfile**:
   - Set `DEPLOY_HOST` to Elastic IP
   - Verify `DEPLOY_USER` is `deploy`
   - Verify `DEPLOY_PATH` is `/home/deploy/app`

### Step 6: Run Jenkins Pipeline

1. Push to `main` branch (or trigger Jenkins build)
2. Monitor Jenkins console output
3. Wait for deployment stage to complete

**✅ Acceptance**: Deployment stage completes successfully.

### Step 7: Verify Public Access

```bash
# From local machine
curl http://<elastic-ip>/health
# Expected: "healthy"

curl -I http://<elastic-ip>/
# Expected: HTTP/1.1 200 OK

# Check security headers
curl -I http://<elastic-ip>/ | grep -i "x-frame-options"
# Expected: X-Frame-Options: SAMEORIGIN
```

**✅ Acceptance**: Application accessible via public IP with correct responses.

### Step 8: Verify on EC2

```bash
# SSH to EC2
ssh -i key deploy@<elastic-ip>
cd /home/deploy/app

# Check service status
docker compose ps
# Expected: All services show "Up (healthy)"

# Check logs
docker compose logs --tail=50 backend
# Expected: No errors, application started

# Verify swap
swapon --show
# Expected: 2GB swap active
```

**✅ Acceptance**: All services healthy, swap active, no errors in logs.

---

## Screenshots to Capture

1. **Jenkins Pipeline Stage View**
   - All stages showing green ✓
   - Build number and timestamp

2. **EC2 Instance Details**
   - Instance type, status, Elastic IP
   - Security Group rules

3. **Docker Services on EC2**
   - `docker compose ps` output showing all services healthy
   - `swapon --show` output showing 2GB swap

4. **Public Endpoint Test**
   - `curl -I http://<elastic-ip>/` output
   - Browser screenshot of application homepage

---

## Commands Summary

### Local Development
```bash
docker compose build
docker compose up -d
curl http://localhost/health
```

### Jenkins
```bash
# Trigger build (via UI or webhook)
# Monitor console output
```

### EC2 Verification
```bash
ssh -i key deploy@<elastic-ip>
docker compose ps
swapon --show
free -h
curl http://localhost/health
```

### Public Access
```bash
curl http://<elastic-ip>/health
curl -I http://<elastic-ip>/
curl -I http://<elastic-ip>/ | grep -i "x-frame-options"
```

---

## Final Checklist

### Level 1: Containerization
- [x] Services start successfully
- [x] Health endpoint works
- [x] Frontend and backend accessible
- [x] Security headers present

### Level 2: CI/CD
- [x] Jenkins pipeline completes successfully
- [x] Images built and tagged correctly
- [x] Images pushed to registry
- [x] No errors in console output

### Level 3: AWS EC2
- [x] EC2 instance bootstrapped correctly
- [x] Swap created (2GB)
- [x] Elastic IP allocated
- [x] Security Group configured
- [x] Jenkins SSH key added
- [x] Deployment successful
- [x] Public endpoint accessible
- [x] All services healthy

---

## Expected Timeline

- **Local verification**: 15 minutes
- **Jenkins setup**: 20 minutes (first time), 5 minutes (subsequent)
- **EC2 setup**: 30 minutes (first time), 10 minutes (subsequent)
- **Pipeline run**: 10-15 minutes
- **Verification**: 10 minutes

**Total**: ~60-90 minutes for first-time setup, ~30 minutes for subsequent runs

---

## Success Criteria

✅ **All acceptance criteria met**:
- Local development works
- Jenkins pipeline completes successfully
- Images pushed to registry
- EC2 instance bootstrapped with swap
- Deployment successful
- Public endpoint accessible
- All services healthy
- Documentation complete

**Ready for Spider DevOps induction review!** 🕷️
