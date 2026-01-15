# Jenkins CI/CD Setup Guide

This guide walks you through setting up Jenkins to automatically build, test, and deploy your application.

## Prerequisites

- ✅ Your application is running locally (Docker containers working)
- ✅ Jenkins installed and running
- ✅ Docker installed on Jenkins server
- ✅ Access to GitHub Container Registry (GHCR) or Docker Hub
- ✅ AWS EC2 instance (for deployment) - Optional for Level 2

## Part 1: Jenkins Installation (If Not Already Installed)

### Windows Installation

1. **Download Jenkins**:
   - Go to https://www.jenkins.io/download/
   - Download Windows installer (.msi)
   - Run installer

2. **Initial Setup**:
   - Open browser to `http://localhost:8080`
   - Unlock Jenkins with initial admin password (found in installation path)
   - Install suggested plugins
   - Create admin user

### Alternative: Docker Installation

```powershell
docker run -d -p 8080:8080 -p 50000:50000 --name jenkins `
  -v jenkins_home:/var/jenkins_home `
  jenkins/jenkins:lts
```

Get initial password:
```powershell
docker exec jenkins cat /var/jenkins_home/secrets/initialAdminPassword
```

## Part 2: Install Required Jenkins Plugins

1. **Navigate to Plugin Manager**:
   - Jenkins Dashboard → Manage Jenkins → Manage Plugins

2. **Install These Plugins** (Available tab):
   - ✅ Pipeline
   - ✅ Docker Pipeline
   - ✅ SSH Pipeline Steps
   - ✅ Credentials Binding
   - ✅ Git
   - ✅ GitHub Plugin (if using GitHub)
   - ✅ Blue Ocean (optional, for better UI)

3. **Restart Jenkins** after installing plugins

## Part 3: Configure Jenkins Credentials

### 3.1 Docker Registry Credentials (for GHCR or Docker Hub)

1. **Navigate**: Manage Jenkins → Credentials → System → Global credentials → Add Credentials

2. **Configure**:
   - **Kind**: Username with password
   - **Scope**: Global
   - **Username**: Your GitHub username (for GHCR) or Docker Hub username
   - **Password**: 
     - For GHCR: GitHub Personal Access Token (PAT) with `write:packages` scope
     - For Docker Hub: Your Docker Hub password or access token
   - **ID**: `DOCKER_REGISTRY_CRED` (MUST match exactly)
   - **Description**: Docker Registry Credentials

3. **Create GitHub PAT** (if using GHCR):
   - GitHub → Settings → Developer settings → Personal access tokens → Tokens (classic)
   - Generate new token (classic)
   - Select scopes: `write:packages`, `read:packages`
   - Copy token (use as password in credentials)

### 3.2 SSH Credentials (for EC2 Deployment - Optional for Level 2)

**Skip this if you're only doing Level 2 (build/test/push, no deployment)**

1. **Generate SSH Key** (if not exists):
   ```powershell
   # On Jenkins server or your local machine
   ssh-keygen -t ed25519 -C "jenkins-deploy" -f jenkins_deploy
   ```

2. **Add SSH Credential in Jenkins**:
   - Manage Jenkins → Credentials → System → Global credentials → Add Credentials
   - **Kind**: SSH Username with private key
   - **Scope**: Global
   - **ID**: `SSH_DEPLOY_KEY` (MUST match exactly)
   - **Username**: `deploy` (or your EC2 username)
   - **Private Key**: Enter directly → Paste private key content (from `jenkins_deploy` file)
   - **Description**: SSH Key for EC2 Deployment

3. **Add Public Key to EC2**:
   ```bash
   # SSH to your EC2 instance
   ssh -i your-ec2-key.pem ubuntu@your-ec2-ip
   
   # Add Jenkins public key
   sudo su - deploy
   mkdir -p ~/.ssh
   chmod 700 ~/.ssh
   echo "YOUR_JENKINS_PUBLIC_KEY" >> ~/.ssh/authorized_keys
   chmod 600 ~/.ssh/authorized_keys
   ```

## Part 4: Configure Jenkinsfile Environment Variables

Edit `Jenkinsfile` in your repository (lines 5-19):

```groovy
environment {
    DOCKER_REGISTRY = 'ghcr.io'  // or 'docker.io' for Docker Hub
    DOCKER_ORG = 'Vickram-T-G'   // Your GitHub username or Docker Hub org
    
    DEPLOY_HOST = 'your-ec2-ip-or-hostname'  // EC2 Elastic IP (optional for Level 2)
    DEPLOY_USER = 'deploy'
    DEPLOY_PATH = '/home/deploy/app'
}
```

**For Level 2 Only** (no deployment):
- You can leave `DEPLOY_HOST` as-is (deployment stage will be skipped if SSH fails)
- Or comment out deployment stages in Jenkinsfile

## Part 5: Create Jenkins Pipeline Job

1. **Create New Job**:
   - Jenkins Dashboard → New Item
   - **Name**: `login-app-cicd`
   - **Type**: Pipeline
   - Click OK

2. **Configure Pipeline**:
   - Scroll to **Pipeline** section
   - **Definition**: Pipeline script from SCM
   - **SCM**: Git
   - **Repository URL**: Your repository URL (e.g., `https://github.com/Vickram-T-G/DevOps-laterals-task-main.git`)
   - **Credentials**: Add if private repository
   - **Branches to build**: `*/main` (or your main branch name)
   - **Script Path**: `Jenkinsfile` (should be in root of repo)
   - Click **Save**

## Part 6: Configure Docker on Jenkins Server

### If Jenkins is on Windows:

1. **Ensure Docker Desktop is running**
2. **Jenkins needs access to Docker**:
   - Install Docker Pipeline plugin (already done)
   - Jenkins service needs to run with user that has Docker access
   - Or configure Docker Toolbox/Desktop socket access

### If Jenkins is in Docker:

1. **Mount Docker socket**:
   ```powershell
   docker run -d -p 8080:8080 -p 50000:50000 `
     -v jenkins_home:/var/jenkins_home `
     -v /var/run/docker.sock:/var/run/docker.sock `
     --name jenkins `
     jenkins/jenkins:lts
   ```

2. **Install Docker CLI in Jenkins container**:
   ```powershell
   docker exec -it jenkins bash
   apt-get update
   apt-get install -y docker.io
   ```

## Part 7: Run Your First Pipeline

1. **Trigger Build**:
   - Go to your pipeline job: `login-app-cicd`
   - Click **Build Now**

2. **Monitor Build**:
   - Click on build number (#1)
   - Click **Console Output** to see real-time logs

3. **Expected Stages** (Level 2):
   - ✅ Checkout
   - ✅ Lint & Static Checks
   - ✅ Build Backend Image
   - ✅ Build Frontend Image
   - ✅ Test Images
   - ✅ Push Images to Registry

4. **If Deployment is configured** (Level 3):
   - ✅ Deploy to Production
   - ✅ Verify Deployment

## Part 8: Verify Pipeline Success

### Check Build Status
- ✅ Blue ball = Success
- 🔴 Red ball = Failure
- 🟡 Yellow ball = Unstable

### Check Images in Registry

**For GHCR**:
- Go to: https://github.com/Vickram-T-G?tab=packages
- You should see: `login-app-backend` and `login-app-frontend`

**For Docker Hub**:
- Go to: https://hub.docker.com/u/yourusername
- You should see your images

### Verify Images Were Pushed
```powershell
docker pull ghcr.io/vickram-t-g/login-app-backend:latest
docker pull ghcr.io/vickram-t-g/login-app-frontend:latest
```

## Troubleshooting

### Pipeline Fails at Docker Build

**Issue**: Permission denied or Docker daemon not accessible

**Fix**:
- Ensure Docker is running: `docker ps`
- Add Jenkins user to docker group (Linux) or run Jenkins with Docker access (Windows)
- Check Docker socket permissions

### Pipeline Fails at Registry Push

**Issue**: Authentication failed

**Fix**:
- Verify `DOCKER_REGISTRY_CRED` credential ID matches exactly
- Check username/password are correct
- For GHCR: Ensure PAT has `write:packages` scope
- Test login manually: `docker login ghcr.io -u username -p token`

### Pipeline Fails at SSH Deployment

**Issue**: Permission denied or connection timeout

**Fix**:
- Verify `SSH_DEPLOY_KEY` credential ID matches exactly
- Test SSH manually: `ssh -i key deploy@ec2-ip`
- Check EC2 Security Group allows SSH (port 22)
- Verify `DEPLOY_HOST` in Jenkinsfile matches EC2 IP

### Build Hangs or Times Out

**Issue**: Build takes too long

**Fix**:
- Increase timeout in Jenkinsfile (line 24): `timeout(time: 60, unit: 'MINUTES')`
- Check Jenkins server resources (CPU, RAM, disk)
- Review build logs for specific failing step

## Next Steps

1. ✅ Set up webhook (GitHub → Jenkins) for automatic builds on push
2. ✅ Configure branch protection rules
3. ✅ Set up notifications (email, Slack, etc.)
4. ✅ Add more test stages
5. ✅ Configure deployment to staging environment

## Useful Jenkins URLs

- **Dashboard**: http://localhost:8080
- **Manage Jenkins**: http://localhost:8080/manage
- **Credentials**: http://localhost:8080/credentials
- **Plugin Manager**: http://localhost:8080/pluginManager
- **Pipeline Job**: http://localhost:8080/job/login-app-cicd/

## Quick Reference: Credential IDs (MUST Match Exactly)

- Docker Registry: `DOCKER_REGISTRY_CRED`
- SSH Deploy Key: `SSH_DEPLOY_KEY`

## Quick Reference: Jenkinsfile Variables to Update

- `DOCKER_REGISTRY`: `ghcr.io` or `docker.io`
- `DOCKER_ORG`: Your GitHub username or Docker Hub org
- `DEPLOY_HOST`: Your EC2 Elastic IP (if deploying)
