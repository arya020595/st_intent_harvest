# Troubleshooting Guide

Common issues and solutions for development with Docker and Rails.

## Table of Contents

1. [Assets & Images](#assets--images)
2. [Docker & Containers](#docker--containers)
3. [Database Issues](#database-issues)
4. [Gems & Dependencies](#gems--dependencies)
5. [Performance Issues](#performance-issues)

---

## Assets & Images

### Images Not Rendering or Not Updating

**Symptoms:**

- Images show as broken/missing in the browser
- Updated images still show old versions
- CSS changes not reflecting

**Cause:**
Precompiled assets in `public/assets/` take priority over source files in `app/assets/`. If you've run `rails assets:precompile` in development, Rails serves the cached versions instead of fresh files.

**Solution:**

```bash
# Clear precompiled assets
docker compose exec web rails assets:clobber

# Restart the container
docker compose restart web
```

**One-liner:**

```bash
docker compose exec web rails assets:clobber && docker compose restart web
```

**Prevention:**

- Avoid running `rails assets:precompile` in development
- Only precompile assets for production deployments
- In development, Rails serves assets directly from source files

**Verify Fix:**

1. Open your browser's Developer Tools (F12)
2. Go to Network tab
3. Refresh the page (Ctrl+F5 for hard refresh)
4. Check if image loads with HTTP 200 status

---

### CSS/JavaScript Changes Not Reflecting

**Symptoms:**

- CSS changes don't appear in the browser
- JavaScript changes don't work
- Old styles still showing

**Solution:**

```bash
# Clear browser cache (hard refresh)
# Chrome/Firefox: Ctrl + Shift + R (Linux/Windows) or Cmd + Shift + R (Mac)

# If that doesn't work, clear Rails assets cache:
docker compose exec web rails assets:clobber
docker compose restart web
```

**Alternative - Clear Turbo Cache:**

```javascript
// In browser console:
Turbo.clearCache();
```

---

## Docker & Containers

### Container Won't Start

**Symptoms:**

- `docker compose up` fails
- Error: "port already allocated"
- Error: "Cannot start service"

**Solution 1 - Port Conflict:**

```bash
# Check what's using port 3000
lsof -i :3000

# Kill the process
kill -9 <PID>

# Or change port in docker-compose.yml
ports:
  - "3001:3000"  # Use 3001 instead
```

**Solution 2 - Remove Old Containers:**

```bash
# Stop and remove all containers
docker compose down

# Start fresh
docker compose up
```

**Solution 3 - Check Logs:**

```bash
# View recent logs
docker compose logs web --tail=50

# Follow logs in real-time
docker compose logs web -f
```

---

### "Server is already running" Error

**Symptoms:**

- Error: "A server is already running. Check /rails/tmp/pids/server.pid"
- Container exits immediately after starting

**Cause:**
Rails PID file wasn't cleaned up from previous run (usually after container crash).

**Solution:**

This should be handled automatically by `bin/docker-entrypoint`, but if it persists:

```bash
# Remove PID file manually
docker compose exec web rm -f tmp/pids/server.pid

# Restart container
docker compose restart web

# Or rebuild if necessary
docker compose down
docker compose up
```

---

### Changes in Code Not Reflecting

**Symptoms:**

- Code changes don't appear in running application
- Still seeing old behavior after editing files

**Check Volume Mounts:**

```bash
# Verify volumes are mounted correctly
docker compose exec web ls -la /rails

# Should show your project files with recent timestamps
```

**Solution:**

```bash
# Code changes should reflect immediately due to volume mounts
# If not, check docker-compose.yml has:
volumes:
  - .:/rails

# For Ruby files, no restart needed (Spring/bootsnap handles reloading)
# For config files, restart required:
docker compose restart web
```

---

## Database Issues

### "Database does not exist"

**Symptoms:**

- Error: `FATAL: database "<app_name>_development" does not exist`
- Application won't start

**Solution:**

```bash
# Create the database
docker compose exec web rails db:create

# Run migrations
docker compose exec web rails db:migrate

# Seed data (if needed)
docker compose exec web rails db:seed
```

**Full Reset (if corrupted):**

```bash
docker compose exec web rails db:drop db:create db:migrate db:seed
```

---

### Pending Migrations

**Symptoms:**

- Error: "Migrations are pending"
- Page shows migration error

**Solution:**

```bash
# Run pending migrations
docker compose exec web rails db:migrate

# Check migration status
docker compose exec web rails db:migrate:status
```

---

### Can't Connect to PostgreSQL

**Symptoms:**

- Error: "could not connect to server"
- Error: "Connection refused"

**Solution:**

```bash
# Check if postgres container is running
docker compose ps

# Restart postgres
docker compose restart postgres

# Check postgres logs
docker compose logs postgres --tail=50

# If postgres container is failing, recreate it:
docker compose down
docker compose up postgres -d
docker compose up web
```

---

## Gems & Dependencies

### "Run `bundle install` to install missing gems"

**Symptoms:**

- Error after pulling changes with new gems
- Application won't start due to missing gems

**Solution:**

If you have added new gems, you need to install them manually inside the container:

```bash
docker compose exec web bundle install
# Restart container
docker compose restart web
```

---

### Gemfile.lock Conflicts After Pull

**Symptoms:**

- Git merge conflict in `Gemfile.lock`
- Inconsistent gem versions

**Solution:**

```bash
# Accept theirs (recommended for team consistency)
git checkout --theirs Gemfile.lock

# Restart container (auto-installs correct versions)
docker compose restart web

# Or regenerate lock file
docker compose exec web bundle lock --update
docker compose restart web
```

**Prevention:**

- Always pull before making changes
- Don't manually edit `Gemfile.lock`
- Let bundle manage lock file automatically

---

### Can't Install Native Extension Gems

**Symptoms:**

- Error: "Failed to build gem native extension"
- Missing system libraries

**Solution:**

```bash
# Rebuild the Docker image with updated dependencies
docker compose down
docker compose build --no-cache web
docker compose up

# If specific library is missing, add to Dockerfile:
# RUN apt-get update && apt-get install -y <package-name>
```

---

## Performance Issues

### Slow Container Startup

**Symptoms:**

- Container takes minutes to start
- `docker compose up` is very slow

**Common Causes:**

1. Bundle install running (first time or after gem changes)
2. Asset compilation happening
3. Database migrations running

**Solution:**

```bash
# Check what's happening
docker compose logs web -f

# If it's bundle install, wait for it to complete (first time only)
# Subsequent starts will be fast due to bundle_cache volume

# If stuck, restart:
docker compose restart web
```

---

### Application Running Slow

**Symptoms:**

- Pages load slowly
- Requests take several seconds

**Check Database Queries:**

```ruby
# Look for N+1 queries in logs
# Enable verbose query logs in config/environments/development.rb
config.active_record.verbose_query_logs = true
```

**Check Memory:**

```bash
# Check container resource usage
docker stats

# If memory is high, restart container
docker compose restart web
```

**Check for Turbo Cache Issues:**

- Try hard refresh: `Ctrl + Shift + R`
- Or clear Turbo cache in browser console: `Turbo.clearCache()`

---

### Redis Connection Issues

**Symptoms:**

- Error: "Error connecting to Redis"
- Cable/WebSocket features not working

**Solution:**

```bash
# Check if redis is running
docker compose ps

# Restart redis
docker compose restart redis

# Check redis logs
docker compose logs redis --tail=50

# Test redis connection
docker compose exec redis redis-cli ping
# Should return: PONG
```

---

## Quick Commands Reference

```bash
# View logs
docker compose logs web -f                    # Follow web logs
docker compose logs web --tail=50             # Last 50 lines

# Restart services
docker compose restart web                    # Restart web only
docker compose restart                        # Restart all services

# Clean restart
docker compose down                           # Stop all
docker compose up                             # Start all

# Rails commands
docker compose exec web rails db:migrate      # Run migrations
docker compose exec web rails c               # Console
docker compose exec web rails routes          # Show routes
docker compose exec web rails assets:clobber  # Clear assets

# Bundle commands
docker compose exec web bundle install        # Install gems
docker compose exec web bundle update <gem>   # Update specific gem

# Database commands
docker compose exec web rails db:reset        # Drop, create, migrate, seed
docker compose exec postgres psql -U postgres # Access postgres CLI

# Shell access
docker compose exec web bash                  # Access web container shell
docker compose exec postgres bash             # Access postgres container shell
```

---

## Still Having Issues?

### Enable Debug Mode

```bash
# Set environment variables in docker-compose.yml
environment:
  - RAILS_LOG_LEVEL=debug
  - VERBOSE=true

# Restart to apply
docker compose restart web
```

### Check System Resources

```bash
# Check Docker resources
docker stats

# Check disk space
df -h

# Check Docker disk usage
docker system df
```

### Full Reset (Nuclear Option)

**⚠️ Warning: This will delete all data!**

```bash
# Stop everything
docker compose down -v

# Remove all Docker images and volumes
docker system prune -a --volumes

# Rebuild from scratch
docker compose build --no-cache
docker compose up
docker compose exec web rails db:setup
```

---

## Getting Help

If you're still stuck:

1. **Check Logs:** Always start with `docker compose logs web --tail=100`
2. **Search Error:** Copy the error message and search in project documentation
3. **Ask Team:** Share the error message and what you tried
4. **Include Context:** When asking for help, include:
   - What you were trying to do
   - Exact error message
   - Recent changes (git commits, gems added, etc.)
   - Output of `docker compose ps`
   - Relevant logs from `docker compose logs`
