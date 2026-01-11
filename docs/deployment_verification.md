# Deployment Verification Guide

## Overview

This document provides exact commands and expected responses for verifying the Login App deployment.

## Prerequisites

- Access to production VM (via SSH or public IP)
- `curl` installed on verification machine
- Docker installed on production VM

## Verification Checklist

### 1. Service Health Check

**Command**:
```bash
curl -I http://localhost/health
```

**Expected Response**:
```
HTTP/1.1 200 OK
Server: nginx/1.x.x
Content-Type: text/plain
Content-Length: 8

healthy
```

**On Production VM**:
```bash
ssh deploy@your-vm-ip "curl -I http://localhost/health"
```

### 2. Frontend Accessibility

**Command**:
```bash
curl -I http://localhost/
```

**Expected Response**:
```
HTTP/1.1 200 OK
Server: nginx/1.x.x
Content-Type: text/html
Content-Length: <some-number>
```

**Verify HTML Content**:
```bash
curl http://localhost/ | head -20
```

Should contain React app HTML (look for `<div id="root">` or similar).

### 3. Security Headers Verification

**Command**:
```bash
curl -I http://localhost/ 2>&1 | grep -i "x-frame-options\|x-content-type-options\|referrer-policy\|x-xss-protection"
```

**Expected Headers**:
```
X-Frame-Options: SAMEORIGIN
X-Content-Type-Options: nosniff
X-XSS-Protection: 1; mode=block
Referrer-Policy: strict-origin-when-cross-origin
```

### 4. Backend API Verification

**Command**:
```bash
curl -I http://localhost/api/
```

**Expected Response**:
```
HTTP/1.1 200 OK
Server: nginx/1.x.x
Content-Type: application/json
```

**Test API Endpoint** (adjust based on your API):
```bash
curl http://localhost/api/getUser
```

**Expected**: JSON response or appropriate API response.

### 5. Static Asset Caching

**Command**:
```bash
curl -I http://localhost/static/js/main.js 2>/dev/null | grep -i "cache-control\|expires"
```

**Expected Headers**:
```
Cache-Control: public, immutable
Expires: <future-date>
```

### 6. Gzip Compression

**Command**:
```bash
curl -H "Accept-Encoding: gzip" -I http://localhost/ 2>&1 | grep -i "content-encoding"
```

**Expected Header**:
```
Content-Encoding: gzip
```

### 7. Docker Container Status

**On Production VM**:
```bash
ssh deploy@your-vm-ip "cd /opt/login-app && docker compose ps"
```

**Expected Output**:
```
NAME                  STATUS          PORTS
login-app-backend     Up (healthy)    ...
login-app-frontend    Up (healthy)    ...
login-app-nginx       Up (healthy)    0.0.0.0:80->80/tcp
login-app-postgres    Up (healthy)    ...
```

All services should show `Up (healthy)`.

### 8. Container Logs Verification

**On Production VM**:
```bash
ssh deploy@your-vm-ip "cd /opt/login-app && docker compose logs --tail=50 backend"
```

**Expected**: No error messages, application started successfully.

### 9. Image Tag Verification

**On Production VM**:
```bash
ssh deploy@your-vm-ip "cd /opt/login-app && docker compose images"
```

**Expected**: Images should match the tag deployed by Jenkins (e.g., `ghcr.io/your-org/login-app-backend:abc1234`).

### 10. Network Connectivity

**Test from within Docker network**:
```bash
ssh deploy@your-vm-ip "docker exec login-app-nginx curl -f http://backend:8080/"
```

**Expected**: HTTP 200 response from backend.

## Complete Verification Script

Save this as `verify_deployment.sh`:

```bash
#!/bin/bash
set -e

HOST="${1:-localhost}"
echo "Verifying deployment on ${HOST}..."

echo "1. Health Check..."
curl -f -s http://${HOST}/health || exit 1

echo "2. Frontend..."
curl -f -s -I http://${HOST}/ | head -1

echo "3. Security Headers..."
curl -s -I http://${HOST}/ | grep -i "x-frame-options\|x-content-type-options" || echo "⚠ Some headers missing"

echo "4. Backend API..."
curl -f -s -I http://${HOST}/api/ | head -1

echo "5. Gzip Compression..."
curl -s -H "Accept-Encoding: gzip" -I http://${HOST}/ | grep -i "content-encoding" || echo "⚠ Gzip not detected"

echo "✓ All checks passed!"
```

**Usage**:
```bash
chmod +x verify_deployment.sh
./verify_deployment.sh localhost
# Or for remote VM:
./verify_deployment.sh your-vm-ip
```

## Post-Deployment Verification

After Jenkins pipeline completes:

1. **Check Jenkins Console Output**:
   - All stages should show ✓ (green)
   - No errors in logs
   - Images pushed successfully
   - Deployment completed

2. **Verify on Production VM**:
   ```bash
   ssh deploy@your-vm-ip
   cd /opt/login-app
   docker compose ps
   docker compose logs --tail=100
   ```

3. **Test Public Endpoint** (if VM has public IP/DNS):
   ```bash
   curl http://your-vm-ip/health
   curl http://your-vm-ip/
   ```

## Rollback Procedure

If deployment fails:

1. **Stop new containers**:
   ```bash
   ssh deploy@your-vm-ip "cd /opt/login-app && docker compose down"
   ```

2. **Revert to previous image tag**:
   ```bash
   ssh deploy@your-vm-ip "cd /opt/login-app && \
     IMAGE_TAG=previous-tag docker compose -f docker-compose.yml -f docker-compose.prod.yml up -d"
   ```

3. **Verify rollback**:
   ```bash
   curl http://your-vm-ip/health
   ```

## Common Issues

### Issue: 502 Bad Gateway

**Check**:
```bash
docker compose logs backend
docker compose ps backend
```

**Solution**: Backend may not be healthy. Check logs and ensure backend binds to `0.0.0.0:8080`.

### Issue: 404 Not Found

**Check**:
```bash
docker compose logs frontend
docker compose exec frontend ls -la /usr/share/nginx/html
```

**Solution**: Frontend build may have failed. Rebuild frontend image.

### Issue: Database Connection Error

**Check**:
```bash
docker compose logs backend | grep -i "database\|connection"
docker compose ps postgres
```

**Solution**: Ensure PostgreSQL is healthy and `DATABASE_URL` is correct.

## Performance Benchmarks

Expected response times (local network):

- Health endpoint: < 50ms
- Frontend HTML: < 100ms
- API endpoint: < 200ms
- Static assets: < 50ms (after first request, cached)

## Security Verification

1. **Check for exposed secrets**:
   ```bash
   docker compose config | grep -i "password\|secret\|key"
   ```
   Should only show environment variable references, not actual values.

2. **Verify non-root containers**:
   ```bash
   docker compose exec backend whoami
   ```
   Should return `appuser` (not `root`).

3. **Check network isolation**:
   ```bash
   docker network inspect login-app_app-network
   ```
   Services should only be accessible within the network.

