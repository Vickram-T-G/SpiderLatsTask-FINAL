# Troubleshooting Guide - Getting Everything Running

## Current Status Check

### Issue 1: Docker Desktop Not Running ❌

**Problem**: Docker daemon is not accessible. You're getting this error:
```
error during connect: open //./pipe/dockerDesktopLinuxEngine: The system cannot find the file specified.
```

**Solution**: 
1. **Start Docker Desktop**:
   - Press `Windows Key` and search for "Docker Desktop"
   - Launch Docker Desktop application
   - Wait for Docker Desktop to fully start (you'll see a whale icon in system tray)
   - Wait 30-60 seconds for Docker daemon to initialize

2. **Verify Docker is Running**:
   ```powershell
   docker ps
   ```
   Should return empty list (no error) if Docker is running.

### Issue 2: Verify Configuration

**Backend Binding**: ✅ Already correct! (`0.0.0.0:8080` in `Backend/src/main.rs` line 66)

**Environment File**: ✅ `.env` file exists

## Step-by-Step: Getting Services Running

### Step 1: Start Docker Desktop
- Launch Docker Desktop from Windows Start Menu
- Wait for it to fully start (green icon in system tray)

### Step 2: Verify Docker is Running
```powershell
cd d:\vickram\DevOps-laterals-task-main
docker ps
```

### Step 3: Clean Up (if needed)
```powershell
docker compose down
docker system prune -f
```

### Step 4: Build and Start Services
```powershell
docker compose build
docker compose up -d
```

### Step 5: Check Status
```powershell
docker compose ps
```

Expected output: All 4 services should show "Up (healthy)":
- login-app-postgres
- login-app-backend  
- login-app-frontend
- login-app-nginx

### Step 6: Check Logs
```powershell
# All logs
docker compose logs

# Specific service logs
docker compose logs backend
docker compose logs frontend
docker compose logs postgres
docker compose logs nginx

# Follow logs in real-time
docker compose logs -f
```

### Step 7: Test Endpoints
```powershell
# Health check
curl http://localhost/health

# Frontend
curl -I http://localhost/

# Backend API
curl http://localhost/api/
```

## Common Issues and Fixes

### Containers Keep Restarting

**Check logs**:
```powershell
docker compose logs backend
docker compose logs postgres
```

**Common causes**:
- Database connection issues (check DATABASE_URL in .env)
- Port conflicts (check if ports 80, 5432, 8080 are already in use)
- Memory issues (restart Docker Desktop)

### Backend Won't Start

**Check**:
1. Database is healthy: `docker compose ps postgres`
2. Backend logs: `docker compose logs backend`
3. Database URL format: `postgres://postgres:postgres@postgres:5432/rust_server`

### Frontend Won't Start

**Check**:
1. Build succeeded: `docker compose logs frontend`
2. Nginx configuration: `docker compose exec nginx nginx -t`

### Port Already in Use

**Find what's using the port**:
```powershell
# Check port 80
netstat -ano | findstr :80

# Check port 5432 (PostgreSQL)
netstat -ano | findstr :5432

# Check port 8080 (Backend)
netstat -ano | findstr :8080
```

**Stop conflicting service** or change ports in `.env` file.

## Verification Checklist

- [ ] Docker Desktop is running (green icon in system tray)
- [ ] `docker ps` command works without errors
- [ ] All containers built successfully (`docker compose build` completes)
- [ ] All containers are running (`docker compose ps` shows all "Up")
- [ ] All containers are healthy (`docker compose ps` shows all "healthy")
- [ ] Health endpoint responds: `curl http://localhost/health` returns "healthy"
- [ ] Frontend accessible: Browser shows login page at `http://localhost`
- [ ] Backend API responds: `curl http://localhost/api/` returns response
- [ ] No errors in logs: `docker compose logs` shows no critical errors

## Next Steps After Services Are Running

Once everything is working locally, proceed to Jenkins setup (see JENKINS_SETUP.md).
