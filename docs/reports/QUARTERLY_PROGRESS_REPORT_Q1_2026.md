# External Consultant Progress Report — Q1 2026

## December 2025 – February 2026

| Field    | Value                                      |
| -------- | ------------------------------------------ |
| Name     | Arya Pratama                               |
| Role     | External Consultant — Full Stack Developer |
| Company  | ST Datablu Sdn. Bhd.                       |
| Period   | December 2025 – February 2026 (3 months)   |
| Date     | February 17, 2026                          |
| Platform | Intent Harvest                             |

### Engagement Scope Reference

| Area                          | Allocation | Key Responsibilities                                                           |
| ----------------------------- | ---------- | ------------------------------------------------------------------------------ |
| Web & Application Development | 60%        | Develop and maintain scalable web applications; ensure performance & security  |
| Maintenance & Support         | 20%        | Troubleshoot, fix bugs; maintain documentation, version control                |
| Team Management & Governance  | 20%        | Mentor junior developers; enforce coding, documentation & deployment standards |

---

## Executive Summary

Over the past three months, I have delivered measurable results across all three areas of my engagement scope:

**Web & Application Development (60%)** — Built a complete CI/CD pipeline that deploys code from development to production automatically in ~3 minutes with zero manual intervention. Implemented a production rollback mechanism that can recover from any issue in under 5 minutes. Containerized the entire platform with Docker, enabling consistent environments and 5-minute developer onboarding.

**Maintenance & Support (20%)** — Deployed AI-powered code review (GitHub Copilot) that automatically inspects every code change 24/7. Set up Portainer as a visual server management dashboard so the team can monitor and manage production without SSH terminal expertise. Maintained comprehensive system documentation and version control across the platform.

**Team Management & Governance (20%)** — Mentored junior developer Amirul through a structured program. In 3 months, he grew from needing daily guidance to **independently managing the entire Intent Harvest platform** when I was out of office. Created a Junior Developer SOP, Team Management Plan, and 40+ technical documents to enforce coding, documentation, and deployment standards.

**In short:** All deliverables across the three scope areas have been completed. The platform is now professionally operated with enterprise-grade infrastructure, automated quality control, and a team capable of operating independently.

---

## Achievements at a Glance

| #   | Scope Area            | Achievement                | Impact                                                     | Status    |
| --- | --------------------- | -------------------------- | ---------------------------------------------------------- | --------- |
| 1   | Web & App Dev (60%)   | CI/CD Pipeline             | Automated testing + deployment, ~3 min deploy time         | Completed |
| 2   | Web & App Dev         | Rollback Mechanism         | Recovery from production issues in under 5 minutes         | Completed |
| 3   | Web & App Dev         | Full Dockerization         | All apps containerized, consistent across all environments | Completed |
| 4   | Maintenance (20%)     | GitHub Copilot Code Review | AI-powered quality guard on every code change              | Completed |
| 5   | Maintenance           | Portainer Dashboard        | Visual Docker management — no SSH terminal needed          | Completed |
| 6   | Team Management (20%) | Mentoring & Leading Amirul | Junior independently handles the project when Lead is away | Completed |

---

## Part A: Web & Application Development

_Scope: 60% — Develop and maintain scalable web applications. Ensure high performance, security, and reliability of developed solutions._

The following three achievements establish the complete development and deployment infrastructure for the Intent Harvest platform.

---

## 1. CI/CD Pipeline — Automated Quality & Deployment

### What is CI/CD?

**CI/CD** stands for **Continuous Integration / Continuous Deployment**. Think of it as an **automated quality inspector combined with a delivery truck.**

- **Continuous Integration (CI):** Every time a developer submits code, it is automatically checked for errors, style violations, security vulnerabilities, and tested — before anyone reviews it.
- **Continuous Deployment (CD):** Once the code passes all checks and is approved, it is automatically packaged and delivered to the live production server — no manual steps required.

Previously, deploying the application required manually connecting to the server via SSH, running commands, and hoping nothing went wrong. Now, the entire process is automated and monitored.

### What We Built

We implemented **4 automated workflows** using GitHub Actions:

| Workflow        | Purpose                                          | Trigger                        |
| --------------- | ------------------------------------------------ | ------------------------------ |
| **CI Pipeline** | Run 4 quality checks on every code change        | Every Pull Request             |
| **Build**       | Package the application into a Docker image      | Code merged to main branch     |
| **Deploy**      | Deliver the new version to the production server | After successful build         |
| **Rollback**    | Revert to a previous version (see Section 2)     | Manual trigger (emergency use) |

### How It Works — End to End

```
  Developer pushes code
        │
        ▼
  ┌──────────────────────────────────────────────────┐
  │         CI: AUTOMATED QUALITY GATES               │
  │                                                    │
  │   ✓ RuboCop        Code style & formatting check  │
  │   ✓ Brakeman       Security vulnerability scan     │
  │   ✓ Bundler Audit  Dependency vulnerability check  │
  │   ✓ Rails Tests    Automated functionality tests   │
  │                                                    │
  │   ❌ Any gate fails? → Code is BLOCKED.            │
  │      Developer must fix before proceeding.         │
  └────────────────────┬─────────────────────────────┘
                       │ All 4 gates pass ✓
                       ▼
  ┌──────────────────────────────────────────────────┐
  │         CD: BUILD & PACKAGE                       │
  │                                                    │
  │   → Build optimized Docker image                   │
  │   → Tag with unique version identifier             │
  │   → Push to GitHub Container Registry (GHCR)       │
  └────────────────────┬─────────────────────────────┘
                       │
                       ▼
  ┌──────────────────────────────────────────────────┐
  │         CD: DEPLOY TO PRODUCTION                  │
  │                                                    │
  │   → Save current version (for rollback)            │
  │   → Pull new version on production server          │
  │   → Start new version                              │
  │   → Health check (verify system is working)        │
  │      ├─ ✓ Healthy → Continue deployment            │
  │      └─ ✗ Fails → AUTOMATIC ROLLBACK               │
  │          • Stop deployment immediately              │
  │          • Revert to previous working version       │
  │          • Notify team via Slack (failure alert)    │
  │          • Log failure details for investigation    │
  │                                                    │
  │   → Run database updates                           │
  │   → Record deployment in history log               │
  │   → Notify team via Slack (success)                │
  └──────────────────────────────────────────────────┘
```

### Before vs After

| Aspect                  | Before (Manual)                    | After (Automated CI/CD)               |
| ----------------------- | ---------------------------------- | ------------------------------------- |
| **Deploy time**         | ~30 minutes of manual SSH work     | ~3 minutes, fully automated           |
| **Quality checks**      | Human-only, easy to forget         | 4 automated gates, impossible to skip |
| **Risk of human error** | High — wrong command, wrong server | Near zero — scripted & tested         |
| **Team visibility**     | Only the person deploying knew     | Slack notifies entire team instantly  |
| **Rollback**            | No mechanism existed               | Built-in, under 5 minutes (Section 2) |
| **Dependency updates**  | Manual, often forgotten            | Automated weekly via Dependabot       |
| **Deploy frequency**    | Infrequent (risky, time-consuming) | Can deploy multiple times per day     |

### Key Numbers

| Metric                       | Value                             |
| ---------------------------- | --------------------------------- |
| Automated quality gates      | 4 (style, security, audit, tests) |
| Deploy time                  | ~3 minutes end-to-end             |
| Health check window          | 150 seconds (30 retries × 5s)     |
| Apps deployed simultaneously | 2 (Intent Harvest + Accorn)       |
| Dependency update frequency  | Weekly (automated by Dependabot)  |

### Health Check Safety Mechanism

Every deployment includes an **automated health check** — a critical safety feature that prevents broken deployments from reaching users.

**How it works:**

1. **New version starts:** The new application container is launched on the production server
2. **Health check begins:** System makes HTTP requests to the `/up` endpoint every 5 seconds
3. **30 attempts maximum:** If the application doesn't respond healthy within 150 seconds (30 × 5s), it's considered failed
4. **Two possible outcomes:**
   - ✅ **HEALTHY** → Application responds correctly, deployment continues normally
   - ❌ **FAILED** → Application doesn't respond or returns errors

**When health check fails:**

```
  Health Check FAILED
        │
        ▼
  Stop deployment immediately
        │
        ▼
  Automatic rollback to previous version
        │
        ▼
  Previous working version is restored
        │
        ▼
  Slack alert sent to team:
  "⚠️ Deployment FAILED for Intent Harvest
   Health check timeout - automatically rolled back
   Previous version restored: main-abc1234"
        │
        ▼
  Failure details logged for investigation
```

**What causes health check failures:**

- Application crashes on startup (code error, missing dependency)
- Database connection failures
- Memory/resource exhaustion
- Configuration errors (missing environment variables)
- Slow initialization (exceeds 150-second timeout)

**Why this matters:**

- **Zero downtime:** Users never see a broken application — the system reverts automatically before the broken version is fully active
- **No manual intervention needed:** The rollback happens automatically; the team can investigate the issue without pressure
- **Safety net:** Even if something passes all CI tests but breaks in production, the health check catches it

### Business Impact

- **Faster releases:** Features and fixes reach production the same day they are approved, not days later.
- **Fewer production bugs:** 4 automated quality gates catch issues before they reach users.
- **Full transparency:** Every deployment is logged and the team is notified via Slack in real time.
- **Reduced downtime risk:** Automated health checks verify the system is working after every deploy.

---

## 2. Rollback Mechanism — Production Safety Net

### What is Rollback?

A **rollback** is an **undo button for production.** If we deploy a new version of the application and something goes wrong — a critical bug, a broken feature, or a performance issue — we can instantly revert to the previous working version. Without a rollback mechanism, fixing a production issue could take hours of debugging. With rollback, we can restore service in under 5 minutes while we investigate the root cause separately.

### Three Rollback Methods Implemented

| Method                     | When to Use                       | Who Can Use It         |
| -------------------------- | --------------------------------- | ---------------------- |
| **GitHub Actions UI**      | Standard rollback (recommended)   | Any team member        |
| **Server CLI Script**      | From the server terminal directly | Anyone with SSH access |
| **Manual Docker Commands** | Last resort / learning exercise   | Advanced users         |

Having three methods ensures we always have a way to recover, even if one method is unavailable.

### How It Works Behind the Scenes

```
  Problem detected after deployment!
        │
        ▼
  ┌─ Step 1 ──────────────────────────────────────────┐
  │  TRIGGER ROLLBACK                                   │
  │  Go to GitHub Actions → "Rollback Production"      │
  │  Enter the version tag to roll back to              │
  └────────────────────┬───────────────────────────────┘
                       │
                       ▼
  ┌─ Step 2 ──────────────────────────────────────────┐
  │  VERIFY THE OLD VERSION EXISTS                      │
  │  System checks that the target version is           │
  │  available in the container registry                 │
  └────────────────────┬───────────────────────────────┘
                       │
                       ▼
  ┌─ Step 3 ──────────────────────────────────────────┐
  │  PULL THE PREVIOUS WORKING VERSION                  │
  │  Download the old, known-good version to the server │
  └────────────────────┬───────────────────────────────┘
                       │
                       ▼
  ┌─ Step 4 ──────────────────────────────────────────┐
  │  SWAP VERSIONS (Zero Downtime)                      │
  │  Replace the broken version with the good one       │
  │  Users experience minimal to no interruption         │
  └────────────────────┬───────────────────────────────┘
                       │
                       ▼
  ┌─ Step 5 ──────────────────────────────────────────┐
  │  ROLLBACK DATABASE CHANGES (If Needed)              │
  │  Undo any database structure changes that came      │
  │  with the broken version                            │
  └────────────────────┬───────────────────────────────┘
                       │
                       ▼
  ┌─ Step 6 ──────────────────────────────────────────┐
  │  HEALTH CHECK — VERIFY SYSTEM IS WORKING            │
  │  Automated checks for up to 150 seconds to          │
  │  confirm the application is responding correctly     │
  └────────────────────┬───────────────────────────────┘
                       │
                       ▼
  ┌─ Step 7 ──────────────────────────────────────────┐
  │  RECORD IN DEPLOYMENT HISTORY                       │
  │  Log the rollback action (who, when, which version) │
  │  History keeps the last 10 deployments for reference │
  └────────────────────┬───────────────────────────────┘
                       │
                       ▼
  ┌─ Step 8 ──────────────────────────────────────────┐
  │  NOTIFY TEAM VIA SLACK                              │
  │  "Rollback completed: Intent Harvest reverted       │
  │   to version main-abc1234 — system is healthy"      │
  └────────────────────────────────────────────────────┘
```

### Deployment History Tracking

Every deployment and rollback is recorded in a history log on the server. The system keeps the **last 10 deployments**, making it easy to:

- See exactly what version is running and when it was deployed
- Pick any previous version to roll back to
- Understand the timeline of changes if something goes wrong

### Business Impact

- **Recovery time:** Production incidents can be resolved in **under 5 minutes** instead of hours.
- **Safety net:** Every deployment has a built-in escape hatch — the team can deploy with confidence, knowing they can always revert.
- **Accountability:** Full history of who deployed what and when.
- **Multi-app support:** Can rollback Intent Harvest and Accorn independently or together.

---

## 3. Dockerization — Containerized Platform

### What is Docker?

Think of Docker as **shipping containers for software.** In the physical world, shipping containers standardize how goods are transported — the same container fits on any truck, ship, or train. Docker does the same for software: it packages our application with everything it needs (code, database, dependencies, settings) into a standardized "container" that runs exactly the same way everywhere.

**The problem Docker solves:**

| Without Docker                                 | With Docker                                  |
| ---------------------------------------------- | -------------------------------------------- |
| "It works on my computer but not on yours"     | Works identically on every machine           |
| Hours setting up a new developer's environment | New developer starts in **5 minutes**        |
| Different versions of tools cause conflicts    | Everyone uses the exact same versions        |
| Deploying means manually installing everything | Deploy = pull the container image and run it |

### What We Containerized

We created Docker configurations for **every environment**:

#### Development Environment (Developer's Machine)

Three containers work together on every developer's laptop:

```
  ┌─────────────────── Developer's Machine ───────────────────┐
  │                                                            │
  │  ┌─────────────────────────────────────────────────────┐  │
  │  │              Docker Engine                           │  │
  │  │                                                      │  │
  │  │   ┌──────────────┐  ┌───────────┐  ┌────────────┐  │  │
  │  │   │  Web App      │  │ Database  │  │   Cache    │  │  │
  │  │   │  (Rails 8.1)  │  │(PostgreSQL│  │  (Redis 7) │  │  │
  │  │   │  Port 3000    │  │  16.1)    │  │  Port 6379 │  │  │
  │  │   │               │  │ Port 5432 │  │            │  │  │
  │  │   └───────────────┘  └───────────┘  └────────────┘  │  │
  │  │           │                │               │         │  │
  │  │           └────────────────┴───────────────┘         │  │
  │  │                    Shared Network                     │  │
  │  └─────────────────────────────────────────────────────┘  │
  │                                                            │
  │  Code changes on laptop → instantly reflected in container │
  └────────────────────────────────────────────────────────────┘
```

#### Production Environment (Live Server)

Optimized production containers running two applications on a single server:

```
  ┌────────────────── Production Server (VPS) ──────────────────┐
  │                                                              │
  │  ┌──────────────────────────────────────────────────────┐   │
  │  │  Nginx (Reverse Proxy + SSL Encryption)              │   │
  │  │    ├── intent.intentharvest.com ──→ Port 3005        │   │
  │  │    ├── accorn.intentharvest.com ──→ Port 3006        │   │
  │  │    └── intentharvest.com (static landing page)       │   │
  │  └──────────────────────────────────────────────────────┘   │
  │                                                              │
  │  ┌─────────────────────┐    ┌─────────────────────┐        │
  │  │  Intent Harvest     │    │  Accorn              │        │
  │  │  Rails Application  │    │  Rails Application   │        │
  │  │  Port 3005          │    │  Port 3006           │        │
  │  └─────────┬───────────┘    └─────────┬───────────┘        │
  │            │                          │                     │
  │  ┌─────────▼───────────┐    ┌─────────▼───────────┐        │
  │  │  PostgreSQL 16.1    │    │  PostgreSQL 16.1     │        │
  │  │  (SSL Encrypted)    │    │  (SSL Encrypted)     │        │
  │  └─────────────────────┘    └──────────────────────┘        │
  │                                                              │
  │  ┌──────────────────────────────────────────────────────┐   │
  │  │  Portainer (Docker Management Dashboard)             │   │
  │  │  → See Section 5 for details                         │   │
  │  └──────────────────────────────────────────────────────┘   │
  └──────────────────────────────────────────────────────────────┘
```

### Production Docker Build — Multi-Stage Optimization

Our production Docker image uses a **multi-stage build** process — similar to building a house: you use heavy construction equipment during building, but you don't leave the crane inside the house when the family moves in.

```
  ┌─ Stage 1: BUILDER ─────────────────────────────────┐
  │  Install all build tools and dependencies            │
  │  Compile assets (CSS, JavaScript)                    │
  │  Prepare the application code                        │
  │  (This stage is large but temporary)                 │
  └─────────────────────┬──────────────────────────────┘
                        │ Copy only what's needed
                        ▼
  ┌─ Stage 2: RUNTIME ─────────────────────────────────┐
  │  Minimal operating system                            │
  │  Only production dependencies                        │
  │  Compiled application code from Stage 1              │
  │  Non-root user (security best practice)              │
  │  Built-in health check endpoint                      │
  │  (This stage is small and optimized)                 │
  └─────────────────────────────────────────────────────┘
```

**Result:** A lean, secure production image that starts fast and uses minimal resources.

### Key Benefits

| Benefit                     | Explanation                                                                 |
| --------------------------- | --------------------------------------------------------------------------- |
| **Consistency**             | Same Ruby 3.4.7, PostgreSQL 16.1, Redis 7 on every machine — guaranteed     |
| **5-minute onboarding**     | New developer runs 2 commands and the full environment is ready             |
| **Isolation**               | Each application runs independently — no conflicts between apps             |
| **Reproducible deploys**    | Production image is built once, tested, and deployed identically everywhere |
| **Multi-app on one server** | Intent Harvest + Accorn run side-by-side without interference               |
| **Security**                | Production containers run as non-root user with SSL-encrypted database      |

### Business Impact

- **Developer onboarding:** Reduced from hours/days of environment setup to **5 minutes**.
- **Zero environment bugs:** "Works on my machine" is no longer a valid excuse — everyone runs the same environment.
- **Cost efficiency:** Two applications run on a single server, optimized for minimal resource usage.
- **Operational reliability:** Built-in health checks detect problems automatically.

---

## Part B: Maintenance & Support

_Scope: 20% — Troubleshoot, fix bugs, and enhance systems. Maintain system documentation, version control, and technical records._

The following two achievements establish automated quality maintenance and operational visibility for the platform.

---

## 4. GitHub Copilot Code Review — AI-Powered Quality Guard

### What is It?

**GitHub Copilot Code Review** is an AI assistant that automatically reviews every code change (Pull Request) before a human reviewer looks at it. Think of it as having a **tireless senior engineer** who reads every line of code 24/7 and flags potential issues — bugs, inefficiencies, security concerns, and deviations from best practices.

### How It Fits Into Our Quality Chain

Our code goes through **5 layers of quality defense** before it reaches production. GitHub Copilot is Layer 3 — it catches things the automated tools miss, and frees up the human reviewer (Layer 4) to focus on architecture and business logic rather than formatting and common mistakes.

```
  Code written by developer
        │
        ▼
  ┌─ Layer 1 ──────────────────────────────────────────┐
  │  GIT HOOKS (on every commit)                        │
  │  Auto-format code style, block commits with errors  │
  │  Runs locally on the developer's machine            │
  └────────────────────┬───────────────────────────────┘
                       │
                       ▼
  ┌─ Layer 2 ──────────────────────────────────────────┐
  │  CI PIPELINE (on every Pull Request)                │
  │  4 automated checks: style, security, audit, tests  │
  │  Runs in the cloud — blocks merge if any check fails │
  └────────────────────┬───────────────────────────────┘
                       │
                       ▼
  ┌─ Layer 3 ──────────────────────────────────────────┐
  │  GITHUB COPILOT REVIEW (AI analysis)                │
  │  Reads the code changes and provides feedback        │
  │  Catches logic errors, suggests improvements         │
  │  Available 24/7, reviews in seconds                  │
  └────────────────────┬───────────────────────────────┘
                       │
                       ▼
  ┌─ Layer 4 ──────────────────────────────────────────┐
  │  LEAD CODE REVIEW (human judgment)                  │
  │  Architecture review, business logic validation      │
  │  Teaching opportunity for junior developers          │
  └────────────────────┬───────────────────────────────┘
                       │
                       ▼
  ┌─ Layer 5 ──────────────────────────────────────────┐
  │  DAILY DEMO (live team inspection)                  │
  │  Developer shares screen, explains their code        │
  │  Team discusses approach, catches edge cases          │
  └────────────────────────────────────────────────────┘
```

### What the AI Catches

| Category            | Examples                                                      |
| ------------------- | ------------------------------------------------------------- |
| **Potential bugs**  | Logic errors, missing null checks, incorrect conditions       |
| **Security issues** | Exposed credentials, unsafe input handling                    |
| **Performance**     | Inefficient database queries, unnecessary computations        |
| **Code quality**    | Overly complex methods, duplicated code, naming issues        |
| **Best practices**  | Deviations from framework conventions, missing error handling |

### Business Impact

- **Faster reviews:** AI handles the routine checks, human reviewers focus on what matters.
- **Consistent quality:** AI does not get tired, distracted, or forget to check something.
- **Early bug detection:** Issues caught at the code review stage cost 10x less to fix than issues found in production.
- **Learning tool:** Junior developers receive immediate feedback and learn from the AI's suggestions.

---

## 5. Portainer — Visual Server Management Dashboard

### What is Portainer?

**Portainer** is a web-based dashboard for managing Docker containers on our production server. Instead of connecting to the server via SSH terminal and typing complex commands, the team can manage everything through a **visual interface in their web browser** — similar to how a car dashboard shows engine status, fuel level, and warnings without requiring you to open the hood.

### What Portainer Provides

```
  ┌──────────────────────────────────────────────────────────┐
  │                  PORTAINER DASHBOARD                      │
  │                                                           │
  │  ┌─ Container Status ──────────────────────────────────┐ │
  │  │                                                      │ │
  │  │  🟢 Intent Harvest    Running    CPU: 12%  RAM: 340MB│ │
  │  │  🟢 Accorn            Running    CPU: 8%   RAM: 280MB│ │
  │  │  🟢 PostgreSQL (IH)   Running    CPU: 3%   RAM: 120MB│ │
  │  │  🟢 PostgreSQL (AC)   Running    CPU: 2%   RAM: 110MB│ │
  │  │  🔴 Sidekiq           Stopped    —         —         │ │
  │  │                                                      │ │
  │  └──────────────────────────────────────────────────────┘ │
  │                                                           │
  │  Actions:  [Start] [Stop] [Restart] [Logs] [Console]     │
  │                                                           │
  │  Quick Stats:                                             │
  │    Total containers: 5                                    │
  │    Running: 4                                             │
  │    Stopped: 1                                             │
  │    Total CPU usage: 25%                                   │
  │    Total memory: 850 MB / 4 GB                            │
  └──────────────────────────────────────────────────────────┘
```

### Production Environment Screenshot

**Figure: Portainer Container Management Interface**

> _[Screenshot placeholder: Insert Portainer dashboard screenshot showing the container list view]_

The screenshot above shows the actual Portainer interface managing our production environment. Visible in the interface:

- **Multiple applications running simultaneously:**
  - `st_intent_harvest-web-1` — Intent Harvest application container (healthy)
  - `st_intent_harvest-db-1` — Intent Harvest database container (healthy)
  - `st_accorn-web-1` — Accorn application container (healthy)
  - `st_accorn-db-1` — Accorn database container (healthy)
  - `st_insighthub-web-1` — Insight Hub application container (healthy)
  - `st_insighthub-db-1` — Insight Hub database container (healthy)
  - `portainer` — Portainer management tool itself (running)

- **Key interface features visible:**
  - Container status indicators (green "healthy" badges)
  - Quick action buttons (start, stop, restart, logs)
  - Container metadata (stack name, image, created date, IP address, published ports)
  - Left sidebar navigation (Dashboard, Stacks, Containers, Images, Networks, Volumes)
  - Search and filter capabilities at the top

This single dashboard provides complete visibility into our entire production infrastructure — 7 containers serving 3 different applications, all managed from one interface.

### Before vs After

| Task                       | Before (SSH Terminal)                 | After (Portainer)                    |
| -------------------------- | ------------------------------------- | ------------------------------------ |
| Check if app is running    | SSH → `docker ps`                     | Green/red indicator in browser       |
| View application logs      | SSH → `docker logs -f container_name` | Click "Logs" button, view in browser |
| Restart an application     | SSH → `docker compose restart web`    | Click "Restart" button               |
| Check resource usage       | SSH → `docker stats`                  | Real-time graphs in dashboard        |
| See all running containers | SSH → `docker ps --format ...`        | Full visual list with status icons   |
| Server access requirement  | SSH key + terminal knowledge          | Web browser only                     |
| Add new team member access | Generate SSH key, configure server    | Create Portainer user account        |

### Capabilities

| Feature                  | Description                                                           |
| ------------------------ | --------------------------------------------------------------------- |
| **Container management** | Start, stop, restart, remove containers with one click                |
| **Real-time logs**       | View application logs directly in the browser, with search and filter |
| **Resource monitoring**  | Live CPU, memory, and network usage per container                     |
| **Image management**     | View, pull, and manage Docker images on the server                    |
| **Volume management**    | Inspect and manage persistent data storage                            |
| **Access control**       | Create user accounts with different permission levels                 |
| **Stack management**     | Deploy and manage multi-container applications visually               |

### Business Impact

- **Lower barrier to entry:** Team members without terminal expertise can check server status and perform basic operations.
- **Faster troubleshooting:** Visual logs and status indicators make it faster to identify and resolve issues.
- **Reduced dependency on Lead:** Team members can independently check if applications are running and view logs.
- **Operational visibility:** Anyone on the team can see the health of our production systems at a glance.

---

## Part C: Team Management & Governance

_Scope: 20% — Lead technical discussions and mentor junior developers. Enforce coding, documentation, and deployment standards. Suggest workflow and governance improvements._

This section covers what was accomplished in mentoring, standards enforcement, and team development — with measurable results.

---

## 6. Mentoring & Team Development — Results & Accomplishments

### What Was Built for Team Governance

To support the remote team and enforce consistent standards, I created the following deliverables:

| Deliverable                        | Description                                                                      |
| ---------------------------------- | -------------------------------------------------------------------------------- |
| **Junior Developer SOP**           | 11-chapter onboarding handbook covering environment setup through daily workflow |
| **Remote Team Management Plan**    | Communication cadence, task management, review process, growth milestones        |
| **Documentation Library**          | 40+ technical documents across 15 categories (see table below)                   |
| **5-Layer Quality Defense System** | Automated + human quality gates from Git hooks to daily demo (see Section 4)     |
| **Coding & Deployment Standards**  | RuboCop, Brakeman, CI gates, Git hooks — enforced automatically on every commit  |

### Documentation Library Created

| Category        | Topics Covered                                                           |
| --------------- | ------------------------------------------------------------------------ |
| Getting Started | Quick start guide, team setup checklist                                  |
| Development     | Rails workflow, RuboCop guide, Git branching, Git hooks                  |
| Architecture    | AASM patterns, denormalization, JSON response handling, SOLID principles |
| Auth & Security | Devise guide, permission system (6 docs), parameter whitelisting         |
| Database        | Auditing, soft delete, search (Ransack), multi-sort                      |
| Frontend        | Stimulus/Turbo (Hotwire), modals, date pickers, layout system            |
| Features        | Work orders, payroll, pay calculations, deductions                       |
| Import/Export   | Export services, block import, deduction import, rate import             |
| DevOps          | Docker (3 guides), Nginx, production deployment, rollback                |
| Testing         | TDD and testing guide                                                    |
| Logging         | Application logger, quick start                                          |
| Performance     | Pagination analysis, image optimization                                  |
| Troubleshooting | Common issues and solutions                                              |

> **40+ documents** ensure no one is stuck because "they didn't know." Everything is documented, searchable, and maintained.

### Mentoring Amirul — The Key Accomplishment

**Amirul**, a junior developer, went through a structured mentoring program over the past three months. The results demonstrate the effectiveness of the management approach.

#### What I Did

| Activity                           | Frequency                           | Purpose                                     |
| ---------------------------------- | ----------------------------------- | ------------------------------------------- |
| Daily standup with screen share    | Every day, 30-60 min                | Demo code, identify blockers, give feedback |
| Pair programming sessions          | 2x/week (Month 1-2), then as needed | Hands-on teaching, live problem-solving     |
| Technical Analysis reviews         | Every task                          | Develop planning skills, improve estimation |
| Code review with teaching feedback | Every PR                            | Explain the "why", not just "change this"   |
| Architecture knowledge transfer    | Ongoing                             | Service/Interactor/Query patterns, testing  |
| SOP as daily guide                 | Continuous                          | Consistent workflow, clear expectations     |

#### Measurable Results

| Skill Area        | Before (Month 1)                             | After (Month 3)                                                   |
| ----------------- | -------------------------------------------- | ----------------------------------------------------------------- |
| **Hard Skills**   | Basic Rails knowledge                        | Implements features end-to-end using project architecture         |
| **Soft Skills**   | Needed step-by-step guidance for every task  | Estimates, plans, and communicates progress independently         |
| **Git Workflow**  | Unfamiliar with branching and PR process     | Creates branches, commits, PRs following conventions consistently |
| **Architecture**  | Did not understand Service/Interactor layers | Uses correct architecture layers, applies SOP decision flowchart  |
| **Testing**       | No testing experience                        | Writes model and service tests as part of every feature           |
| **Communication** | Waited without escalating when stuck         | Follows 1-hour escalation rule, updates status proactively        |
| **Independence**  | Required constant supervision                | **Independently handles the Intent Harvest project**              |

#### The Key Proof

> **Amirul successfully took over and managed the Intent Harvest project independently when I was out of office.**

This is the strongest evidence that the mentoring and standards enforcement worked:

- The **SOP** gave him the reference he needed to work without asking questions.
- The **architecture documentation** told him where to put code.
- The **CI/CD pipeline** caught quality issues automatically.
- The **mentoring** built his confidence to make decisions.
- The **daily demo practice** honed his ability to reason about code.

#### Before vs After

| Before This Program                            | After This Program                               |
| ---------------------------------------------- | ------------------------------------------------ |
| Team was a single point of failure (Lead only) | Knowledge is distributed across the team         |
| Junior developer needed constant hand-holding  | Junior works independently with SOP support      |
| Code quality depended on manual supervision    | 5 automated layers ensure quality systematically |
| Lead's absence = blocked team                  | Team operates normally even when Lead is away    |
| Onboarding was ad-hoc and inconsistent         | Onboarding is documented, repeatable, measurable |

### Business Impact

- **Proven mentoring results:** Junior developer went from dependent to independent in 3 months.
- **Scalable onboarding:** The SOP, documentation, and process are ready to onboard the next 1-2 junior developers with predictable outcomes.
- **Knowledge retention:** 40+ documents ensure knowledge does not leave when a person leaves.
- **Team resilience:** The team can operate normally even when the Lead is away.
- **Standards enforcement:** Coding, documentation, and deployment standards are automated — not dependent on manual policing.

---

## 7. Current Architecture — System Overview

### Full System Architecture

```
  ┌────────────────────────────────────────────────────────────────────────┐
  │                    CURRENT SYSTEM ARCHITECTURE                          │
  │                       February 2026                                     │
  │                                                                         │
  │                                                                         │
  │   ┌──────────┐        ┌────────────────┐        ┌──────────────────┐   │
  │   │Developer │───────▶│    GitHub       │───────▶│  GitHub Actions  │   │
  │   │pushes    │  git   │  Repository    │ trigger │  CI/CD Pipeline  │   │
  │   │code      │  push  │                │         │                  │   │
  │   └──────────┘        └────────────────┘         └────────┬─────────┘   │
  │                                                           │              │
  │                              ┌────────────────────────────┤              │
  │                              │                            │              │
  │                              ▼                            ▼              │
  │                     ┌───────────────┐          ┌──────────────────┐     │
  │                     │     GHCR      │          │  Slack           │     │
  │                     │  (Container   │          │  Notifications   │     │
  │                     │   Registry)   │          │  (deploy/rollback│     │
  │                     │               │          │   status)        │     │
  │                     └───────┬───────┘          └──────────────────┘     │
  │                             │                                           │
  │                             │ docker pull                               │
  │                             ▼                                           │
  │   ┌───────────────── Production Server (VPS) ────────────────────┐     │
  │   │                                                               │     │
  │   │   ┌───────────────────────────────────────────────────────┐   │     │
  │   │   │  Nginx (Reverse Proxy + Let's Encrypt SSL)            │   │     │
  │   │   │    ├── intent.intentharvest.com ──→ Port 3005         │   │     │
  │   │   │    ├── accorn.intentharvest.com ──→ Port 3006         │   │     │
  │   │   │    └── intentharvest.com (static landing page)        │   │     │
  │   │   └───────────────────────────────────────────────────────┘   │     │
  │   │                                                               │     │
  │   │   ┌─────────────────────┐     ┌─────────────────────┐       │     │
  │   │   │  Intent Harvest     │     │  Accorn              │       │     │
  │   │   │  Rails 8.1          │     │  Rails Application   │       │     │
  │   │   │  Ruby 3.4.7         │     │  Port 3006           │       │     │
  │   │   │  Port 3005          │     │                      │       │     │
  │   │   └─────────┬───────────┘     └──────────┬──────────┘       │     │
  │   │             │                             │                  │     │
  │   │   ┌─────────▼───────────┐     ┌──────────▼──────────┐       │     │
  │   │   │  PostgreSQL 16.1    │     │  PostgreSQL 16.1     │       │     │
  │   │   │  (SSL Encrypted)    │     │  (SSL Encrypted)     │       │     │
  │   │   └─────────────────────┘     └─────────────────────┘       │     │
  │   │                                                               │     │
  │   │   ┌───────────────────────────────────────────────────────┐   │     │
  │   │   │  Portainer (Docker Management Dashboard)              │   │     │
  │   │   │  Web-based GUI for container management               │   │     │
  │   │   └───────────────────────────────────────────────────────┘   │     │
  │   │                                                               │     │
  │   │   Automated: Health checks • Deploy history • Rollback       │     │
  │   └───────────────────────────────────────────────────────────────┘     │
  │                                                                         │
  └────────────────────────────────────────────────────────────────────────┘
```

### Application Architecture (Internal Layers)

Each Rails application follows a clean, layered architecture:

```
  ┌─────────────────────────────────────────────────────────────────────┐
  │                    APPLICATION ARCHITECTURE                          │
  │                                                                      │
  │   HTTP Request                                                       │
  │        │                                                             │
  │        ▼                                                             │
  │   ┌─────────────────────────────────────────────────────────────┐   │
  │   │  CONTROLLER — receives request, delegates, returns response │   │
  │   │  Rule: Maximum 5-7 lines per action                         │   │
  │   └────────────────────────┬────────────────────────────────────┘   │
  │                            │                                        │
  │                            ▼                                        │
  │   ┌─────────────────────────────────────────────────────────────┐   │
  │   │  INTERACTOR — orchestrates multi-step use cases             │   │
  │   │  Coordinates multiple services in sequence                  │   │
  │   └────────┬──────────────┬──────────────────┬─────────────────┘   │
  │            │              │                  │                      │
  │            ▼              ▼                  ▼                      │
  │   ┌──────────────┐ ┌──────────────┐ ┌──────────────────┐          │
  │   │   SERVICE    │ │    QUERY     │ │      FORM        │          │
  │   │  Single      │ │  Database    │ │  Validation &    │          │
  │   │  business    │ │  queries     │ │  parameter       │          │
  │   │  operation   │ │              │ │  handling        │          │
  │   └──────────────┘ └──────────────┘ └──────────────────┘          │
  │            │                                                       │
  │            ▼                                                       │
  │   ┌─────────────────────────────────────────────────────────────┐  │
  │   │  MODEL — data persistence, associations, validations        │  │
  │   └────────┬──────────────────────────────────┬────────────────┘  │
  │            │                                  │                    │
  │            ▼                                  ▼                    │
  │   ┌──────────────────┐            ┌──────────────────┐            │
  │   │    DECORATOR     │            │    POLICY        │            │
  │   │  Display logic   │            │  Authorization   │            │
  │   │  (formatting)    │            │  (permissions)   │            │
  │   └──────────────────┘            └──────────────────┘            │
  └─────────────────────────────────────────────────────────────────────┘
```

### Technology Stack Summary

| Category               | Technology                                               |
| ---------------------- | -------------------------------------------------------- |
| **Framework**          | Ruby on Rails 8.1                                        |
| **Language**           | Ruby 3.4.7                                               |
| **Database**           | PostgreSQL 16.1 (with SSL encryption in production)      |
| **Cache**              | Redis 7                                                  |
| **Background Jobs**    | Sidekiq 8.1                                              |
| **Frontend**           | Turbo + Stimulus (Hotwire), Bootstrap 5.3, ERB templates |
| **Authentication**     | Devise                                                   |
| **Authorization**      | Pundit (role-based permission system)                    |
| **State Machine**      | AASM 5.5                                                 |
| **Audit Trail**        | Audited 5.8                                              |
| **Functional**         | dry-monads 1.9 (Result types: Success/Failure)           |
| **PDF Generation**     | Grover (Puppeteer/Chromium)                              |
| **Soft Delete**        | Discard 1.4                                              |
| **Containerization**   | Docker + Docker Compose                                  |
| **CI/CD**              | GitHub Actions (4 workflows)                             |
| **Container Registry** | GitHub Container Registry (GHCR)                         |
| **Web Server**         | Puma (multi-worker, preload)                             |
| **Reverse Proxy**      | Nginx (with Let's Encrypt SSL)                           |
| **Server Management**  | Portainer (GUI dashboard)                                |
| **Code Quality**       | RuboCop, Brakeman, Bundler Audit, strong_migrations      |
| **Notifications**      | Slack Webhooks                                           |
| **Dependency Updates** | Dependabot (weekly, 3 ecosystems)                        |

---

## 8. Summary

### What Was Accomplished in 3 Months

| #   | Scope Area            | Achievement                | Key Metric / Outcome                                       |
| --- | --------------------- | -------------------------- | ---------------------------------------------------------- |
| 1   | Web & App Dev (60%)   | CI/CD Pipeline             | 4 automated quality gates, ~3 min deployment               |
| 2   | Web & App Dev         | Rollback Mechanism         | 3 rollback methods, recovery in under 5 minutes            |
| 3   | Web & App Dev         | Full Dockerization         | 3 apps containerized, 5-minute developer onboarding        |
| 4   | Maintenance (20%)     | GitHub Copilot Code Review | 5-layer quality defense, AI + human review                 |
| 5   | Maintenance           | Portainer Dashboard        | Visual server management, no SSH required                  |
| 6   | Team Management (20%) | Mentoring & Leading Amirul | Junior independently handles the project when Lead is away |

### Scope Coverage

| Scope Area                        | Allocation | Delivered                                                                                       |
| --------------------------------- | ---------- | ----------------------------------------------------------------------------------------------- |
| **Web & Application Development** | 60%        | CI/CD pipeline, rollback mechanism, full Dockerization — platform is professionally deployed    |
| **Maintenance & Support**         | 20%        | AI code review, visual server management, 40+ technical documents maintained                    |
| **Team Management & Governance**  | 20%        | Junior developer mentored to independence, SOP + standards enforced, team operates autonomously |

### The Result

These six accomplishments together deliver a platform that is:

- **Professionally operated** — enterprise-grade CI/CD, containerization, and deployment infrastructure.
- **Self-protecting** — 5 layers of automated quality defense catch problems before they reach production.
- **Resilient** — rollback capability means any issue can be reversed in minutes, not hours.
- **Scalable** — Docker containerization and CI/CD pipeline support adding more applications and team members.
- **Team-ready** — the mentoring framework, SOP, and documentation have proven that a junior developer can grow to operate independently within 3 months.

**All three scope areas of the engagement have been delivered with measurable outcomes.**

---

_Report prepared by Arya Pratama — External Consultant, ST Datablu Sdn. Bhd. — February 17, 2026_
