# 🔄 Production Rollback Guide

This guide explains how to rollback deployments when something goes wrong in production.

## 📋 Table of Contents

- [Overview](#overview)
- [How It Works](#how-it-works)
- [Rollback Methods](#rollback-methods)
  - [Method 1: GitHub Actions (Recommended)](#method-1-github-actions-recommended)
  - [Method 2: Server CLI Script](#method-2-server-cli-script)
  - [Method 3: Manual Docker Commands](#method-3-manual-docker-commands)
- [Database Migration Rollback](#database-migration-rollback)
- [Finding Available Image Tags](#finding-available-image-tags)
- [Deployment History](#deployment-history)
- [Common Scenarios](#common-scenarios)
- [Troubleshooting](#troubleshooting)

---

## Overview

Our deployment system supports instant rollback to any previously deployed version using Docker image tags. Every deployment is tagged with a commit SHA (`main-<sha>`), allowing precise version control.

**Key Features:**

- ✅ No code changes required for rollback
- ✅ Automatic deployment history tracking
- ✅ Database migration rollback support
- ✅ Slack notifications for rollback events
- ✅ Multiple rollback methods (GitHub Actions, CLI, Manual)

---

## How It Works

```
Deploy Flow:
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│ Push to     │ ──▶ │ Build Image │ ──▶ │ Deploy with │
│ main branch │     │ main-abc1234│     │ specific tag│
└─────────────┘     └─────────────┘     └─────────────┘
                           │
                           ▼
                    ┌─────────────┐
                    │ Save to     │
                    │ history file│
                    └─────────────┘

Rollback Flow:
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│ Trigger     │ ──▶ │ Pull old    │ ──▶ │ Restart     │
│ rollback    │     │ image tag   │     │ services    │
└─────────────┘     └─────────────┘     └─────────────┘
```

**Image Tagging Strategy:**

- Every build creates: `ghcr.io/arya020595/st_intent_harvest:main-<sha>`
- Latest build also tags: `ghcr.io/arya020595/st_intent_harvest:latest`
- SHA is the first 7 characters of the commit hash

---

## Rollback Methods

### Method 1: GitHub Actions (Recommended)

The easiest and most reliable way to rollback.

**Steps:**

1. Go to **Actions** tab in GitHub repository
2. Select **"Rollback Production"** workflow
3. Click **"Run workflow"**
4. Fill in the parameters:
   - **image_tag**: The tag to rollback to (e.g., `main-abc1234`)
   - **rollback_migrations**: Number of migrations to rollback (default: 0)
   - **app_name**: Which app to rollback (`all`, `st_intent_harvest`, or `st_accorn`)
   - **skip_health_check**: Enable for emergency situations
5. Click **"Run workflow"**

**Example:**

```
image_tag: main-abc1234
rollback_migrations: 0
app_name: all
skip_health_check: false
```

---

### Method 2: Server CLI Script

For quick rollbacks directly on the server.

**Prerequisites:**

```bash
# SSH to production server
ssh stadmin@46.202.163.155

# Navigate to app directory
cd /home/stadmin/st_intent_harvest

# Ensure script is available
ls scripts/rollback.sh
```

**Commands:**

```bash
# Show deployment history
./scripts/rollback.sh --list

# Rollback to previous deployment
./scripts/rollback.sh --previous

# Rollback to specific tag
./scripts/rollback.sh main-abc1234

# Rollback to specific tag + rollback 1 migration
./scripts/rollback.sh main-abc1234 1

# Show help
./scripts/rollback.sh --help
```

**Example Output:**

```
==========================================
📋 Deployment History (Last 10)
==========================================

Timestamp                     | Deployed Tag       | Previous Tag
------------------------------|--------------------|------------------
2026-02-12T10:30:00+07:00     | main-abc1234       | main-def5678
2026-02-11T15:45:00+07:00     | main-def5678       | main-ghi9012
```

---

### Method 3: Manual Docker Commands

For advanced users or emergency situations.

```bash
# SSH to production server
ssh stadmin@46.202.163.155
cd /home/stadmin/st_intent_harvest

# 1. Check current running image
docker compose images web

# 2. List available local images
docker images | grep st_intent_harvest

# 3. Pull the target image
docker pull ghcr.io/arya020595/st_intent_harvest:main-abc1234

# 4. Update .env file with new image tag
sed -i "s|^DOCKER_IMAGE=.*|DOCKER_IMAGE=ghcr.io/arya020595/st_intent_harvest:main-abc1234|" .env

# 5. Restart services
docker compose up -d

# 6. Verify health
docker compose ps
docker compose logs -f web
```

---

## Database Migration Rollback

⚠️ **Important:** Always rollback migrations BEFORE rolling back code if the new migrations are incompatible with the old code.

### Using GitHub Actions

Set `rollback_migrations` to the number of steps.

### Using CLI Script

```bash
./scripts/rollback.sh main-abc1234 2  # Rollback code + 2 migrations
```

### Manual Method

```bash
# Check migration status
docker compose exec web rails db:migrate:status

# Rollback last migration
docker compose exec web rails db:rollback

# Rollback specific number of migrations
docker compose exec web rails db:rollback STEP=3

# Rollback to specific version
docker compose exec web rails db:migrate:down VERSION=20260212100000
```

---

## Finding Available Image Tags

### Method 1: GitHub Container Registry UI

1. Go to: https://github.com/arya020595/st_intent_harvest/pkgs/container/st_intent_harvest
2. Browse available tags

### Method 2: GitHub API

```bash
# List recent tags
curl -s "https://api.github.com/users/arya020595/packages/container/st_intent_harvest/versions" \
  -H "Authorization: Bearer ${GITHUB_TOKEN}" | jq '.[].metadata.container.tags'
```

### Method 3: Git Log

```bash
# See recent commits with SHAs
git log --oneline -20

# The tag format is: main-<first-7-chars-of-sha>
# Example: commit abc1234567890 → tag main-abc1234
```

### Method 4: Deployment History

```bash
# On production server
cat /home/stadmin/st_intent_harvest/.deploy_history
```

---

## Deployment History

Each deployment is logged to `.deploy_history` file on the server:

```
timestamp|deployed_tag|previous_tag
2026-02-12T10:30:00+07:00|main-abc1234|main-def5678
2026-02-11T15:45:00+07:00|main-def5678|main-ghi9012
```

**View history:**

```bash
# On server
cat /home/stadmin/st_intent_harvest/.deploy_history

# Or use the script
./scripts/rollback.sh --list
```

---

## Common Scenarios

### Scenario 1: New deployment causes 500 errors

```bash
# Quick rollback to previous version
./scripts/rollback.sh --previous

# Or via GitHub Actions with "main-<previous-sha>"
```

### Scenario 2: New migration breaks the app

```bash
# Rollback 1 migration + rollback code
./scripts/rollback.sh main-abc1234 1
```

### Scenario 3: Health check fails but app partially works

```bash
# Use GitHub Actions with skip_health_check = true
# Or manually:
docker pull ghcr.io/arya020595/st_intent_harvest:main-abc1234
sed -i "s|^DOCKER_IMAGE=.*|DOCKER_IMAGE=ghcr.io/arya020595/st_intent_harvest:main-abc1234|" .env
docker compose up -d
```

### Scenario 4: Need to rollback specific app only

```bash
# Via GitHub Actions: set app_name to "st_intent_harvest" or "st_accorn"

# Via CLI:
APP_NAME=st_intent_harvest ./scripts/rollback.sh main-abc1234
```

### Scenario 5: Unknown which version to rollback to

```bash
# 1. Check deployment history
./scripts/rollback.sh --list

# 2. Or check git log for recent stable commits
git log --oneline -20

# 3. Identify the last known good commit SHA
# 4. Use first 7 characters as tag: main-<sha>
```

---

## Troubleshooting

### Image Not Found

```
Error: Image not found: ghcr.io/arya020595/st_intent_harvest:main-abc1234
```

**Solution:**

1. Verify the tag exists in GitHub Container Registry
2. Check if you have the correct SHA
3. Ensure the build workflow completed successfully for that commit

### Health Check Timeout

```
Error: Health check failed after 150s
```

**Solution:**

1. Check application logs: `docker compose logs web`
2. Use emergency rollback with `skip_health_check=true`
3. Investigate the root cause

### Migration Rollback Fails

```
Error: Cannot rollback migration - irreversible
```

**Solution:**

1. Some migrations are irreversible by design
2. May need to manually fix the database
3. Consider restoring from database backup

### Permission Denied on Script

```bash
chmod +x scripts/rollback.sh
```

### .env File Missing

```bash
# Create .env from template
cp .env.example .env
# Edit with appropriate values
nano .env
```

---

## Best Practices

1. **Test rollbacks in staging** before they're needed in production
2. **Keep deployment history** - don't delete `.deploy_history`
3. **Document breaking changes** in migrations that require code rollback
4. **Use GitHub Actions** for audit trail and Slack notifications
5. **Monitor after rollback** - verify the rollback fixed the issue
6. **Communicate rollbacks** to the team via Slack

---

## Related Documentation

- [Production Deployment Guide](./PRODUCTION_DEPLOYMENT_GUIDE.md)
- [Docker Setup Guide](./DOCKER_SETUP.md)
- [Database Migration Guide](../database/MIGRATIONS.md)
