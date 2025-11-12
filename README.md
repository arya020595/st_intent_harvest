# ST Intent Harvest

Work Order Management System built with Rails 8.1 and Ruby 3.4.7.

## 🐳 Docker Setup (Recommended)

This project is fully Dockerized for easy setup across all platforms (Windows, macOS, Linux).

### Quick Start

```bash
# 1. Copy environment file
cp .env.example .env

# 2. Build and start services
docker compose up -d

# 3. Setup database
docker compose exec web rails db:create
docker compose exec web rails db:migrate
docker compose exec web rails db:seed

# 4. Visit http://localhost:3000
# Login: admin@example.com / password123
```

### 📚 Documentation

#### Development

- **[Quick Start Guide](docs/QUICK_START.md)** - Get up and running in 5 minutes
- **[Docker Guide](docs/DOCKER_GUIDE.md)** - Comprehensive Docker documentation
- **[Troubleshooting](docs/TROUBLESHOOTING.md)** - Common issues and solutions
- **[Denormalizable Usage Guide](docs/DENORMALIZABLE_USAGE_GUIDE.md)** - Clean denormalization pattern
- **[Pundit Authorization](docs/PUNDIT_AUTHORIZATION.md)** - Permission system details
- **[Work Order Status Flow](docs/WORK_ORDER_STATUS_FLOW.md)** - State machine documentation

#### Production Deployment

- **[Production Deployment Guide](docs/PRODUCTION_DEPLOYMENT_GUIDE.md)** - Complete step-by-step deployment to production server using GHCR and GitHub Actions CI/CD

### Common Commands

```bash
# No bundle exec needed! 🎉
docker compose exec web rails console
docker compose exec web rails db:migrate
docker compose exec web rails test
docker compose exec web rails routes

# View logs
docker compose logs -f web

# Stop services
docker compose down
```

## 💻 Tech Stack

- **Ruby**: 3.4.7
- **Rails**: 8.1.0
- **Database**: PostgreSQL 16.1
- **Cache**: Redis 7
- **Authorization**: Pundit
- **State Machine**: AASM
- **Frontend**: Stimulus, Turbo, ImportMap

## 📦 Services

- **Web**: Rails application (Port 3000)
- **Database**: PostgreSQL (Port 5432)
- **Redis**: Caching and sessions (Port 6379)

## 🔧 Development

### Running Tests

```bash
docker compose exec web rails test
```

### Accessing Rails Console

```bash
docker compose exec web rails console
```

### Database Access

```bash
# Via Rails console
docker compose exec web rails dbconsole

# Via psql directly
docker compose exec db psql -U postgres -d st_intent_harvest_development
```

## 🚀 Features

- **Work Order Management**: Create, track, and complete work orders
- **Worker Management**: Assign workers to work orders
- **Inventory Tracking**: Track materials used in work orders
- **Role-based Access Control**: Admin, Manager, Staff roles with granular permissions
- **State Machine**: Automatic status transitions with history tracking
- **Dashboard**: Real-time statistics and recent activity
- **CI/CD Pipeline**: Automated testing and deployment with GitHub Actions
- **Dockerized**: Easy deployment to any server with Docker support

## 🌐 Production Deployment

Want to deploy to production? See our **[Production Deployment Guide](docs/PRODUCTION_DEPLOYMENT_GUIDE.md)** for complete instructions on:

- Setting up production server
- Configuring GitHub Container Registry (GHCR)
- Automated CI/CD with GitHub Actions
- SSL/HTTPS setup with Nginx
- Database management and backups

## 📝 Default Users (from seed data)

```
Admin:   admin@example.com   / password123
Manager: manager@example.com / password123
Staff:   staff@example.com   / password123
```

## 🐛 Troubleshooting

Having issues? Check the **[Troubleshooting Guide](docs/TROUBLESHOOTING.md)** for detailed solutions:

- 🖼️ Images not rendering or updating
- 🐳 Container startup problems
- 💾 Database connection errors
- 💎 Gem installation issues
- 🐌 Performance problems
- And more common issues...

### Quick Fixes

**Images not showing or updating?**

```bash
docker compose exec web rails assets:clobber && docker compose restart web
```

**New gems not installed?**

```bash
docker compose restart web  # Auto-installs missing gems
```

**Database issues?**

```bash
docker compose restart web
```

## 📄 License

This project is licensed under the MIT License.
