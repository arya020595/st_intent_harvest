# Docker Development Guide

Complete guide for developing the ST Intent Harvest application using Docker.

## 📋 Table of Contents

- [How Docker Works](#how-docker-works)
- [Prerequisites](#prerequisites)
- [First Time Setup](#first-time-setup)
- [Daily Development Workflow](#daily-development-workflow)
- [Common Commands](#common-commands)
- [Database Management](#database-management)
- [Troubleshooting](#troubleshooting)
- [Advanced Topics](#advanced-topics)

---

## 🐳 How Docker Works

### Docker Architecture Overview

Docker containers allow us to package the application with all its dependencies, ensuring consistency across all development environments.

```
┌─────────────────────────────────────────────────────────────────┐
│                      Your Computer (Host)                        │
│                                                                   │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │                    Docker Engine                            │ │
│  │                                                              │ │
│  │  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐     │ │
│  │  │  Container   │  │  Container   │  │  Container   │     │ │
│  │  │    (web)     │  │    (db)      │  │   (redis)    │     │ │
│  │  │              │  │              │  │              │     │ │
│  │  │  Rails 8.1   │  │ PostgreSQL   │  │   Redis 7    │     │ │
│  │  │  Ruby 3.4.7  │  │     16.1     │  │              │     │ │
│  │  │  Port: 3000  │  │  Port: 5432  │  │  Port: 6379  │     │ │
│  │  │              │  │              │  │              │     │ │
│  │  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘     │ │
│  │         │                  │                  │             │ │
│  │         └──────────────────┼──────────────────┘             │ │
│  │                            │                                │ │
│  │                    Network Bridge                           │ │
│  │              (st_intent_harvest_network)                    │ │
│  └──────────────────────────────────────────────────────────────┘ │
│                                                                   │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │                   Docker Volumes                            │ │
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐        │ │
│  │  │  postgres   │  │    redis    │  │   bundle    │        │ │
│  │  │    _data    │  │    _data    │  │   _cache    │        │ │
│  │  └─────────────┘  └─────────────┘  └─────────────┘        │ │
│  └────────────────────────────────────────────────────────────┘ │
│                                                                   │
│  Your Project Files: /home/user/st_intent_harvest                │
│           ↕                                                       │
│  Mounted in Container: /rails                                    │
└───────────────────────────────────────────────────────────────────┘
```

### What is a Container?

A **container** is like a lightweight virtual machine that runs your application in an isolated environment.

```
┌─────────────────────────────────────────────────────────────┐
│  Traditional Setup (Without Docker)                         │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  Developer A's Machine:                                      │
│  ├─ Ruby 3.3.0 ❌ (Different version!)                      │
│  ├─ PostgreSQL 14 ❌ (Different version!)                   │
│  └─ Manually installed gems                                 │
│                                                              │
│  Developer B's Machine:                                      │
│  ├─ Ruby 3.4.7 ✅                                           │
│  ├─ PostgreSQL 16 ✅                                        │
│  └─ Different gem versions ❌                               │
│                                                              │
│  ⚠️  "It works on my machine!" syndrome                     │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│  With Docker (Consistent Environment)                       │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  All Developers:                                             │
│  ├─ Same Ruby 3.4.7 ✅                                      │
│  ├─ Same PostgreSQL 16.1 ✅                                 │
│  ├─ Same Redis 7 ✅                                         │
│  └─ Same gem versions ✅                                    │
│                                                              │
│  ✅ Guaranteed consistency across all machines              │
└─────────────────────────────────────────────────────────────┘
```

### Docker Compose Services

Our application uses **3 main services** defined in `docker-compose.yml`:

```
┌────────────────────────────────────────────────────────────────┐
│                   docker-compose.yml                            │
└────────────────────────────────────────────────────────────────┘
                           │
           ┌───────────────┼───────────────┐
           │               │               │
           ▼               ▼               ▼
    ┌──────────┐    ┌──────────┐    ┌──────────┐
    │   web    │    │    db    │    │  redis   │
    │ (Rails)  │    │(Postgres)│    │ (Cache)  │
    └──────────┘    └──────────┘    └──────────┘
         │               │               │
         └───────────────┴───────────────┘
                     │
              Shared Network
         (Containers can talk to
              each other)
```

#### Service Details:

**1. Web Service (Rails Application)**

```
┌─────────────────────────────────────┐
│  Container: web                      │
├─────────────────────────────────────┤
│  Image: Built from Dockerfile       │
│  Base: Ruby 3.4.7                   │
│  Port: 3000 (exposed to host)       │
│  Volume Mounts:                      │
│    ├─ ./  → /rails (code sync)      │
│    └─ bundle_cache (gems)           │
│  Environment Variables:              │
│    ├─ DATABASE_HOST=db              │
│    ├─ DATABASE_PASSWORD=root        │
│    └─ REDIS_URL=redis://redis:6379  │
└─────────────────────────────────────┘
```

**2. Database Service (PostgreSQL)**

```
┌─────────────────────────────────────┐
│  Container: db                       │
├─────────────────────────────────────┤
│  Image: postgres:16.1-alpine        │
│  Port: 5432 (exposed to host)       │
│  Volume: postgres_data              │
│  Environment Variables:              │
│    ├─ POSTGRES_USER=postgres        │
│    ├─ POSTGRES_PASSWORD=root        │
│    └─ POSTGRES_DB=st_intent_...     │
└─────────────────────────────────────┘
```

**3. Redis Service (Cache)**

```
┌─────────────────────────────────────┐
│  Container: redis                    │
├─────────────────────────────────────┤
│  Image: redis:7-alpine              │
│  Port: 6379 (exposed to host)       │
│  Volume: redis_data                 │
│  Purpose: Caching, sessions         │
└─────────────────────────────────────┘
```

### How Code Syncing Works

Docker **volume mounts** allow real-time code synchronization:

```
┌─────────────────────────────────────────────────────────────┐
│  Your Local Machine                                          │
│                                                              │
│  /home/user/st_intent_harvest/                              │
│  ├─ app/                                                     │
│  │   ├─ controllers/                                        │
│  │   │   └─ dashboard_controller.rb  ← You edit this       │
│  │   ├─ models/                                             │
│  │   └─ views/                                              │
│  ├─ config/                                                 │
│  └─ db/                                                     │
│                                                              │
└──────────────────┬──────────────────────────────────────────┘
                   │
                   │ Volume Mount (Real-time sync)
                   │
┌──────────────────▼──────────────────────────────────────────┐
│  Docker Container (web)                                      │
│                                                              │
│  /rails/                                                     │
│  ├─ app/                                                     │
│  │   ├─ controllers/                                        │
│  │   │   └─ dashboard_controller.rb  ← Changes appear here │
│  │   ├─ models/                                             │
│  │   └─ views/                                              │
│  ├─ config/                                                 │
│  └─ db/                                                     │
│                                                              │
│  Rails Server: Detects changes and auto-reloads! ✅         │
└─────────────────────────────────────────────────────────────┘
```

**Result**: Edit files locally → Changes automatically reflected in container → Browser refresh shows updates! 🚀

### Docker Workflow Step-by-Step

```
1. docker compose up -d
   │
   ▼
┌─────────────────────────────────────┐
│  Docker reads docker-compose.yml    │
└─────────────────────────────────────┘
   │
   ▼
┌─────────────────────────────────────┐
│  Creates network bridge              │
│  (st_intent_harvest_network)        │
└─────────────────────────────────────┘
   │
   ▼
┌─────────────────────────────────────┐
│  Pulls/builds images if needed       │
│  ├─ postgres:16.1-alpine            │
│  ├─ redis:7-alpine                  │
│  └─ web (from Dockerfile)           │
└─────────────────────────────────────┘
   │
   ▼
┌─────────────────────────────────────┐
│  Creates containers                  │
│  ├─ db (PostgreSQL)    ✅           │
│  ├─ redis (Redis)      ✅           │
│  └─ web (Rails)        ✅           │
└─────────────────────────────────────┘
   │
   ▼
┌─────────────────────────────────────┐
│  Mounts volumes                      │
│  ├─ Your code → /rails              │
│  ├─ postgres_data (database)        │
│  ├─ redis_data (cache)              │
│  └─ bundle_cache (gems)             │
└─────────────────────────────────────┘
   │
   ▼
┌─────────────────────────────────────┐
│  Starts services in order:           │
│  1. db (waits for health check)     │
│  2. redis (waits for health check)  │
│  3. web (starts Rails server)       │
└─────────────────────────────────────┘
   │
   ▼
┌─────────────────────────────────────┐
│  Application Ready! 🎉               │
│  Visit http://localhost:3000        │
└─────────────────────────────────────┘
```

### What Happens When You Make Changes?

```
┌──────────────────────────────────────────────────────────────┐
│  Scenario 1: Edit a View (.html.erb)                         │
└──────────────────────────────────────────────────────────────┘

You edit:    app/views/dashboard/index.html.erb
              ↓
Volume sync: File instantly synced to container
              ↓
Rails:       Detects change, no restart needed
              ↓
Browser:     Refresh page → See changes ✅


┌──────────────────────────────────────────────────────────────┐
│  Scenario 2: Edit a Controller/Model                         │
└──────────────────────────────────────────────────────────────┘

You edit:    app/controllers/dashboard_controller.rb
              ↓
Volume sync: File instantly synced to container
              ↓
Rails:       Auto-reloads code in development mode
              ↓
Browser:     Refresh page → See changes ✅


┌──────────────────────────────────────────────────────────────┐
│  Scenario 3: Update Gemfile (Add new gem)                    │
└──────────────────────────────────────────────────────────────┘

You edit:    Gemfile
              ↓
Run:         docker compose exec web bundle install
              ↓
Rails:       Restart container: docker compose restart web
              ↓
Done:        New gem available ✅


┌──────────────────────────────────────────────────────────────┐
│  Scenario 4: Create new Migration                            │
└──────────────────────────────────────────────────────────────┘

You run:     docker compose exec web rails g migration ...
              ↓
Edit:        Migration file created in db/migrate/
              ↓
Run:         docker compose exec web rails db:migrate
              ↓
Done:        Database schema updated ✅
```

### Docker vs Traditional Development

```
┌────────────────────────────────────────────────────────────────┐
│                    Traditional Development                      │
├────────────────────────────────────────────────────────────────┤
│                                                                 │
│  Setup Time: 2-4 hours per developer                           │
│                                                                 │
│  Steps:                                                         │
│  1. Install Ruby (rbenv/rvm)                     ⏱️  30 min    │
│  2. Install PostgreSQL                           ⏱️  20 min    │
│  3. Configure PostgreSQL                         ⏱️  15 min    │
│  4. Install Redis                                ⏱️  10 min    │
│  5. Install system dependencies                  ⏱️  20 min    │
│  6. Bundle install (troubleshoot errors)         ⏱️  45 min    │
│  7. Database setup                               ⏱️  10 min    │
│  8. Debug environment issues                     ⏱️  30 min    │
│                                                                 │
│  Problems:                                                      │
│  ❌ Different Ruby versions                                    │
│  ❌ Different PostgreSQL versions                              │
│  ❌ OS-specific issues                                         │
│  ❌ "Works on my machine" syndrome                             │
│  ❌ Hard to onboard new developers                             │
└────────────────────────────────────────────────────────────────┘

┌────────────────────────────────────────────────────────────────┐
│                   Docker Development                            │
├────────────────────────────────────────────────────────────────┤
│                                                                 │
│  Setup Time: 10-15 minutes per developer                       │
│                                                                 │
│  Steps:                                                         │
│  1. Install Docker Desktop                       ⏱️  5 min     │
│  2. Clone repository                             ⏱️  1 min     │
│  3. cp .env.example .env                         ⏱️  1 sec     │
│  4. docker compose up -d                         ⏱️  8 min     │
│  5. docker compose exec web rails db:setup       ⏱️  30 sec    │
│                                                                 │
│  Benefits:                                                      │
│  ✅ Same environment for everyone                              │
│  ✅ Works on Windows, macOS, Linux                             │
│  ✅ Isolated from host system                                  │
│  ✅ Easy to onboard new developers                             │
│  ✅ No version conflicts                                       │
└────────────────────────────────────────────────────────────────┘
```

### Key Concepts Summary

| Concept                   | Description                          | Example                      |
| ------------------------- | ------------------------------------ | ---------------------------- |
| **Image**                 | Blueprint for a container            | `ruby:3.4.7-slim`            |
| **Container**             | Running instance of an image         | Your Rails app running       |
| **Volume**                | Persistent data storage              | Database data, gem cache     |
| **Network**               | Allows containers to communicate     | `st_intent_harvest_network`  |
| **Port Mapping**          | Expose container port to host        | `3000:3000` → localhost:3000 |
| **Environment Variables** | Configuration passed to containers   | `DATABASE_HOST=db`           |
| **docker-compose.yml**    | Defines all services & configuration | Your project's Docker config |
| **Dockerfile**            | Instructions to build an image       | How to build Rails image     |

---

## 🔧 Prerequisites

### Required Software

1. **Docker Desktop**

   - **Windows**: [Download Docker Desktop for Windows](https://docs.docker.com/desktop/install/windows-install/)
     - Requires WSL 2 (Windows Subsystem for Linux)
   - **macOS**: [Download Docker Desktop for Mac](https://docs.docker.com/desktop/install/mac-install/)
   - **Linux**: [Install Docker Engine](https://docs.docker.com/engine/install/) and [Docker Compose](https://docs.docker.com/compose/install/)

2. **Git** - For version control
   - Windows: [Git for Windows](https://git-scm.com/download/win)
   - macOS: `brew install git`
   - Linux: `sudo apt-get install git`

### System Requirements

- **RAM**: Minimum 4GB, Recommended 8GB+
- **Disk Space**: At least 10GB free
- **Docker Memory Allocation**: At least 4GB (configurable in Docker Desktop)

---

## 🚀 First Time Setup

### Step 1: Clone Repository

```bash
# Clone the repository
git clone https://github.com/arya020595/st_intent_harvest.git
cd st_intent_harvest
```

### Step 2: Create Environment File

```bash
# Copy the environment template
cp .env.example .env
```

**Note**: The default `.env.example` is already configured for Docker. You don't need to modify it unless you have specific requirements.

### Step 3: Build Docker Images

```bash
# Build all Docker images (this takes 5-10 minutes on first run)
docker compose build
```

**What this does**:

- Downloads Ruby 3.4.7 base image
- Installs system dependencies (PostgreSQL client, build tools, etc.)
- Installs all Ruby gems from `Gemfile.lock`
- Prepares the application image

### Step 4: Start Services

```bash
# Start all services (PostgreSQL, Redis, Rails app)
docker compose up -d
```

**Services started**:

- `db` - PostgreSQL 16.1 database (port 5432)
- `redis` - Redis 7 for caching (port 6379)
- `web` - Rails 8.1 application (port 3000)

### Step 5: Create & Setup Database

```bash
# Create database
docker compose exec web rails db:create

# Run migrations
docker compose exec web rails db:migrate

# Seed initial data (users, roles, permissions)
docker compose exec web rails db:seed

# Reset database (drop, create, migrate, seed)
docker compose exec web rails db:reset
```

### Step 6: Access Application

Open your browser and visit:

```
http://localhost:3000
```

**Default Login Credentials** (created by seed):

```
Email: admin@example.com
Password: password123
```

---

## 💼 Daily Development Workflow

### Starting Work

```bash
# Start all services
docker compose up -d

# Check if services are running
docker compose ps

# View logs (optional)
docker compose logs -f web
```

**Expected output from `docker compose ps`:**

```
NAME                        STATUS          PORTS
st_intent_harvest-db-1      Up (healthy)    0.0.0.0:5432->5432/tcp
st_intent_harvest-redis-1   Up (healthy)    0.0.0.0:6379->6379/tcp
st_intent_harvest-web-1     Up              0.0.0.0:3000->3000/tcp
```

### Verifying Services are Running

#### Check Container Status

```bash
# Show running containers
docker compose ps

# Show all containers (including stopped)
docker compose ps -a
```

#### View Logs

```bash
# View all logs
docker compose logs

# Follow logs (live tail)
docker compose logs -f

# View only web app logs
docker compose logs -f web

# View last 50 lines
docker compose logs --tail=50 web

# View database logs
docker compose logs db

# View Redis logs
docker compose logs redis
```

#### Access Your Application

Open your browser and visit:

- **Application**: http://localhost:3000
- **Health Check**: http://localhost:3000/up
- **PostgreSQL**: Use any DB client connecting to `localhost:5432`

#### Check Individual Services

```bash
# Check Rails version
docker compose exec web rails -v

# Check database connection
docker compose exec db psql -U postgres -c "SELECT version();"

# Check Redis is responding
docker compose exec redis redis-cli ping
# Should return: PONG
```

#### Quick Health Check

```bash
# See resource usage (CPU, memory)
docker stats

# Check if Rails is responding
curl http://localhost:3000/up
# Should return: ok

# Check all services status
docker compose ps
```

#### Detailed Container Inspection

```bash
# Inspect web container details
docker inspect st_intent_harvest-web-1

# Check logs for errors
docker compose logs --tail=100 web

# Access container shell
docker compose exec web bash
```

### Making Code Changes

Your code is **automatically synced** to the Docker container via volume mounts. Just edit files locally and refresh your browser!

**No restart needed for**:

- Views (`.html.erb`, `.haml`)
- Controllers
- Models
- Most Ruby code changes

**Restart needed for**:

- `Gemfile` changes
- `config/` changes
- Route changes (sometimes)

```bash
# Restart Rails server
docker compose restart web
```

### Stopping Work

```bash
# Stop all services (keeps data)
docker compose down

# Stop and remove volumes (deletes database!)
docker compose down -v
```

---

## 📚 Common Commands

### Service Management

```bash
# Start services
docker compose up -d

# Start with logs visible
docker compose up

# Stop services
docker compose down

# Restart specific service
docker compose restart web

# View service status
docker compose ps

# View logs
docker compose logs web           # Web logs only
docker compose logs -f web        # Follow web logs
docker compose logs --tail=100    # Last 100 lines
```

### Rails Commands

```bash
# Rails console
docker compose exec web rails console

# Run migrations
docker compose exec web rails db:migrate

# Rollback migration
docker compose exec web rails db:rollback

# Create a new migration
docker compose exec web rails generate migration AddColumnToTable

# Generate model
docker compose exec web rails generate model ModelName

# Generate controller
docker compose exec web rails generate controller ControllerName

# View routes
docker compose exec web rails routes

# Run tests
docker compose exec web rails test

# Run specific test
docker compose exec web rails test test/models/user_test.rb
```

### Bundle (Gem) Commands

```bash
# Install new gems after updating Gemfile
docker compose exec web bundle install

# Update specific gem
docker compose exec web bundle update gem_name

# Check outdated gems
docker compose exec web bundle outdated

# Show installed gems
docker compose exec web bundle list
```

### Bash Access

```bash
# Access container shell
docker compose exec web bash

# Once inside, you can run any command:
# rails console
# bundle install
# rake routes
# etc.

# Exit shell
exit
```

---

## 🗄️ Database Management

### PostgreSQL Access

#### Option 1: Using Rails Console

```bash
docker compose exec web rails console

# In console:
User.count
User.all
WorkOrder.where(work_order_status: 'pending')
```

#### Option 2: Using PostgreSQL Client (psql)

```bash
# Access PostgreSQL directly
docker compose exec db psql -U postgres -d st_intent_harvest_development

# Common psql commands:
\dt                              # List all tables
\d table_name                    # Describe table
\l                               # List databases
\q                               # Quit
```

#### Option 3: Using pgAdmin or TablePlus

Connect with these credentials (from `.env`):

```
Host: localhost
Port: 5432
Username: postgres
Password: root
Database: st_intent_harvest_development
```

### Database Operations

```bash
# Create database
docker compose exec web rails db:create

# Drop database (destructive!)
docker compose exec web rails db:drop

# Reset database (drop, create, migrate, seed)
docker compose exec web rails db:reset

# Migrate database
docker compose exec web rails db:migrate

# Rollback last migration
docker compose exec web rails db:rollback

# Rollback 3 migrations
docker compose exec web rails db:rollback STEP=3

# Seed database
docker compose exec web rails db:seed

# Check migration status
docker compose exec web rails db:migrate:status

# Dump database schema
docker compose exec web rails db:schema:dump
```

### Database Backup & Restore

```bash
# Backup database
docker compose exec db pg_dump -U postgres st_intent_harvest_development > backup.sql

# Restore database
docker compose exec -T db psql -U postgres st_intent_harvest_development < backup.sql
```

---

## 🔄 Handling Changes

### When Gemfile Changes (New Gems Added)

```bash
# 1. Update Gemfile locally
# 2. Rebuild the image
docker compose build web

# 3. Restart services
docker compose up -d

# Alternative: Install without rebuilding (faster for development)
docker compose exec web bundle install
docker compose restart web
```

### When Database Schema Changes (New Migration)

```bash
# 1. Pull latest code
git pull

# 2. Run new migrations
docker compose exec web rails db:migrate

# 3. Restart if needed
docker compose restart web
```

### When docker-compose.yml Changes

```bash
# 1. Stop services
docker compose down

# 2. Rebuild if needed
docker compose build

# 3. Start services
docker compose up -d
```

### When Dockerfile Changes

```bash
# 1. Rebuild image without cache
docker compose build --no-cache web

# 2. Restart services
docker compose up -d
```

### When .env Changes

```bash
# Just restart services
docker compose down
docker compose up -d
```

---

## 🐛 Troubleshooting

### Services Won't Start

**Check Docker is running**:

```bash
docker --version
docker compose version
```

**Check service status**:

```bash
docker compose ps
```

**View error logs**:

```bash
docker compose logs web
docker compose logs db
```

### Port Already in Use

**Error**: `Bind for 0.0.0.0:3000 failed: port is already allocated`

**Solution 1** - Stop the conflicting service:

```bash
# Find what's using port 3000
sudo lsof -i :3000
# or on Windows
netstat -ano | findstr :3000

# Kill the process
kill -9 PID
```

**Solution 2** - Change port in `docker-compose.yml`:

```yaml
web:
  ports:
    - "3001:3000" # Change external port to 3001
```

#### Port 5432 (PostgreSQL) Already in Use

**Error**: `exposing port TCP 0.0.0.0:5432: bind: address already in use`

**Cause**: You have PostgreSQL running locally on your machine.

**Solution 1** - Stop local PostgreSQL (Recommended):

```bash
# Check if PostgreSQL is running
sudo systemctl status postgresql

# Stop PostgreSQL
sudo systemctl stop postgresql

# Disable PostgreSQL from starting on boot (optional)
sudo systemctl disable postgresql

# Now start Docker
docker compose up -d
```

**Solution 2** - Change Docker PostgreSQL port to 5433:

Edit `docker-compose.yml`:

```yaml
db:
  ports:
    - "5433:5432" # Change from 5432:5432
```

Then update `.env`:

```bash
DATABASE_PORT=5433  # Change from 5432
```

#### Port 6379 (Redis) Already in Use

**Error**: `exposing port TCP 0.0.0.0:6379: bind: address already in use`

**Cause**: You have Redis running locally on your machine.

**Solution 1** - Stop local Redis (Recommended):

```bash
# Stop local Redis
sudo systemctl stop redis
sudo systemctl stop redis-server

# Disable Redis from starting on boot (optional)
sudo systemctl disable redis-server

# Or find and kill the Redis process
sudo lsof -i :6379
sudo kill -9 <PID>

# Now start Docker
docker compose up -d
```

**Solution 2** - Change Docker Redis port to 6380:

Edit `docker-compose.yml`:

```yaml
redis:
  ports:
    - "6380:6379" # Change from 6379:6379
```

#### Stop All Conflicting Services at Once

If you have multiple port conflicts:

```bash
# Stop PostgreSQL and Redis together
sudo systemctl stop postgresql redis-server

# Start Docker
docker compose up -d

# (Optional) Disable them from starting on boot
sudo systemctl disable postgresql redis-server
```

### Database Connection Errors

#### Error: "could not connect to server: Connection refused"

**Check database is running**:

```bash
docker compose ps db
docker compose logs db
```

**Restart database**:

```bash
docker compose restart db
```

**Check database credentials in `.env`**:

```bash
cat .env | grep DATABASE
```

#### Error: "connection to server on socket failed: No such file or directory"

**Cause**: Rails is trying to connect via Unix socket instead of TCP/IP. This happens when `host` is not configured in `config/database.yml`.

**Solution**: Ensure your `config/database.yml` includes `host` configuration:

```yaml
development:
  <<: *default
  database: <%= ENV.fetch("DATABASE_NAME") { "st_intent_harvest_development" } %>
  username: <%= ENV.fetch("DATABASE_USERNAME") { "postgres" } %>
  password: <%= ENV.fetch("DATABASE_PASSWORD") { "root" } %>
  host: <%= ENV.fetch("DATABASE_HOST") { "localhost" } %>      # ← This is required!
  port: <%= ENV.fetch("DATABASE_PORT") { 5432 } %>            # ← This too!
```

After fixing, restart the web container:

```bash
docker compose restart web
docker compose exec web rails db:create
docker compose exec web rails db:migrate
```

#### Error: "database does not exist"

**Solution**: Create the database:

```bash
docker compose exec web rails db:create
docker compose exec web rails db:migrate
docker compose exec web rails db:seed
```

### Bundle Install Fails

**Error**: `An error occurred while installing [gem]`

**Solution** - Rebuild with no cache:

```bash
docker compose build --no-cache web
```

### Changes Not Reflected

**Code changes not showing**:

1. Hard refresh browser: `Ctrl + Shift + R` (Windows/Linux) or `Cmd + Shift + R` (Mac)
2. Restart Rails server: `docker compose restart web`
3. Check volume mounts: `docker compose exec web ls -la`

**View changes not showing**:

1. Clear browser cache
2. Check file was saved
3. Restart server: `docker compose restart web`

### Permission Denied Errors

**On Linux**, you might encounter permission issues.

**Solution**:

```bash
# Fix ownership
sudo chown -R $USER:$USER .

# Or run commands with sudo
sudo docker compose up -d
```

### Out of Disk Space

**Clean up Docker resources**:

```bash
# Remove stopped containers
docker container prune

# Remove unused images
docker image prune

# Remove unused volumes
docker volume prune

# Clean everything (careful!)
docker system prune -a --volumes
```

### Container Keeps Restarting

**Check logs for errors**:

```bash
docker compose logs -f web
```

**Common causes**:

- Database not ready (wait a minute)
- Migration needed: `docker compose exec web rails db:migrate`
- Missing gems: `docker compose exec web bundle install`
- Syntax error in code

### Windows Line Ending Issues

**Error**: `/rails/bin/docker-entrypoint: line 8: exec: bash: not found` or `: invalid optionsh: -`

**Cause**: Windows CRLF line endings in shell scripts instead of Unix LF line endings.

**Solution** - Convert line endings on Windows:

```powershell
# Convert docker-entrypoint to Unix line endings
$content = Get-Content -Path "bin/docker-entrypoint" -Raw
$content = $content -replace "`r`n", "`n"
[System.IO.File]::WriteAllText("$PWD/bin/docker-entrypoint", $content, [System.Text.UTF8Encoding]::new($false))

# Rebuild and restart
docker compose down
docker compose build web
docker compose up -d
```

**Prevention**: Configure Git to handle line endings properly:

```bash
# On Windows, configure Git to checkout with LF line endings for shell scripts
git config --local core.autocrlf false

# Add to .gitattributes (already configured in this project):
# *.sh text eol=lf
# bin/* text eol=lf
```

### Server PID File Issues

**Error**: `A server is already running (pid: XX, file: /rails/tmp/pids/server.pid)`

**Cause**: Stale PID file from previous container run.

**Solution**: The entrypoint script automatically removes stale PID files, but if you encounter this:

```bash
# Remove PID file manually
docker compose exec web rm -f tmp/pids/server.pid

# Restart
docker compose restart web
```

### Slow Performance

**Increase Docker resources**:

- Docker Desktop → Settings → Resources
- Increase CPU: 4+ cores
- Increase RAM: 4+ GB

**On Windows with WSL 2**:
Create/edit `%USERPROFILE%\.wslconfig`:

```ini
[wsl2]
memory=4GB
processors=4
```

---

## 🔧 Advanced Topics

### Running Multiple Commands

```bash
# Run migrations and seed in one line
docker compose exec web bash -c "rails db:migrate && rails db:seed"
```

### Running Background Jobs (Sidekiq)

Uncomment the `sidekiq` service in `docker-compose.yml`:

```yaml
sidekiq:
  build:
    context: .
    dockerfile: Dockerfile
  command: bundle exec sidekiq
  # ... rest of config
```

Then restart:

```bash
docker compose up -d
```

### Running Tests

```bash
# Run all tests
docker compose exec web rails test

# Run specific test file
docker compose exec web rails test test/models/work_order_test.rb

# Run with coverage
docker compose exec web rails test COVERAGE=true

# Run system tests (browser tests)
docker compose exec web rails test:system
```

### Installing New Gems

**Method 1: Update Gemfile then rebuild**

```bash
# 1. Edit Gemfile locally
# 2. Rebuild image
docker compose build web
# 3. Restart
docker compose up -d
```

**Method 2: Quick install (development only)**

```bash
# 1. Edit Gemfile locally
# 2. Install in running container
docker compose exec web bundle install
# 3. Restart
docker compose restart web
# 4. Rebuild for production
docker compose build web
```

### Accessing Redis

```bash
# Redis CLI
docker compose exec redis redis-cli

# In redis-cli:
KEYS *                  # List all keys
GET key_name           # Get value
FLUSHALL               # Clear all data
```

### Connecting to Production-like Environment

Edit `.env`:

```bash
RAILS_ENV=production
```

Then:

```bash
docker compose down
docker compose up -d
docker compose exec web rails db:create RAILS_ENV=production
docker compose exec web rails db:migrate RAILS_ENV=production
docker compose exec web rails assets:precompile
```

### Debugging with Byebug

Add `byebug` or `debugger` in your code:

```ruby
def index
  byebug  # Execution will stop here
  @users = User.all
end
```

Then attach to the running container:

```bash
docker attach st_intent_harvest-web-1

# Or find container name first:
docker ps
docker attach <container_name>
```

To detach without stopping: `Ctrl+P` then `Ctrl+Q`

### Interactive Debugging with Pry/Byebug

When you need to debug with `binding.pry` or `byebug`, you need an **interactive terminal** that can receive input.

#### Problem: Regular `docker compose up -d` doesn't allow interaction

If you have `binding.pry` in your code and run `docker compose up -d`, the debugger will pause but you won't be able to interact with it.

#### Solution: Use `docker compose run --service-ports`

```bash
# Stop the background web service first
docker compose stop web

# Run web service interactively with ports exposed
docker compose run --service-ports web
```

**What this does:**

- `docker compose run` - Runs a one-off command in a new container
- `--service-ports` - Maps ports defined in docker-compose.yml (like port 3000)
- `web` - The service name to run

**Now you can:**

1. Access your app at `http://localhost:3000` (ports are exposed)
2. See console output in real-time
3. Interact with debugger when `binding.pry` or `byebug` is hit
4. Press `Ctrl+C` to stop cleanly

**Example workflow:**

```bash
# 1. Stop background web service
docker compose stop web

# 2. Start web interactively
docker compose run --service-ports web

# 3. Access app in browser → triggers your binding.pry
# 4. Interact with debugger in terminal:
#    (pry) @user
#    (pry) params
#    (pry) continue

# 5. When done, press Ctrl+C

# 6. Restart background service
docker compose up -d web
```

**Common use cases:**

- Debugging with `binding.pry` or `byebug`
- Running Rails console interactively: `docker compose run web rails console`
- Running generators that need input: `docker compose run web rails g scaffold Post`
- Running tasks that need user input

**Differences between commands:**

| Command                                  | Use Case                 | Interactive | Ports Exposed                   | Removes Container After |
| ---------------------------------------- | ------------------------ | ----------- | ------------------------------- | ----------------------- |
| `docker compose up -d`                   | Normal development       | ❌ No       | ✅ Yes                          | ❌ No (reusable)        |
| `docker compose exec web bash`           | Access running container | ✅ Yes      | N/A (container already running) | ❌ No                   |
| `docker compose run web`                 | One-off commands         | ✅ Yes      | ❌ No                           | ✅ Yes (by default)     |
| `docker compose run --service-ports web` | Interactive debugging    | ✅ Yes      | ✅ Yes                          | ✅ Yes (by default)     |

**Keep container after run:**

```bash
# Don't remove container after exit
docker compose run --service-ports --no-deps --rm=false web

# Or keep it with dependencies
docker compose run --service-ports --rm=false web
```

### Using Docker Compose Profiles

If you want to optionally run services:

**docker-compose.yml**:

```yaml
sidekiq:
  profiles: ["jobs"]
  # ... config
```

**Start without Sidekiq**:

```bash
docker compose up -d
```

**Start with Sidekiq**:

```bash
docker compose --profile jobs up -d
```

---

## 📝 Quick Reference Cheat Sheet

| Task            | Command                                                                    |
| --------------- | -------------------------------------------------------------------------- |
| Start services  | `docker compose up -d`                                                     |
| Stop services   | `docker compose down`                                                      |
| View logs       | `docker compose logs -f web`                                               |
| Rails console   | `docker compose exec web rails console`                                    |
| Run migration   | `docker compose exec web rails db:migrate`                                 |
| Access database | `docker compose exec db psql -U postgres -d st_intent_harvest_development` |
| Bash shell      | `docker compose exec web bash`                                             |
| Install gems    | `docker compose exec web bundle install`                                   |
| Restart app     | `docker compose restart web`                                               |
| Rebuild image   | `docker compose build web`                                                 |
| Reset database  | `docker compose exec web rails db:reset`                                   |
| View routes     | `docker compose exec web rails routes`                                     |
| Run tests       | `docker compose exec web rails test`                                       |

---

## 🆘 Getting Help

### Check Logs First

```bash
# All services
docker compose logs

# Specific service
docker compose logs web
docker compose logs db
docker compose logs redis

# Follow logs (live)
docker compose logs -f web

# Last 100 lines
docker compose logs --tail=100 web
```

### Inspect Container

```bash
# List running containers
docker compose ps

# Inspect container
docker inspect st_intent_harvest-web-1

# Check container resources
docker stats
```

### Verify Configuration

```bash
# Check docker-compose.yml syntax
docker compose config

# Show actual configuration with interpolated values
docker compose config --resolve-image-configs
```

---

## 📖 Additional Resources

### Documentation

- [Docker Documentation](https://docs.docker.com/)
- [Docker Compose Documentation](https://docs.docker.com/compose/)
- [Rails Guides](https://guides.rubyonrails.org/)
- [PostgreSQL Documentation](https://www.postgresql.org/docs/)

### Useful Tools

- [pgAdmin](https://www.pgadmin.org/) - PostgreSQL GUI
- [TablePlus](https://tableplus.com/) - Modern database GUI
- [Redis Commander](https://github.com/joeferner/redis-commander) - Redis GUI
- [Portainer](https://www.portainer.io/) - Docker GUI

---

## 🔒 Security Notes

### Development vs Production

**This Docker setup is for DEVELOPMENT ONLY**. Do not use in production without:

1. **Strong passwords** in `.env`
2. **Secure SECRET_KEY_BASE**
3. **SSL/TLS** certificates
4. **Proper firewall** rules
5. **Non-root user** in containers
6. **Security scanning** of images
7. **Environment variable** protection

### .env File

**Never commit `.env` to Git!**

Check `.gitignore` includes:

```
.env
```

Always use `.env.example` as template for your team.

---

## 🎯 Best Practices

### 1. Use .env for Configuration

Never hardcode credentials or configuration in code.

### 2. Regular Updates

```bash
# Update base images weekly
docker compose pull

# Rebuild with new images
docker compose build

# Update gems
docker compose exec web bundle update
```

### 3. Clean Up Regularly

```bash
# Weekly cleanup
docker system prune

# Check disk usage
docker system df
```

### 4. Backup Database

```bash
# Before major changes
docker compose exec db pg_dump -U postgres st_intent_harvest_development > backup_$(date +%Y%m%d).sql
```

### 5. Keep Gemfile.lock in Sync

Always commit `Gemfile.lock` to ensure consistent gem versions across team.

### 6. Use Specific Gem Versions

In `Gemfile`, use `~>` for safety:

```ruby
gem 'rails', '~> 8.1.0'  # Good: allows 8.1.x
gem 'rails', '>= 8.0'    # Risky: could break
```

---

**Last Updated**: October 25, 2025  
**Maintained By**: Development Team  
**Questions?**: Contact your team lead or check the troubleshooting section
