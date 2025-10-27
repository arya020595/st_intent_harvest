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

## Architecture Diagrams

### 🏗️ Container Network Architecture

```
╔═══════════════════════════════════════════════════════════════════╗
║                        HOST MACHINE                               ║
║  (Your Computer - Windows/Mac/Linux)                              ║
╠═══════════════════════════════════════════════════════════════════╣
║                                                                   ║
║  👤 Your Browser                    💻 Database Tools             ║
║  localhost:3000                     localhost:5432                ║
║                                     localhost:6379                ║
║         │                                   │                     ║
║         │                                   │                     ║
║ ════════╪═══════════════════════════════════╪═══════════════════  ║
║         │         DOCKER NETWORK            │                     ║
║         │      (Internal Bridge)            │                     ║
║         │                                   │                     ║
║         ↓                                   ↓                     ║
║   ┌─────────────┐                    ┌──────────────┐            ║
║   │ web:3000    │ ←──────────────→   │  db:5432     │            ║
║   │ (Rails)     │   DATABASE_HOST=db │ (PostgreSQL) │            ║
║   │             │                    │              │            ║
║   │             │                    └──────────────┘            ║
║   │             │                                                ║
║   │             │ ←──────────────→   ┌──────────────┐            ║
║   │             │   REDIS_URL=redis  │ redis:6379   │            ║
║   └─────────────┘                    │ (Redis)      │            ║
║                                      │              │            ║
║                                      └──────────────┘            ║
║                                                                   ║
╠═══════════════════════════════════════════════════════════════════╣
║  📦 VOLUMES (Data Storage)                                        ║
║  • postgres-data (Database files)                                 ║
║  • redis-data (Cache data)                                        ║
║  • bundle (Ruby gems)                                             ║
║  • ./  →  /rails (Your code - bind mount)                         ║
╚═══════════════════════════════════════════════════════════════════╝
```

### 🔄 Service Communication Flow

```
┌─────────────────────────────────────────────────────────────────┐
│  HTTP Request Flow                                              │
└─────────────────────────────────────────────────────────────────┘

1️⃣  User opens browser: http://localhost:3000
    │
    ↓
2️⃣  Request hits HOST PORT 3000
    │
    ↓
3️⃣  Docker forwards to WEB CONTAINER PORT 3000
    │
    ↓
4️⃣  Rails app processes request
    │
    ├──→ Need data?  ──→  Connect to 'db:5432'    ──→ PostgreSQL
    │                      (service name)
    │
    ├──→ Need cache? ──→  Connect to 'redis:6379' ──→ Redis
    │                      (service name)
    │
    ↓
5️⃣  Rails sends response back
    │
    ↓
6️⃣  User sees web page in browser
```

### 📡 Port Mapping Diagram

```
╔════════════════════════════════════════════════════════════════╗
║                    PORT MAPPING EXPLAINED                      ║
╚════════════════════════════════════════════════════════════════╝

┌──────────────────────────────────────────────────────────────┐
│  HOST MACHINE (Your Computer)                                │
│  IP: localhost / 127.0.0.1                                   │
└──────────────────────────────────────────────────────────────┘
           │                │                │
           │                │                │
    localhost:3000   localhost:5432   localhost:6379
           │                │                │
           │                │                │
       Port Mapping     Port Mapping     Port Mapping
        "3000:3000"      "5432:5432"      "6379:6379"
           │                │                │
           ↓                ↓                ↓
┌──────────────────────────────────────────────────────────────┐
│  DOCKER INTERNAL NETWORK                                     │
│  Subnet: 172.x.x.x (auto-assigned)                           │
├──────────────────────────────────────────────────────────────┤
│                                                              │
│  ┌─────────────────┐  ┌──────────────────┐  ┌────────────┐ │
│  │   web           │  │   db             │  │   redis    │ │
│  │   Container     │  │   Container      │  │   Container│ │
│  │                 │  │                  │  │            │ │
│  │   Port: 3000    │  │   Port: 5432     │  │  Port: 6379│ │
│  │   IP: 172.x.x.2 │  │   IP: 172.x.x.3  │  │  IP:172.x.4│ │
│  │                 │  │                  │  │            │ │
│  │   Hostname: web │  │   Hostname: db   │  │ Hostname:  │ │
│  │                 │  │                  │  │   redis    │ │
│  └─────────────────┘  └──────────────────┘  └────────────┘ │
│                                                              │
└──────────────────────────────────────────────────────────────┘

═══════════════════════════════════════════════════════════════

🔍 HOW EACH SERVICE ACCESSES OTHERS:

From HOST MACHINE:
  • Web app     → http://localhost:3000
  • PostgreSQL  → postgresql://localhost:5432
  • Redis       → redis://localhost:6379

From WEB CONTAINER (inside Docker):
  • PostgreSQL  → postgresql://db:5432        (uses service name!)
  • Redis       → redis://redis:6379          (uses service name!)

From DB CONTAINER (inside Docker):
  • Web app     → http://web:3000             (uses service name!)
  • Redis       → redis://redis:6379          (uses service name!)

═══════════════════════════════════════════════════════════════

📌 KEY CONCEPTS:

1. HOST PORT (left side of ':')
   → The port on YOUR computer
   → What you type in browser/tools

2. CONTAINER PORT (right side of ':')
   → The port INSIDE the container
   → What the service listens on

3. SERVICE NAME = HOSTNAME
   → Docker automatically creates DNS
   → Containers use names: 'db', 'redis', 'web'
   → No need for IP addresses!

4. EXAMPLE PORT MAPPING:
   ports:
     - "8080:3000"

   HOST: localhost:8080  →  CONTAINER: 0.0.0.0:3000

   Your browser:  http://localhost:8080
   Inside Rails:  Server runs on 0.0.0.0:3000
```

### ⏱️ Startup Sequence with Health Checks

```
TIME  │  SERVICE      │  STATUS           │  ACTION
──────┼───────────────┼───────────────────┼─────────────────────────
00:00 │  docker       │  Starting...      │  docker compose up
      │               │                   │
00:01 │  db           │  🟡 Starting      │  PostgreSQL initializing
00:02 │  redis        │  🟡 Starting      │  Redis initializing
00:03 │  web          │  ⏸️  Waiting      │  Depends on db & redis
      │               │                   │
00:05 │  db           │  🔍 Health Check  │  pg_isready -U postgres
00:05 │  db           │  ❌ Not ready     │  Retry in 10s...
      │               │                   │
00:06 │  redis        │  🔍 Health Check  │  redis-cli ping
00:06 │  redis        │  ✅ Healthy       │  PONG received
      │               │                   │
00:15 │  db           │  🔍 Health Check  │  pg_isready -U postgres
00:15 │  db           │  ✅ Healthy       │  Database ready!
      │               │                   │
00:16 │  web          │  🟢 Starting      │  Dependencies healthy
00:16 │  web          │  📦 Running       │  bundle exec rails db:prepare
00:20 │  web          │  🚀 Running       │  rails server -b 0.0.0.0
      │               │                   │
00:22 │  ALL          │  ✅ READY         │  http://localhost:3000
──────┴───────────────┴───────────────────┴─────────────────────────

Legend:
  🟡 Starting      - Container starting up
  ⏸️  Waiting      - Waiting for dependencies
  🔍 Health Check  - Running health check command
  ❌ Not ready     - Health check failed
  ✅ Healthy       - Health check passed
  🟢 Starting      - Now starting this service
  📦 Running       - Executing command
  🚀 Running       - Server running
```

### 💾 Volume Architecture

```
╔═══════════════════════════════════════════════════════════════╗
║                    VOLUME TYPES & USAGE                       ║
╚═══════════════════════════════════════════════════════════════╝

1️⃣  BIND MOUNT (Live Code Sync)
┌────────────────────────────────────────────────────────────┐
│  HOST MACHINE                                              │
│  /home/user/st_intent_harvest/                             │
│  ├── app/                                                  │
│  ├── config/                                               │
│  ├── db/                                                   │
│  └── ...                                                   │
└────────────────────────────────────────────────────────────┘
                      │
                      │  volumes:
                      │    - ./:/rails
                      │
                      ↓
┌────────────────────────────────────────────────────────────┐
│  WEB CONTAINER                                             │
│  /rails/                                                   │
│  ├── app/          ← Same files, instant sync!             │
│  ├── config/                                               │
│  ├── db/                                                   │
│  └── ...                                                   │
└────────────────────────────────────────────────────────────┘

✅ Changes on host → immediately visible in container
✅ No rebuild needed for code changes


2️⃣  NAMED VOLUME (Data Persistence)
┌────────────────────────────────────────────────────────────┐
│  DOCKER MANAGED STORAGE                                    │
│  /var/lib/docker/volumes/                                  │
│                                                            │
│  📦 st_intent_harvest_postgres-data/                       │
│     └── Database files (tables, indexes, etc.)            │
│                                                            │
│  📦 st_intent_harvest_redis-data/                          │
│     └── Cache data & background jobs                      │
│                                                            │
│  📦 st_intent_harvest_bundle/                              │
│     └── Ruby gems (500+ gem files)                        │
└────────────────────────────────────────────────────────────┘
                      │
                      │  Mount into containers
                      │
        ┌─────────────┼─────────────┐
        │             │             │
        ↓             ↓             ↓
   ┌────────┐   ┌─────────┐   ┌──────────┐
   │   db   │   │  redis  │   │   web    │
   │        │   │         │   │          │
   │ /var/  │   │ /data   │   │ /usr/    │
   │ lib/   │   │         │   │ local/   │
   │ post.. │   │         │   │ bundle   │
   └────────┘   └─────────┘   └──────────┘

✅ Data survives container deletion
✅ Shared between container recreations
✅ Managed by Docker (automatic cleanup)


3️⃣  VOLUME LIFECYCLE
┌─────────────────────────────────────────────────────────────┐
│  COMMAND                     │  EFFECT ON VOLUMES           │
├──────────────────────────────┼──────────────────────────────┤
│  docker compose up           │  Creates if not exists       │
│  docker compose down         │  Volumes KEPT                │
│  docker compose down -v      │  Volumes DELETED ⚠️          │
│  docker volume ls            │  List all volumes            │
│  docker volume rm <name>     │  Delete specific volume      │
│  docker volume prune         │  Remove unused volumes       │
└─────────────────────────────────────────────────────────────┘
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

### 🔌 Detailed Port Mapping Examples

```
╔═══════════════════════════════════════════════════════════════╗
║                 PORT MAPPING SCENARIOS                        ║
╚═══════════════════════════════════════════════════════════════╝

SCENARIO 1: Same Port (Default)
──────────────────────────────────────────────────────────────
docker-compose.yml:
  ports:
    - "3000:3000"

┌─────────────────┐         ┌──────────────────┐
│  HOST MACHINE   │         │  WEB CONTAINER   │
│                 │         │                  │
│  localhost:3000 │ ═════►  │  0.0.0.0:3000   │
│                 │         │  (Rails server)  │
└─────────────────┘         └──────────────────┘

Access: http://localhost:3000
Inside container: rails server -b 0.0.0.0


SCENARIO 2: Different Port (Custom)
──────────────────────────────────────────────────────────────
docker-compose.yml:
  ports:
    - "8080:3000"

┌─────────────────┐         ┌──────────────────┐
│  HOST MACHINE   │         │  WEB CONTAINER   │
│                 │         │                  │
│  localhost:8080 │ ═════►  │  0.0.0.0:3000   │
│                 │         │  (Rails server)  │
└─────────────────┘         └──────────────────┘

Access: http://localhost:8080
Inside container: rails server -b 0.0.0.0 (still port 3000)


SCENARIO 3: All Services Port Mapping
──────────────────────────────────────────────────────────────

┌══════════════════════════════════════════════════════════════┐
│                      HOST MACHINE                            │
│              (Your Computer - localhost)                     │
└══════════════════════════════════════════════════════════════┘
                             │
          ┌──────────────────┼──────────────────┐
          │                  │                  │
    localhost:3000     localhost:5432     localhost:6379
          │                  │                  │
       Port Map           Port Map          Port Map
      "3000:3000"        "5432:5432"       "6379:6379"
          │                  │                  │
          ↓                  ↓                  ↓
┌═══════════════════════════════════════════════════════════════┐
│              DOCKER NETWORK (bridge)                          │
├───────────────────────────────────────────────────────────────┤
│                                                               │
│  ┌────────────────┐  ┌─────────────────┐  ┌──────────────┐  │
│  │  web:3000      │  │  db:5432        │  │ redis:6379   │  │
│  │  (Rails)       │  │  (PostgreSQL)   │  │ (Redis)      │  │
│  │                │  │                 │  │              │  │
│  │  Listens on:   │  │  Listens on:    │  │ Listens on:  │  │
│  │  0.0.0.0:3000  │  │  0.0.0.0:5432   │  │ 0.0.0.0:6379 │  │
│  └────────────────┘  └─────────────────┘  └──────────────┘  │
│                                                               │
└═══════════════════════════════════════════════════════════════┘

═══════════════════════════════════════════════════════════════

🌐 ACCESS PATTERNS:

FROM YOUR BROWSER/HOST:
  Web App:      http://localhost:3000
  PostgreSQL:   psql -h localhost -p 5432 -U postgres
  Redis:        redis-cli -h localhost -p 6379

FROM WEB CONTAINER (Rails code):
  config/database.yml:
    host: db              ← Service name, NOT localhost!
    port: 5432

  REDIS_URL: redis://redis:6379/0   ← Service name!

FROM DB CONTAINER:
  # If PostgreSQL needs to connect to Redis
  redis://redis:6379

═══════════════════════════════════════════════════════════════

⚠️  COMMON MISTAKES:

❌ Inside container, using localhost:
   DATABASE_HOST: localhost   # WRONG! Won't work!

✅ Inside container, using service name:
   DATABASE_HOST: db          # CORRECT!

❌ Accessing from host with service name:
   http://web:3000            # WRONG! 'web' unknown on host

✅ Accessing from host with localhost:
   http://localhost:3000      # CORRECT!
```

### 📊 Complete Connection Matrix

```
╔════════════════════════════════════════════════════════════════╗
║              WHO CONNECTS TO WHOM - HOW?                       ║
╚════════════════════════════════════════════════════════════════╝

┌────────────────┬──────────────┬───────────────┬──────────────┐
│ FROM           │ TO WEB       │ TO DB         │ TO REDIS     │
├────────────────┼──────────────┼───────────────┼──────────────┤
│ Your Browser   │ localhost:   │ localhost:    │ localhost:   │
│ (Host)         │ 3000         │ 5432          │ 6379         │
├────────────────┼──────────────┼───────────────┼──────────────┤
│ Web Container  │ localhost:   │ db:5432       │ redis:6379   │
│ (Rails)        │ 3000         │               │              │
├────────────────┼──────────────┼───────────────┼──────────────┤
│ DB Container   │ web:3000     │ localhost:    │ redis:6379   │
│ (PostgreSQL)   │              │ 5432          │              │
├────────────────┼──────────────┼───────────────┼──────────────┤
│ Redis          │ web:3000     │ db:5432       │ localhost:   │
│ Container      │              │               │ 6379         │
└────────────────┴──────────────┴───────────────┴──────────────┘

📝 NOTES:
• "localhost" = same container
• "service_name" = different container in same network
• "localhost:port" = from host machine (your computer)
```

### 🔧 Testing Port Mappings

```bash
# From your host machine (outside Docker)
# ─────────────────────────────────────────

# Test web app
curl http://localhost:3000

# Test PostgreSQL connection
psql -h localhost -p 5432 -U postgres -d st_intent_harvest_development

# Test Redis connection
redis-cli -h localhost -p 6379 ping
# Should return: PONG


# From inside web container
# ─────────────────────────────────────────

# Access the container shell
docker compose exec web bash

# Test connection to PostgreSQL (using service name!)
psql -h db -p 5432 -U postgres -d st_intent_harvest_development

# Test Redis connection (using service name!)
redis-cli -h redis -p 6379 ping
# Should return: PONG

# Test Rails database connection
rails runner "puts ActiveRecord::Base.connection.execute('SELECT 1').values"
# Should return: [[1]]
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
