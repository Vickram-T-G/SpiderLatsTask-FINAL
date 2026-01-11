# 🚀 Quick Start Checklist

Follow these steps in order to get Phase 1 running:

## Prerequisites

- [ ] Docker installed (version 20.10+)
- [ ] Docker Compose installed (version 2.0+)
- [ ] Git installed (if cloning repo)
- [ ] Sufficient disk space (10GB+ free)

## Setup Steps

### 1. Environment Setup

```bash
# Copy environment template
cp env.example .env

# Edit .env if needed (defaults work for local testing)
# For production: CHANGE ALL PASSWORDS!
```

- [ ] `.env` file created
- [ ] `.env` values reviewed (especially passwords)

### 2. Backend Binding Fix (CRITICAL!)

**⚠️ MUST DO BEFORE BUILDING:**

- [ ] Open `Backend/src/main.rs`
- [ ] Find `.bind("127.0.0.1:8080")?` (around line 66)
- [ ] Change to `.bind("0.0.0.0:8080")?`
- [ ] Save file

**See `CRITICAL_BACKEND_CHANGE.md` for details.**

### 3. Build Images

```bash
# Option 1: Use helper script
chmod +x build_and_up.sh  # On Linux/macOS/WSL
./build_and_up.sh

# Option 2: Manual
docker compose build
docker compose up -d
```

- [ ] Images built successfully (no errors)
- [ ] Services started (check with `docker compose ps`)

### 4. Verify Services

```bash
# Check status
docker compose ps

# Expected: All services show "Up (healthy)"
```

- [ ] PostgreSQL: `Up (healthy)`
- [ ] Backend: `Up (healthy)`
- [ ] Frontend: `Up (healthy)`
- [ ] Nginx: `Up (healthy)`

### 5. Test Endpoints

```bash
# Test frontend
curl -I http://localhost/
# Expected: HTTP/1.1 200 OK

# Test health check
curl http://localhost/health
# Expected: healthy

# Test backend API (adjust endpoint if needed)
curl http://localhost/api/
# Expected: HTTP 200 or appropriate response
```

- [ ] Frontend accessible: `http://localhost/` returns 200
- [ ] Health check works: `http://localhost/health` returns "healthy"
- [ ] Backend API accessible: `http://localhost/api/` returns 200 or appropriate

### 6. Verify Logs

```bash
# View all logs
docker compose logs

# Follow logs in real-time
docker compose logs -f

# Check specific service
docker compose logs backend | tail -20
```

- [ ] No errors in logs
- [ ] Backend connects to database successfully
- [ ] Nginx routes requests correctly

## Troubleshooting

If something doesn't work:

1. **Services won't start**: Check logs with `docker compose logs <service>`
2. **502 Bad Gateway**: Backend binding issue? See `CRITICAL_BACKEND_CHANGE.md`
3. **Database connection error**: Wait for PostgreSQL to be healthy, check `DATABASE_URL`
4. **Port 80 in use**: Change `NGINX_HTTP_PORT` in `.env` to different port

See `README_PHASE1.md` Troubleshooting section for more details.

## Next Steps

Once everything is working:

- [ ] Read `README_PHASE1.md` for full documentation
- [ ] Review `WHAT_CHANGED.md` for implementation details
- [ ] Test all acceptance criteria from `README_PHASE1.md`
- [ ] Prepare for Phase 2 (TLS/HTTPS, secrets management, etc.)

## Quick Commands Reference

```bash
# Start services
docker compose up -d

# Stop services
docker compose down

# Stop and remove volumes (⚠️ deletes database data)
docker compose down -v

# View logs
docker compose logs -f

# Rebuild specific service
docker compose build backend
docker compose up -d backend

# Check service health
docker compose ps

# Access service shell
docker compose exec backend bash
docker compose exec postgres psql -U postgres -d rust_server
```

## Common Issues

### Issue: "Permission denied" on scripts (Linux/macOS/WSL)

**Fix**:

```bash
chmod +x build_and_up.sh down_and_clean.sh wait-for.sh
```

### Issue: "Port already in use"

**Fix**: Change port in `.env`:

```bash
NGINX_HTTP_PORT=8080  # Instead of 80
```

Then access at `http://localhost:8080`

### Issue: Backend shows "connection refused" from Nginx

**Fix**: Check backend binding - must be `0.0.0.0:8080`, not `127.0.0.1:8080`

### Issue: Database "does not exist"

**Fix**:

```bash
# Verify database name in .env matches what app expects
# Check DATABASE_URL format: postgres://USER:PASS@HOST:PORT/DBNAME
```

---

**✅ All checks passing? You're ready to go!**

For detailed information, see `README_PHASE1.md`.
