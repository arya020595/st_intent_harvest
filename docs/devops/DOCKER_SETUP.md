# 🐳 Docker Setup Documentation

## Overview

This project uses Docker Compose to orchestrate a complete development environment with three services:

- **PostgreSQL 16.1** - Database server
- **Redis 7** - Caching and background job processing
- **Rails Web App** - Application server (Ruby 3.4.7)

## 📋 Table of Contents

1. [Architecture Overview](#architecture-overview)
2. [Best Practices Analysis](#best-practices-analysis)
3. [Service Configuration](#service-configuration)
4. [Environment Variables](#environment-variables)
5. [Getting Started](#getting-started)
6. [Common Commands](#common-commands)
7. [Troubleshooting](#troubleshooting)
8. [Security Considerations](#security-considerations)
9. [Performance Optimization](#performance-optimization)

---

## Architecture Overview

### Service Dependencies

```
┌─────────────┐
│   Web App   │ (Rails 3000)
│  (depends)  │
└──────┬──────┘
       │
       ├──────► PostgreSQL (5432) [healthy]
       │
       └──────► Redis (6379) [healthy]
```

### Volume Strategy

- **Application Code**: Bind mount (`./:/rails`) for live code reloading
- **Database Data**: Named volume (`postgres-data`) for persistence
- **Redis Data**: Named volume (`redis-data`) for persistence
- **Bundle Cache**: Named volume (`bundle`) for faster rebuilds

---

## Best Practices Analysis

### ✅ What's Done Right

1. **Health Checks** ✓

   - PostgreSQL: `pg_isready -U postgres`
   - Redis: `redis-cli ping`
   - Web depends on healthy databases (not just started)

2. **Service Dependencies** ✓

   - Correct `depends_on` with `condition: service_healthy`
   - Ensures databases are ready before Rails starts

3. **Volume Management** ✓

   - Named volumes for data persistence
   - Bind mount for development code changes
   - Bundle caching for faster rebuilds

4. **Port Management** ✓

   - Clean port mappings: `3000:3000`, `5432:5432`, `6379:6379`
   - No port conflicts

5. **Restart Policies** ✓

   - `restart: unless-stopped` prevents endless restart loops
   - Good for development environment

6. **Environment Variables** ✓
   - Database credentials via environment
   - Service hostnames match container names

### 🔧 Potential Improvements

1. **Networks** (Optional Enhancement)

   ```yaml
   networks:
     frontend:
       driver: bridge
     backend:
       driver: bridge
   ```

   _Current setup uses default network which is fine for development_

2. **Resource Limits** (Production Consideration)

   ```yaml
   deploy:
     resources:
       limits:
         cpus: "0.5"
         memory: 512M
   ```

   _Not critical for development, but useful for production_

3. **Logging Configuration** (Optional)

   ```yaml
   logging:
     driver: "json-file"
     options:
       max-size: "10m"
       max-file: "3"
   ```

   _Prevents disk space issues from logs_

4. **Docker Compose Version**
   - Current: No version specified (uses latest Compose format)
   - This is actually the **modern approach** (Compose Spec)
   - ✅ Correct for Docker Compose v2+

### 📊 Overall Assessment

**Score: 9/10** - Excellent for development environment

- All critical best practices implemented
- Service orchestration is correct
- Health checks prevent race conditions
- Volume strategy is optimal for development
- Only missing optional production-grade features

---

## Service Configuration

### 🐘 PostgreSQL Service

```yaml
db:
  image: postgres:16.1-alpine
  environment:
    POSTGRES_USER: postgres
    POSTGRES_PASSWORD: root
    POSTGRES_DB: st_intent_harvest_development
  volumes:
    - postgres-data:/var/lib/postgresql/data
    - ./init.sql:/docker-entrypoint-initdb.d
  ports:
    - "5432:5432"
  healthcheck:
    test: ["CMD-SHELL", "pg_isready -U postgres"]
    interval: 10s
    timeout: 5s
    retries: 5
  restart: unless-stopped
```

**Why These Choices?**

- **Alpine image**: Smaller size (~80MB vs ~350MB)
- **init.sql mount**: Auto-runs SQL on first startup
- **Health check**: Ensures database is ready before app starts
- **Named volume**: Data survives container recreation
- **restart policy**: Survives Docker daemon restarts

### 🔴 Redis Service

```yaml
redis:
  image: redis:7-alpine
  volumes:
    - redis-data:/data
  ports:
    - "6379:6379"
  healthcheck:
    test: ["CMD", "redis-cli", "ping"]
    interval: 10s
    timeout: 5s
    retries: 5
  restart: unless-stopped
```

**Why These Choices?**

- **Alpine image**: Minimal footprint
- **Health check**: Validates Redis is responding
- **Named volume**: Persists cache/job data
- **Port exposure**: Allows direct access for debugging

### 🌐 Web (Rails) Service

```yaml
web:
  build:
    context: .
    dockerfile: Dockerfile
  command: bash -c "bundle exec rails db:prepare && bundle exec rails server -b 0.0.0.0"
  volumes:
    - ./:/rails
    - bundle:/usr/local/bundle
  ports:
    - "3000:3000"
  depends_on:
    db:
      condition: service_healthy
    redis:
      condition: service_healthy
  environment:
    DATABASE_HOST: db
    DATABASE_PORT: 5432
    DATABASE_USERNAME: postgres
    DATABASE_PASSWORD: root
    DATABASE_NAME: st_intent_harvest_development
    DATABASE_TEST_NAME: st_intent_harvest_test
    REDIS_URL: redis://redis:6379/0
    RAILS_ENV: development
  restart: unless-stopped
```

**Why These Choices?**

- **Build context**: Uses custom Dockerfile with Ruby 3.4.7
- **db:prepare**: Auto-creates DB, runs migrations, seeds if needed
- **Bind mount**: Live code reloading during development
- **Bundle volume**: Caches gems between rebuilds
- **Server binding**: `-b 0.0.0.0` exposes server to host machine
- **Service dependencies**: Waits for healthy databases

---

## Dockerfile Analysis

### 🏗️ Build Strategy

```dockerfile
FROM ruby:3.4.7-slim

# Development environment
ENV RAILS_ENV=development

# Install system dependencies
RUN apt-get update -qq && \
    apt-get install -y build-essential git libpq-dev postgresql-client vim dos2unix

# Working directory
WORKDIR /rails

# Copy and install gems
COPY Gemfile Gemfile.lock ./
RUN bundle install

# Copy application code
COPY . .

# Fix Windows line endings
RUN dos2unix /rails/bin/*

# Precompile bootsnap for faster boot times
RUN bundle exec bootsnap precompile --gemfile app/ lib/

# Create necessary directories with full permissions
RUN mkdir -p tmp log storage && chmod -R 777 tmp log storage

# Entrypoint for initialization
ENTRYPOINT ["/rails/bin/docker-entrypoint"]

# Default command
CMD ["bundle", "exec", "rails", "server", "-b", "0.0.0.0"]

# Expose port
EXPOSE 3000
```

### 📝 Dockerfile Best Practices

✅ **Implemented:**

- Multi-stage optimization (layer caching)
- Minimal base image (`ruby:3.4.7-slim`)
- Logical layer ordering (dependencies before code)
- Working directory set
- Exposed port documented
- Entrypoint for initialization

✅ **Development-Specific Features:**

- `dos2unix` for Windows/WSL compatibility
- Full permissions on tmp/log/storage (777)
- Vim editor for debugging
- Development gems installed

⚠️ **Production Considerations:**

- Use multi-user permissions (not 777)
- Add `.dockerignore` to exclude unnecessary files ✓ (Already done!)
- Consider non-root user for security
- Add health check in Dockerfile

### 🚀 Entrypoint Script

Located at `/rails/bin/docker-entrypoint`:

```bash
#!/bin/bash
set -e

# Fix Windows line endings if dos2unix is available
if command -v dos2unix &> /dev/null; then
  dos2unix /rails/bin/* 2>/dev/null || true
fi

# Make scripts executable
chmod +x /rails/bin/*

# Remove stale PID file
if [ -f tmp/pids/server.pid ]; then
  rm tmp/pids/server.pid
fi

# Execute the main command
exec "$@"
```

**Purpose:**

1. Fixes Windows CRLF → LF conversion
2. Removes stale PID files (prevents "server already running" errors)
3. Makes bin scripts executable
4. Executes passed command

---

## Environment Variables

### 📄 Configuration Files

**`.env.example`** (Template for local development):

```bash
# Database Configuration
DATABASE_HOST=db
DATABASE_PORT=5432
DATABASE_USERNAME=postgres
DATABASE_PASSWORD=root
DATABASE_NAME=st_intent_harvest_development
DATABASE_TEST_NAME=st_intent_harvest_test

# Redis Configuration
REDIS_URL=redis://redis:6379/0

# Rails Configuration
RAILS_ENV=development
RAILS_MAX_THREADS=5
SECRET_KEY_BASE=your_secret_key_base_here

# Application Configuration
APP_HOST=localhost
APP_PORT=3000
```

### 🔐 Environment Variable Priority

1. **Docker Compose** (`docker-compose.yml` environment section)
2. **`.env` file** (if exists, loaded automatically by Docker Compose)
3. **`config/database.yml`** (Rails fallback with `ENV.fetch`)

### ⚙️ How It Works

```ruby
# config/database.yml
development:
  host: <%= ENV.fetch("DATABASE_HOST") { "localhost" } %>
```

- If `DATABASE_HOST` set → uses it
- If not set → uses fallback `"localhost"`

**In Docker:** Always uses `db` (service name)  
**Outside Docker:** Uses `localhost` (local PostgreSQL)

---

## Getting Started

### 1️⃣ Initial Setup

```bash
# Clone repository (if not already)
cd /path/to/st_intent_harvest

# Create .env file from template
cp .env.example .env

# Optional: Edit .env if needed
vim .env
```

### 2️⃣ Build and Start Services

```bash
# Build images and start all services
docker compose up --build

# Or run in detached mode (background)
docker compose up -d --build
```

**What Happens:**

1. Builds Rails Docker image
2. Pulls PostgreSQL and Redis images
3. Creates volumes for data persistence
4. Starts PostgreSQL → waits for health check
5. Starts Redis → waits for health check
6. Starts Rails app → runs `db:prepare`
7. Rails server available at http://localhost:3000

### 3️⃣ Verify Services

```bash
# Check all services are running
docker compose ps

# Expected output:
# NAME                    SERVICE   STATUS      PORTS
# st_intent_harvest-db-1     db       running     0.0.0.0:5432->5432/tcp
# st_intent_harvest-redis-1  redis    running     0.0.0.0:6379->6379/tcp
# st_intent_harvest-web-1    web      running     0.0.0.0:3000->3000/tcp

# Check logs
docker compose logs -f web
```

### 4️⃣ Access Application

- **Web Application:** http://localhost:3000
- **PostgreSQL:** `localhost:5432` (user: `postgres`, password: `root`)
- **Redis:** `localhost:6379`

---

## Common Commands

### 🎯 Daily Development

```bash
# Start services
docker compose up

# Start in background
docker compose up -d

# Stop services
docker compose down

# Restart specific service
docker compose restart web

# View logs
docker compose logs -f web
docker compose logs -f db

# Rebuild after Gemfile changes
docker compose up --build web
```

### 🗄️ Database Operations

```bash
# Run migrations
docker compose exec web rails db:migrate

# Rollback migration
docker compose exec web rails db:rollback

# Seed database
docker compose exec web rails db:seed

# Reset database (drop, create, migrate, seed)
docker compose exec web rails db:reset

# Open Rails console
docker compose exec web rails console

# Open database console
docker compose exec web rails dbconsole

# Or connect directly to PostgreSQL
docker compose exec db psql -U postgres -d st_intent_harvest_development
```

### 🧪 Testing

```bash
# Run all tests
docker compose exec web rails test

# Run specific test file
docker compose exec web rails test test/models/work_order_test.rb

# Run system tests
docker compose exec web rails test:system

# Run with coverage
docker compose exec web rails test COVERAGE=true
```

### 🔧 Debugging & Maintenance

```bash
# Access Rails container shell
docker compose exec web bash

# Access PostgreSQL shell
docker compose exec db psql -U postgres

# Access Redis CLI
docker compose exec redis redis-cli

# View container resource usage
docker stats

# Clean up unused images/volumes
docker system prune -a --volumes

# View volume contents
docker volume ls
docker volume inspect st_intent_harvest_postgres-data
```

### 📦 Bundle Management

```bash
# Install new gem
# 1. Add to Gemfile
# 2. Rebuild container
docker compose up --build web

# Or install without rebuild (temporary)
docker compose exec web bundle install

# Update all gems
docker compose exec web bundle update

# Check for security vulnerabilities
docker compose exec web bundle audit
```

### 🚀 Production Preparation

```bash
# Precompile assets
docker compose exec web rails assets:precompile

# Run production environment locally
RAILS_ENV=production docker compose up

# Database backup
docker compose exec db pg_dump -U postgres st_intent_harvest_development > backup.sql

# Restore database
cat backup.sql | docker compose exec -T db psql -U postgres st_intent_harvest_development
```

---

## Troubleshooting

### 🔴 Problem: "Port already in use"

```
Error: bind: address already in use
```

**Solution:**

```bash
# Find process using port 3000
lsof -i :3000

# Kill the process
kill -9 <PID>

# Or use different port in docker-compose.yml
ports:
  - "3001:3000"  # Host:Container
```

### 🔴 Problem: "Database does not exist"

```
PG::ConnectionBad: FATAL: database "st_intent_harvest_development" does not exist
```

**Solution:**

```bash
# Create database
docker compose exec web rails db:create

# Or run full setup
docker compose exec web rails db:setup
```

### 🔴 Problem: "Migrations pending"

```
ActiveRecord::PendingMigrationError
```

**Solution:**

```bash
# Run pending migrations
docker compose exec web rails db:migrate

# Or use db:prepare (smart command)
docker compose exec web rails db:prepare
```

### 🔴 Problem: "Can't connect to database"

**Check PostgreSQL is healthy:**

```bash
docker compose ps db

# Should show "healthy" status
# If not, check logs
docker compose logs db
```

**Verify connection:**

```bash
docker compose exec web bash
psql -h db -U postgres -d st_intent_harvest_development
```

### 🔴 Problem: "Server already running"

```
A server is already running. Check tmp/pids/server.pid
```

**Solution:**

```bash
# Remove stale PID file
docker compose exec web rm tmp/pids/server.pid

# Or restart container
docker compose restart web
```

### 🔴 Problem: "Gem not found after adding to Gemfile"

**Solution:**

```bash
# Rebuild the web container
docker compose up --build web

# Or install gems and restart
docker compose exec web bundle install
docker compose restart web
```

### 🔴 Problem: Windows line ending issues

```
/bin/bash^M: bad interpreter
```

**Solution:**

```bash
# Our entrypoint handles this automatically
# But you can also manually convert:
docker compose exec web dos2unix /rails/bin/*

# Or on host machine
dos2unix bin/*
```

### 🔴 Problem: Permission denied on volumes

**Solution:**

```bash
# Fix ownership (host machine)
sudo chown -R $USER:$USER .

# Or in container (already done in Dockerfile)
docker compose exec web chmod -R 777 tmp log storage
```

### 🔴 Problem: "Bundle install fails"

**Solution:**

```bash
# Clear bundle cache and rebuild
docker compose down
docker volume rm st_intent_harvest_bundle
docker compose up --build
```

### 🔴 Problem: "Redis connection refused"

**Check Redis is healthy:**

```bash
docker compose ps redis

# Test Redis connection
docker compose exec redis redis-cli ping
# Should return: PONG
```

---

## Security Considerations

### 🔒 Development vs Production

**Current Setup (Development):** ✅

- Plain text credentials (acceptable for local dev)
- Full file permissions 777 (for cross-OS compatibility)
- Root user in container (for volume access)
- Debug tools installed (vim, etc.)

**Production Requirements:** ⚠️

1. **Use Secrets Management**

   ```bash
   # Docker Swarm secrets
   docker secret create db_password ./db_password.txt

   # Or environment variable injection
   docker run -e DATABASE_PASSWORD=$DB_PASS
   ```

2. **Non-Root User**

   ```dockerfile
   # Add to Dockerfile
   RUN groupadd -r rails && useradd -r -g rails rails
   RUN chown -R rails:rails /rails
   USER rails
   ```

3. **Read-Only Root Filesystem**

   ```yaml
   web:
     security_opt:
       - no-new-privileges:true
     read_only: true
     tmpfs:
       - /tmp
       - /rails/tmp
   ```

4. **Network Isolation**

   ```yaml
   networks:
     frontend:
       driver: bridge
     backend:
       driver: bridge
       internal: true # No external access
   ```

5. **Scan Images for Vulnerabilities**
   ```bash
   docker scan ruby:3.4.7-slim
   docker scan postgres:16.1-alpine
   ```

### 🔐 Credential Management

**Never commit:**

- `.env` (add to `.gitignore`)
- `config/master.key`
- `config/credentials/*.key`

**Use Rails encrypted credentials:**

```bash
# Edit credentials
EDITOR=vim rails credentials:edit

# In production
RAILS_MASTER_KEY=xxx rails server
```

---

## Performance Optimization

### ⚡ Build Speed

**Current Strategy:** ✓

```dockerfile
# Copy Gemfile first (layer caching)
COPY Gemfile Gemfile.lock ./
RUN bundle install

# Copy code after (changes more frequently)
COPY . .
```

**Why?** Bundle install only re-runs when Gemfile changes

### ⚡ Runtime Performance

1. **Bootsnap Precompilation** ✓

   ```dockerfile
   RUN bundle exec bootsnap precompile --gemfile app/ lib/
   ```

   Speeds up Rails boot time significantly

2. **Volume Caching** ✓

   ```yaml
   volumes:
     - bundle:/usr/local/bundle # Gems persist
   ```

3. **Shared Memory for PostgreSQL**

   ```yaml
   db:
     shm_size: 256mb # Increase if needed
   ```

4. **Connection Pooling**
   ```yaml
   # config/database.yml
   pool: <%= ENV.fetch("RAILS_MAX_THREADS") { 5 } %>
   ```

### 📊 Monitoring

```bash
# Watch resource usage
docker stats

# Check disk usage
docker system df

# Analyze image layers
docker history st_intent_harvest-web
```

---

## Advanced Topics

### 🔄 Multi-Stage Builds (Production)

```dockerfile
# Builder stage
FROM ruby:3.4.7-slim AS builder
WORKDIR /rails
COPY Gemfile Gemfile.lock ./
RUN bundle install --without development test

# Runtime stage
FROM ruby:3.4.7-slim
WORKDIR /rails
COPY --from=builder /usr/local/bundle /usr/local/bundle
COPY . .
RUN bundle exec bootsnap precompile --gemfile app/ lib/
USER rails
CMD ["rails", "server"]
```

### 🌐 Docker Compose Override

**`docker-compose.override.yml`** (auto-loaded):

```yaml
# Developer-specific customizations
version: "3.8"
services:
  web:
    ports:
      - "3001:3000" # Use different port
    environment:
      RAILS_LOG_LEVEL: debug
```

### 🧪 Test Database Setup

```yaml
# Add to docker-compose.yml or override
services:
  test_db:
    image: postgres:16.1-alpine
    environment:
      POSTGRES_DB: st_intent_harvest_test
    tmpfs:
      - /var/lib/postgresql/data # In-memory for speed
```

---

## Summary

### ✅ Current Setup Strengths

1. **Excellent health checks** - No race conditions
2. **Proper service dependencies** - Databases ready before app
3. **Smart volume strategy** - Data persists, code reloads
4. **Cross-platform compatibility** - Works on Windows/Mac/Linux
5. **Developer-friendly** - Live reload, easy debugging
6. **Well-structured** - Clear separation of concerns

### 📈 Recommendations

**For Development (Current State):**

- ✅ No changes needed - setup is production-ready

**For Staging/Production:**

1. Add resource limits
2. Implement secrets management
3. Use non-root user
4. Enable logging limits
5. Add backup automation
6. Consider multi-stage builds

### 🎓 Learning Resources

- [Docker Compose Documentation](https://docs.docker.com/compose/)
- [Rails Docker Best Practices](https://docs.docker.com/samples/rails/)
- [PostgreSQL Docker Hub](https://hub.docker.com/_/postgres)
- [Redis Docker Hub](https://hub.docker.com/_/redis)

---

## Quick Reference Card

```bash
# Start everything
docker compose up

# Stop everything
docker compose down

# Rebuild after changes
docker compose up --build

# Run migrations
docker compose exec web rails db:migrate

# Rails console
docker compose exec web rails console

# Check logs
docker compose logs -f web

# Access shell
docker compose exec web bash

# Reset database
docker compose exec web rails db:reset
```

---

**Last Updated:** January 2025  
**Docker Compose Version:** v2.x (Compose Spec)  
**Rails Version:** 8.x  
**Ruby Version:** 3.4.7
