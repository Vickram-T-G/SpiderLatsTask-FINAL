# Jenkins Setup Guide

## Overview

This guide explains how to set up Jenkins for the Login App CI/CD pipeline.

## Prerequisites

- Jenkins 2.400+ installed
- Docker installed and accessible to Jenkins agents
- SSH access to production deployment VM
- Container registry account (GitHub Container Registry or Docker Hub)

## Step 1: Install Required Jenkins Plugins

1. Navigate to **Manage Jenkins** → **Manage Plugins**
2. Install the following plugins:
   - **Pipeline** (usually pre-installed)
   - **Docker Pipeline** (for Docker operations)
   - **SSH Pipeline Steps** (for SSH deployments)
   - **Credentials Binding** (for secure credential management)
   - **Git** (for SCM checkout)

## Step 2: Configure Jenkins Credentials

Navigate to **Manage Jenkins** → **Credentials** → **System** → **Global credentials**

### 2.1 Docker Registry Credentials

**Credential ID**: `DOCKER_REGISTRY_CRED`

1. Click **Add Credentials**
2. Select **Username with password**
3. Enter:
   - **Username**: Your GitHub username or Docker Hub username
   - **Password**: Personal Access Token (PAT) for GHCR or Docker Hub password
   - **ID**: `DOCKER_REGISTRY_CRED`
   - **Description**: "Docker Registry Credentials"

**For GitHub Container Registry (GHCR)**:
- Create a Personal Access Token (PAT) with `write:packages` scope
- Username: Your GitHub username
- Password: The PAT

**For Docker Hub**:
- Username: Your Docker Hub username
- Password: Your Docker Hub password or access token

### 2.2 SSH Deploy Key

**Credential ID**: `SSH_DEPLOY_KEY`

1. Click **Add Credentials**
2. Select **SSH Username with private key**
3. Enter:
   - **Username**: `deploy` (or your deploy user)
   - **Private Key**: Paste your SSH private key or select "Enter directly"
   - **ID**: `SSH_DEPLOY_KEY`
   - **Description**: "SSH Key for Production Deployment"

**Generate SSH Key** (if needed):
```bash
ssh-keygen -t ed25519 -C "jenkins-deploy" -f ~/.ssh/jenkins_deploy
# Copy public key to production VM
ssh-copy-id -i ~/.ssh/jenkins_deploy.pub deploy@your-vm-ip
```

### 2.3 Optional: Additional Credentials

**Credential ID**: `DOCKER_REGISTRY_URL` (Secret text)
- Value: `ghcr.io` or `docker.io`

**Credential ID**: `DOCKER_ORG` (Secret text)
- Value: Your GitHub username or Docker Hub organization

**Credential ID**: `DEPLOY_HOST` (Secret text)
- Value: IP address or hostname of production VM

**Credential ID**: `SSH_DEPLOY_USER` (Secret text)
- Value: SSH username (usually `deploy`)

**Credential ID**: `DEPLOY_PATH` (Secret text)
- Value: Deployment path on VM (usually `/opt/login-app`)

## Step 3: Configure Jenkins Agent (if using agent)

If Jenkins runs in a container or separate agent:

1. Ensure Docker is installed and accessible
2. Add Jenkins user to docker group (Linux):
   ```bash
   sudo usermod -aG docker jenkins
   sudo systemctl restart jenkins
   ```
3. Test Docker access:
   ```bash
   sudo -u jenkins docker ps
   ```

## Step 4: Create Jenkins Pipeline Job

### Option A: Pipeline from SCM (Recommended)

1. Navigate to **New Item**
2. Enter job name: `login-app-cicd`
3. Select **Pipeline**
4. Click **OK**
5. Configure:
   - **Definition**: Pipeline script from SCM
   - **SCM**: Git
   - **Repository URL**: Your repository URL
   - **Credentials**: Add if repository is private
   - **Branches to build**: `*/main` (or your main branch)
   - **Script Path**: `Jenkinsfile`
6. Click **Save**

### Option B: Manual Pipeline Job

1. Navigate to **New Item**
2. Enter job name: `login-app-cicd`
3. Select **Pipeline**
4. Click **OK**
5. In **Pipeline** section:
   - **Definition**: Pipeline script
   - Paste the contents of `Jenkinsfile` into the script box
6. Click **Save**

## Step 5: Configure Webhook (Optional but Recommended)

### GitHub Webhook Setup

1. Go to your GitHub repository
2. Navigate to **Settings** → **Webhooks**
3. Click **Add webhook**
4. Configure:
   - **Payload URL**: `http://your-jenkins-url/github-webhook/`
   - **Content type**: `application/json`
   - **Secret**: (optional) Add a webhook secret
   - **Events**: Select "Just the push event"
   - **Active**: ✓
5. Click **Add webhook**

### Jenkins Webhook Configuration

1. In Jenkins job configuration
2. Under **Build Triggers**:
   - Check **GitHub hook trigger for GITScm polling**
3. Save

## Step 6: Test Pipeline

1. Click **Build Now** in Jenkins job
2. Monitor build progress in **Console Output**
3. Verify all stages complete successfully

## Troubleshooting

### Issue: "Docker command not found"

**Solution**: Ensure Docker is installed and Jenkins user has access:
```bash
which docker
sudo usermod -aG docker jenkins
```

### Issue: "Permission denied" when pushing to registry

**Solution**: Verify `DOCKER_REGISTRY_CRED` credentials are correct and have write permissions.

### Issue: "SSH connection refused"

**Solution**: 
- Verify SSH key is correct in `SSH_DEPLOY_KEY` credential
- Test SSH manually: `ssh -i ~/.ssh/jenkins_deploy deploy@your-vm-ip`
- Check firewall rules on production VM

### Issue: "Cannot connect to Docker daemon"

**Solution**: 
- Add Jenkins user to docker group
- Restart Jenkins service
- Verify Docker socket permissions

## Next Steps

- Review pipeline logs for any errors
- Verify images are pushed to registry
- Check deployment on production VM
- See `deployment_verification.md` for verification steps

