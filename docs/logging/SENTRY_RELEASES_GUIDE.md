# Sentry Release Tracking

> **TL;DR** — Every time we deploy, we tell Sentry _"this is version X"_. When an error happens,
> Sentry shows us exactly which deploy caused it and which commit is likely responsible.

---

## Table of Contents

- [What Is This?](#what-is-this)
- [Why Do We Need It?](#why-do-we-need-it)
- [How It Works (The Big Picture)](#how-it-works-the-big-picture)
- [Step-by-Step Flow](#step-by-step-flow)
- [What We Changed (Implementation)](#what-we-changed-implementation)
- [Sentry CLI Commands Explained](#sentry-cli-commands-explained)
- [GitHub Secrets Setup](#github-secrets-setup)
- [How to Verify It's Working](#how-to-verify-its-working)
- [Real-World Example](#real-world-example)
- [Troubleshooting](#troubleshooting)
- [FAQ](#faq)
- [References](#references)

---

## What Is This?

**Sentry Release Tracking** is a feature that links your **deployed code versions** to
**error reports** in Sentry.

Without it, Sentry tells you: _"There's a bug."_
With it, Sentry tells you: _"There's a bug, it started in deploy `abc1234`, and this commit probably caused it."_

---

## Why Do We Need It?

| Problem (Before)                               | Solution (After)                                         |
| ---------------------------------------------- | -------------------------------------------------------- |
| "When did this bug start happening?"           | Sentry shows the exact release where it first appeared   |
| "Which commit broke it?"                       | **Suspect Commits** — Sentry highlights the likely cause |
| "Did our latest deploy fix the issue?"         | **Regression Detection** — auto-alerts if it comes back  |
| "How stable is this release compared to last?" | **Release Health** — crash-free session percentages      |
| "When was this version deployed?"              | **Deploy Tracking** — timestamps and environments        |

---

## How It Works (The Big Picture)

```
 YOU push code to main
        │
        ▼
 ┌─────────────────────────────────┐
 │  GitHub Actions: Build & Push   │  ← Builds Docker image
 └──────────────┬──────────────────┘
                │
                ▼
 ┌─────────────────────────────────┐
 │  GitHub Actions: Deploy         │  ← Deploys to production server
 │                                 │
 │  1. Pull Docker image           │
 │  2. Set SENTRY_RELEASE=<sha>    │  ← Tags the app with git SHA
 │  3. docker compose up           │
 │  4. Run migrations              │
 └──────────────┬──────────────────┘
                │
                ▼
 ┌─────────────────────────────────┐
 │  GitHub Actions: Sentry Release │  ← Tells Sentry about the deploy
 │                                 │
 │  1. sentry-cli releases new     │
 │  2. sentry-cli set-commits      │  ← Links git commits
 │  3. sentry-cli deploys new      │  ← Records deployment
 │  4. sentry-cli releases finalize│
 └──────────────┬──────────────────┘
                │
                ▼
 ┌─────────────────────────────────┐
 │  Rails App (Running)            │
 │                                 │
 │  Every error sent to Sentry     │
 │  includes: release = "abc1234"  │  ← Sentry knows which version
 └─────────────────────────────────┘
```

---

## Step-by-Step Flow

### 1. Deploy happens

Our CD pipeline (`cd-deploy.yml`) deploys the app and writes `SENTRY_RELEASE=<full-git-sha>`
into the `.env` file on the production server.

### 2. Rails picks up the release tag

When the app boots, the Sentry initializer reads the environment variable:

```ruby
# config/initializers/sentry.rb
config.release = ENV.fetch('SENTRY_RELEASE', nil)
```

Now every error, log, and transaction sent to Sentry is tagged with this version.

### 3. CI/CD tells Sentry about the release

After a successful deploy, a dedicated workflow step:

- **Creates** the release in Sentry
- **Links** all git commits since the previous release
- **Records** the deployment (environment + timestamp)
- **Finalizes** the release

### 4. An error occurs

When something breaks, Sentry can now tell you:

- ✅ Which release (deploy) the error belongs to
- ✅ Which commits were in that release
- ✅ Which specific commit likely introduced the bug
- ✅ Whether this is a new issue or a regression

---

## What We Changed (Implementation)

### Files Modified

#### 1. `config/initializers/sentry.rb` — Added release config

```ruby
# Added this line ↓
config.release = ENV.fetch('SENTRY_RELEASE', nil)
```

This is the **bridge** between your deployed version and Sentry. Without this line,
Sentry has no way to know which version of the app is running.

#### 2. `.github/workflows/cd-deploy.yml` — Added two things

**a) Write `SENTRY_RELEASE` to `.env` during deploy:**

```bash
# Inside the SSH deploy script, before docker compose up:
grep -q "^SENTRY_RELEASE=" .env && \
  sed -i "s|^SENTRY_RELEASE=.*|SENTRY_RELEASE=${DEPLOY_SHA}|" .env || \
  echo "SENTRY_RELEASE=${DEPLOY_SHA}" >> .env
```

**b) New step "Create Sentry Release" (runs after successful deploy):**

```yaml
- name: Create Sentry Release
  if: success()
  env:
    SENTRY_AUTH_TOKEN: ${{ secrets.SENTRY_AUTH_TOKEN }}
    SENTRY_ORG: ${{ secrets.SENTRY_ORG }}
    SENTRY_PROJECT: ${{ secrets.SENTRY_PROJECT }}
  run: |
    curl -sL https://sentry.io/get-cli/ | bash
    VERSION="${{ github.event.workflow_run.head_sha || github.sha }}"
    sentry-cli releases new "$VERSION"
    sentry-cli releases set-commits "$VERSION" --auto
    sentry-cli releases deploys "$VERSION" new -e production
    sentry-cli releases finalize "$VERSION"
```

#### 3. Docker Compose files — Added `SENTRY_RELEASE` env var

Added to all three production compose files:

- `docker-compose.production.yml`
- `docker-compose.st_intent_harvest.production.yml`
- `docker-compose.st_accorn.production.yml`

```yaml
environment:
  # ... existing vars ...

  # Sentry release tracking
  SENTRY_RELEASE: ${SENTRY_RELEASE:-}
```

---

## Sentry CLI Commands Explained

Here's what each command in the release script does:

```bash
# ① Install the Sentry CLI tool (lightweight, ~10MB)
curl -sL https://sentry.io/get-cli/ | bash

# ② Generate a version identifier (uses the full git SHA)
VERSION=$(sentry-cli releases propose-version)
# Example: "a1b2c3d4e5f6..."

# ③ Create a new release in Sentry
sentry-cli releases new "$VERSION"
# → Sentry now knows this version exists

# ④ Link git commits to this release
sentry-cli releases set-commits "$VERSION" --auto
# → --auto finds all commits since the last release
# → This enables "Suspect Commits" feature

# ⑤ Record the deployment event
sentry-cli releases deploys "$VERSION" new -e production
# → Sentry records: "version X was deployed to production at <timestamp>"

# ⑥ Finalize the release (mark it as shipped)
sentry-cli releases finalize "$VERSION"
# → Release is now visible in the Sentry Releases dashboard
```

---

## GitHub Secrets Setup

You need to add **3 secrets** in your GitHub repository:

**Go to:** GitHub repo → Settings → Secrets and variables → Actions → New repository secret

| Secret Name         | Value                  | Where to find it                                   |
| ------------------- | ---------------------- | -------------------------------------------------- |
| `SENTRY_AUTH_TOKEN` | `e1850f5109...252e002` | Sentry → Settings → Internal Integrations → Token  |
| `SENTRY_ORG`        | `st-advisory`          | Your Sentry organization slug (visible in the URL) |
| `SENTRY_PROJECT`    | `ruby-rails`           | Sentry → Settings → Projects → Project slug        |

> ⚠️ **Never hardcode the auth token in your codebase.** Always use GitHub Secrets.
> The token shown on the Sentry setup page should be copied directly to GitHub Secrets.

---

## How to Verify It's Working

### ✅ Check 1: Sentry Dashboard

After your next deployment:

1. Go to [sentry.io](https://sentry.io)
2. Select org **st-advisory** → project **ruby-rails**
3. Click **Releases** in the left sidebar
4. You should see a release matching the git SHA, showing:
   - Commit list
   - Deploy timestamp
   - "production" environment tag

### ✅ Check 2: Rails Console

SSH into production and open a Rails console:

```ruby
Sentry.configuration.release
# Should output something like: "a1b2c3d4e5f67890..."
```

If it returns `nil`, the `SENTRY_RELEASE` env var isn't reaching the container.

### ✅ Check 3: GitHub Actions Logs

Look at the deploy workflow run → **"Create Sentry Release"** step.
You should see output like:

```
→ Creating Sentry release: a1b2c3d4e5f67890...
Created release a1b2c3d4e5f67890...
✅ Sentry release created and finalized
```

---

## Real-World Example

Here's a concrete scenario showing how this helps:

```
Timeline:
─────────────────────────────────────────────────────────

Monday 10:00  →  Deploy release "abc1234"
                 (includes commit: "Refactor payslip calculation")

Monday 14:00  →  Users report: "Payslip shows wrong amount"

You open Sentry:
┌─────────────────────────────────────────────────┐
│ ❌ NoMethodError: undefined method 'round'      │
│    for nil:NilClass                              │
│                                                  │
│ 📦 Release:  abc1234                             │
│ 🕐 First seen: Monday 10:32                     │
│ 🔍 Suspect commit:                              │
│    "Refactor payslip calculation" by @arya       │
│    Changed: app/services/payslip_calculator.rb   │
└─────────────────────────────────────────────────┘

Without release tracking:
  "There's a nil error somewhere in payslips... 🤷"

With release tracking:
  "The error started after deploy abc1234,
   likely caused by the payslip refactor commit.
   Check line 42 of payslip_calculator.rb." ✅
```

---

## Troubleshooting

### Releases not appearing in Sentry

| Symptom                       | Cause                               | Fix                                                                                      |
| ----------------------------- | ----------------------------------- | ---------------------------------------------------------------------------------------- |
| No releases listed            | Auth token is invalid or expired    | Go to Sentry → Settings → Internal Integrations → Regenerate token, update GitHub Secret |
| Release exists but no commits | GitHub repo not connected in Sentry | Sentry → Settings → Integrations → GitHub → Connect repository                           |

### Errors not tagged with a release

| Symptom                                      | Cause                                | Fix                                                      |
| -------------------------------------------- | ------------------------------------ | -------------------------------------------------------- |
| Errors show "unknown" release                | `SENTRY_RELEASE` not in `.env`       | SSH to server, check `cat .env \| grep SENTRY`           |
| Errors show "unknown" release                | Docker Compose not passing the var   | Verify `SENTRY_RELEASE` is in docker-compose env section |
| `Sentry.configuration.release` returns `nil` | Initializer missing `config.release` | Check `config/initializers/sentry.rb` has the line       |

### CI/CD step fails

| Symptom                         | Cause                  | Fix                                                  |
| ------------------------------- | ---------------------- | ---------------------------------------------------- |
| `sentry-cli: command not found` | Install step failed    | Check network access to `sentry.io/get-cli/`         |
| `401 Unauthorized`              | Wrong or missing token | Verify `SENTRY_AUTH_TOKEN` secret in GitHub          |
| `Organization not found`        | Wrong org slug         | Verify `SENTRY_ORG` matches your Sentry org URL slug |

---

## FAQ

**Q: Does this slow down deployments?**
No. The Sentry release step runs _after_ the deploy is complete and takes about 5-10 seconds.
Even if it fails, the deployment itself is unaffected (it uses `if: success()`, not a blocker).

**Q: What if the Sentry step fails?**
The app is already deployed and running. Sentry just won't know about this particular release.
Errors will still be captured — they just won't be tagged with the release version until the
next successful release creation.

**Q: Do I need to install anything locally?**
No. The `sentry-cli` is installed on-the-fly in the GitHub Actions runner during each deploy.
It's not part of the Docker image or the local development setup.

**Q: Does this work for both st_intent_harvest and st_accorn?**
Yes. Both apps share the same Docker image and both get `SENTRY_RELEASE` set in their `.env`.
The Sentry release is created once per deploy and applies to both.

**Q: What version format does it use?**
The full 40-character git commit SHA (e.g., `a1b2c3d4e5f678901234567890abcdef12345678`).
This guarantees uniqueness and maps directly to a git commit.

**Q: Can I see releases without errors?**
Yes. Go to Sentry → Releases. All finalized releases appear there, even those with zero errors.
This is useful for confirming deploys were tracked.

---

## References

- [Sentry Release Management Docs](https://docs.sentry.io/product/releases/)
- [Sentry CLI Documentation](https://docs.sentry.io/cli/)
- [sentry-ruby SDK Releases](https://docs.sentry.io/platforms/ruby/configuration/releases/)
- [Suspect Commits](https://docs.sentry.io/product/releases/suspect-commits/)
- [Release Health](https://docs.sentry.io/product/releases/health/)
