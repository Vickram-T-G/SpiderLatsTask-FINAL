# Changelog

All notable changes to this project will be documented in this file.

## [Level 2] - 2024-01-XX

### Added - CI/CD Pipeline Implementation

#### feat(ci): Complete Jenkins CI/CD pipeline
- Added `Jenkinsfile` with declarative pipeline
- Implemented stages: Checkout, Lint, Build, Test, Push, Deploy, Verify
- Added image tagging strategy: `:latest` and `:<git-short-sha>`
- Integrated Docker registry push (GHCR/Docker Hub)
- Added SSH-based deployment to production VM
- Implemented health check verification stage

#### feat(deploy): Production deployment automation
- Added `scripts/deploy.sh` for automated production deployment
- Implemented graceful container shutdown and startup
- Added health check verification in deployment script
- Created rollback capability documentation

#### feat(docker): Production Docker Compose configuration
- Added `docker-compose.prod.yml` for production deployments
- Configured resource limits for all services
- Set up image-based deployment (pulls from registry)
- Removed development-only port exposures

#### feat(nginx): Organized Nginx configuration
- Moved nginx configs to `nginx/` directory
- Fixed conflicting `proxy_buffering` settings
- Removed invalid environment variable substitution in nginx config
- Improved configuration organization and maintainability

#### docs: Comprehensive CI/CD documentation
- Added `README_CI_CD.md` with complete CI/CD guide
- Created `docs/Jenkins_setup_guide.md` with step-by-step Jenkins setup
- Added `docs/deployment_verification.md` with verification commands
- Created `docs/Jenkins_pipeline_screenshot_instructions.md` for documentation
- Added `.env.sample` with all required environment variables

### Changed

#### fix(nginx): Resolved proxy buffering conflict
- Fixed conflicting `proxy_buffering` directives in `nginx.conf`
- Set `proxy_buffering on` for better performance (was conflicting with `off`)

#### fix(nginx): Removed invalid env var substitution
- Removed `${APP_PORT:-8080}` from nginx config (nginx doesn't support env vars)
- Hardcoded backend port to `8080` in `nginx/default.conf`

#### refactor(docker): Improved Docker Compose organization
- Updated `docker-compose.yml` to use `nginx/` directory structure
- Separated development and production configurations

### Security

#### security(ci): Secure credential management
- All secrets stored in Jenkins credentials (not in repository)
- Documented required credential IDs: `DOCKER_REGISTRY_CRED`, `SSH_DEPLOY_KEY`
- Added credential setup instructions in documentation

#### security(docker): Production hardening
- Enabled resource limits in `docker-compose.prod.yml`
- Removed unnecessary port exposures in production
- Maintained non-root user in backend container

## [Level 1] - 2024-01-XX

### Added - Initial Containerization

#### feat(docker): Multi-stage Dockerfiles
- Added `Dockerfile.backend` with multi-stage build for Rust backend
- Added `Dockerfile.frontend` with multi-stage build for React frontend
- Implemented non-root user (`appuser`) in backend container
- Added health checks to all Dockerfiles

#### feat(compose): Docker Compose orchestration
- Created `docker-compose.yml` with all services
- Configured PostgreSQL, backend, frontend, and nginx services
- Implemented health checks and service dependencies
- Set up named volumes for data persistence

#### feat(nginx): Production-ready Nginx configuration
- Added `nginx.conf` with global settings (gzip, caching, security)
- Created `nginx-server.conf` with reverse proxy configuration
- Implemented security headers (CSP, X-Frame-Options, etc.)
- Added static asset caching (1 year, immutable)
- Configured rate limiting for API endpoints

#### feat(scripts): Helper scripts
- Added `build_and_up.sh` for local development
- Added `down_and_clean.sh` for cleanup
- Added `wait-for.sh` for service dependency management

#### docs: Phase 1 documentation
- Created `README_PHASE1.md` with comprehensive setup guide
- Added `WHAT_CHANGED.md` with implementation details
- Created `CRITICAL_BACKEND_CHANGE.md` for backend binding fix
- Added `QUICK_START_CHECKLIST.md` for quick reference

### Security

#### security(docker): Container security
- Backend runs as non-root user (`appuser`, UID 1000)
- Added `.dockerignore` files to prevent secret leakage
- Excluded sensitive files from Docker build context

---

## Commit Message Format

This project follows conventional commit format:

- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `refactor`: Code refactoring
- `test`: Test additions/changes
- `chore`: Maintenance tasks
- `security`: Security improvements

Example: `feat(ci): Add Jenkins pipeline for automated deployment`

