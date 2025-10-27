# Docker Compose Configuration Explained

## What is docker-compose.yml?

The `docker-compose.yml` file orchestrates multiple Docker containers to work together as a complete development environment. Instead of manually starting each service (database, cache, web app) separately, Docker Compose starts them all with a single command.

---

## Our Services

### 1. **PostgreSQL Database (`db`)**

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

**What it does:**

- Uses PostgreSQL version 16.1 (Alpine Linux - lightweight version)
- Creates a database named `st_intent_harvest_development`
- Sets username: `postgres`, password: `root`
- Stores database data in a persistent volume (`postgres-data`)
- Runs any SQL scripts in `init.sql` folder on first startup
- Exposes port 5432 so you can connect from your host machine
- Checks every 10 seconds if the database is ready
- Automatically restarts if it crashes

**Why we need it:**
Rails needs a database to store all application data (users, work orders, inventory, etc.)

---

### 2. **Redis Cache (`redis`)**

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

**What it does:**

- Uses Redis version 7 (Alpine Linux)
- Stores cached data and background jobs
- Data persists in `redis-data` volume
- Exposes port 6379 for connections
- Checks every 10 seconds if Redis is responding
- Automatically restarts if it crashes

**Why we need it:**
Rails uses Redis for caching (faster page loads), session storage, and background job processing (like sending emails or generating reports).

---

### 3. **Rails Web Application (`web`)**

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

**What it does:**

- Builds a custom Docker image using the `Dockerfile`
- Runs `rails db:prepare` (creates database, runs migrations, seeds data if needed)
- Starts Rails server on `http://0.0.0.0:3000`
- Mounts your code folder (`./`) so changes appear instantly (no rebuild needed)
- Caches Ruby gems in `bundle` volume for faster startups
- Exposes port 3000 - your app is available at `http://localhost:3000`
- **Waits** for PostgreSQL and Redis to be healthy before starting
- Sets environment variables so Rails knows how to connect to database and Redis
- Automatically restarts if it crashes

**Why we need it:**
This is your Rails application - the web server that handles HTTP requests and serves web pages.

---

## Volumes (Data Storage)

```yaml
volumes:
  postgres-data:
  redis-data:
  bundle:
```

**What they do:**

1. **postgres-data**: Stores all database tables and records

   - Survives container restarts and rebuilds
   - Delete it with `docker volume rm st_intent_harvest_postgres-data` to reset database

2. **redis-data**: Stores cached data and background jobs

   - Survives container restarts
   - Can be safely deleted without losing critical data

3. **bundle**: Stores installed Ruby gems
   - Speeds up container rebuilds (don't need to reinstall gems every time)
   - Delete it to force gem reinstallation

**Important:** These volumes persist data even when containers are stopped or removed.

---

## How Services Work Together

```
┌─────────────────────────────────────────┐
│  Your Browser                           │
│  http://localhost:3000                  │
└───────────────┬─────────────────────────┘
                │
                ↓
┌─────────────────────────────────────────┐
│  Web Container (Rails)                  │
│  Port 3000                              │
│  - Handles HTTP requests                │
│  - Runs application code                │
└───────┬─────────────────────┬───────────┘
        │                     │
        ↓                     ↓
┌───────────────────┐  ┌──────────────────┐
│  db Container     │  │  redis Container │
│  PostgreSQL       │  │  Redis Cache     │
│  Port 5432        │  │  Port 6379       │
│  - Stores data    │  │  - Caching       │
│  - Runs queries   │  │  - Background    │
└───────────────────┘  └──────────────────┘
```

**Startup Order:**

1. PostgreSQL starts → waits 10s to be healthy
2. Redis starts → waits 10s to be healthy
3. Rails waits for both to be healthy
4. Rails runs `db:prepare` (migrations, seeds)
5. Rails starts web server
6. You can access `http://localhost:3000`

---

## Common Commands

### Start Everything

```bash
docker compose up
```

Starts all three services (db, redis, web) and shows logs in terminal.

### Start in Background

```bash
docker compose up -d
```

Starts services but runs in background (detached mode).

### Stop Everything

```bash
docker compose down
```

Stops and removes all containers. **Data in volumes is preserved.**

### Rebuild After Code Changes

```bash
docker compose up --build
```

Rebuilds the web container (use when you change Gemfile or Dockerfile).

### View Logs

```bash
docker compose logs -f web
docker compose logs -f db
docker compose logs -f redis
```

Shows logs for specific service. `-f` follows (live updates).

### Check Status

```bash
docker compose ps
```

Shows which services are running and their health status.

### Access Rails Console

```bash
docker compose exec web rails console
```

Opens interactive Rails console to test code.

### Run Migrations

```bash
docker compose exec web rails db:migrate
```

Runs database migrations.

### Reset Database

```bash
docker compose exec web rails db:reset
```

Drops, creates, migrates, and seeds database.

---

## Environment Variables

The `environment` section in the `web` service tells Rails how to connect to other services:

```yaml
environment:
  DATABASE_HOST: db # ← Container name, not "localhost"
  DATABASE_PORT: 5432
  DATABASE_USERNAME: postgres
  DATABASE_PASSWORD: root
  REDIS_URL: redis://redis:6379/0 # ← Container name
  RAILS_ENV: development
```

**Important:** Inside Docker, containers talk to each other using **service names** as hostnames:

- `db` → PostgreSQL container
- `redis` → Redis container
- `web` → Rails container

From your host machine (outside Docker), you use `localhost:5432` and `localhost:6379`.

---

## Health Checks

### Why Health Checks Matter

Without health checks, this could happen:

1. PostgreSQL container starts (but database not ready yet)
2. Rails immediately tries to connect
3. Connection fails → Rails crashes

With health checks:

1. PostgreSQL container starts
2. Every 10 seconds, Docker runs `pg_isready -U postgres`
3. After database responds, health status = "healthy"
4. **Only then** Rails starts
5. Rails successfully connects to database

```yaml
healthcheck:
  test: ["CMD-SHELL", "pg_isready -U postgres"] # Command to check
  interval: 10s # Run check every 10 seconds
  timeout: 5s # Wait max 5 seconds for response
  retries: 5 # Try 5 times before marking unhealthy
```

---

## Volumes vs Bind Mounts

### Named Volume (Data Persistence)

```yaml
volumes:
  - postgres-data:/var/lib/postgresql/data
```

- Managed by Docker
- Persists even after `docker compose down`
- View with `docker volume ls`

### Bind Mount (Live Code Reload)

```yaml
volumes:
  - ./:/rails
```

- Maps your local folder directly into container
- Changes to code files immediately appear in container
- No rebuild needed for code changes

### Bundle Volume (Gem Cache)

```yaml
volumes:
  - bundle:/usr/local/bundle
```

- Caches installed Ruby gems
- Speeds up container rebuilds
- Shared across container recreations

---

## Restart Policies

```yaml
restart: unless-stopped
```

**What it means:**

- If container crashes → automatically restart
- If you manually stop it → stay stopped
- If Docker daemon restarts → restart this container
- If server reboots → restart this container

**Other options:**

- `no` - Never restart (default)
- `always` - Always restart, even after manual stop
- `on-failure` - Only restart on error

---

## Port Mapping

```yaml
ports:
  - "3000:3000"
```

**Format:** `"HOST_PORT:CONTAINER_PORT"`

**What it means:**

- Port 3000 inside container → exposed as port 3000 on host
- Access via `http://localhost:3000`

**Can be changed:**

```yaml
ports:
  - "8080:3000" # Access at http://localhost:8080
```

---

## Summary

### What docker-compose.yml Does:

1. **Defines Services** - PostgreSQL, Redis, and Rails
2. **Sets Up Networking** - Containers can talk to each other by name
3. **Manages Dependencies** - Rails waits for databases to be ready
4. **Configures Storage** - Persistent data in volumes
5. **Exposes Ports** - Makes services accessible from host machine
6. **Sets Environment** - Configuration for each service
7. **Handles Restarts** - Automatically recovers from crashes

### Single Command to Rule Them All:

Instead of:

```bash
# Start PostgreSQL
postgres -D /usr/local/var/postgres

# Start Redis
redis-server

# Start Rails
rails server
```

You just run:

```bash
docker compose up
```

And everything works together! 🚀

---

## Quick Reference

| What You Want          | Command                                    |
| ---------------------- | ------------------------------------------ |
| Start everything       | `docker compose up`                        |
| Start in background    | `docker compose up -d`                     |
| Stop everything        | `docker compose down`                      |
| Rebuild containers     | `docker compose up --build`                |
| View logs              | `docker compose logs -f web`               |
| Check status           | `docker compose ps`                        |
| Rails console          | `docker compose exec web rails console`    |
| Run migrations         | `docker compose exec web rails db:migrate` |
| Access container shell | `docker compose exec web bash`             |
| Reset database         | `docker compose exec web rails db:reset`   |

---

**Last Updated:** October 27, 2025  
**Docker Compose Version:** v2.x
