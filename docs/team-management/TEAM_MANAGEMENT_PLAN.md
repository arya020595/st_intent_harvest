# Remote Team Management Plan

## Document Information

| Field        | Value                        |
| ------------ | ---------------------------- |
| Author       | Team Lead                    |
| Created      | February 2026                |
| Last Updated | February 2026                |
| Status       | Active                       |
| Applies To   | All remote development teams |

---

## Table of Contents

1. [Team Overview](#1-team-overview)
2. [Communication Cadence](#2-communication-cadence)
3. [Communication Tools — Slack](#3-communication-tools--slack)
4. [Task Management Workflow — Google Sheets](#4-task-management-workflow--google-sheets)
5. [Technical Analysis Process](#5-technical-analysis-process)
6. [Development Workflow](#6-development-workflow)
7. [Code Review Process](#7-code-review-process)
8. [Metrics & Accountability](#8-metrics--accountability)
9. [Junior Growth Plan](#9-junior-growth-plan)
10. [Boss Presentation Outline](#10-boss-presentation-outline)

---

## 1. Team Overview

### Team Structure

```
                    ┌──────────────────────┐
                    │     TEAM LEAD        │
                    │   (Surabaya, SBY)    │
                    │                      │
                    │  • Architecture      │
                    │  • Code Review       │
                    │  • Task Assignment   │
                    │  • Sprint Planning   │
                    │  • Stakeholder Comm  │
                    └──────────┬───────────┘
                               │
                 ┌─────────────┴─────────────┐
                 │                           │
        ┌────────────────┐         ┌────────────────┐
        │   JUNIOR DEV A │         │   JUNIOR DEV B │
        │  (Mojokerto)   │         │   (Blitar)     │
        │                │         │                │
        │  • Feature     │         │  • Feature     │
        │    Development │         │    Development │
        │  • Bug Fixes   │         │  • Bug Fixes   │
        │  • Testing     │         │  • Testing     │
        │  • Docs        │         │  • Docs        │
        └────────────────┘         └────────────────┘
```

### Roles & Responsibilities

| Role                 | Responsibilities                                                                                                                   |
| -------------------- | ---------------------------------------------------------------------------------------------------------------------------------- |
| **Team Lead**        | Architecture decisions, code review, task assignment, sprint planning, stakeholder communication, mentoring, quality assurance     |
| **Junior Developer** | Feature implementation (under guidance), bug fixing, writing tests, writing technical analysis, updating documentation, daily demo |

### Key Principles

1. **Structure creates freedom** — Clear processes reduce confusion and increase autonomy
2. **Measure output, not hours online** — Results matter, not screen time
3. **Async-first, sync when needed** — Default to written communication; meetings for alignment and demos
4. **No one stays stuck alone** — Escalate blockers quickly (1-hour rule)
5. **Learn by doing, supported by mentoring** — Juniors grow through guided practice

---

## 2. Communication Cadence

### Daily Rituals

| Ritual                  | Time      | Duration  | Format                     | Participants | Purpose                                                            |
| ----------------------- | --------- | --------- | -------------------------- | ------------ | ------------------------------------------------------------------ |
| Async Standup (Geekbot) | 08:30 WIB | 5 min     | Slack bot                  | All          | Written update before live meeting                                 |
| Daily Standup + Demo    | 09:00 WIB | 30-60 min | Screen share (Google Meet) | All          | Screen share progress, demo code, identify blockers, give feedback |

### Weekly Rituals

| Ritual               | Day    | Duration  | Format      | Purpose                                              |
| -------------------- | ------ | --------- | ----------- | ---------------------------------------------------- |
| Sprint Planning      | Monday | 30-45 min | Google Meet | Review Google Sheets, assign tasks, set weekly goals |
| Weekly Retrospective | Friday | 15-20 min | Google Meet | What went well, what to improve, action items        |

### Biweekly Rituals

| Ritual                  | Duration  | Format       | Purpose                                       |
| ----------------------- | --------- | ------------ | --------------------------------------------- |
| 1-on-1 with each Junior | 15-30 min | Private call | Growth feedback, career development, concerns |

### Core Hours

```
Core collaboration hours: 09:00 - 12:00 WIB (Monday - Friday)

During core hours:
✅ Must be available on Slack
✅ Respond to messages within 30 minutes
✅ Available for ad-hoc calls if needed

Outside core hours:
✅ Work at your own pace
✅ Async communication only
✅ No expectation of immediate response
```

---

## 3. Communication Tools — Slack

### Channel Structure

| Channel            | Purpose                                                | Who Posts             |
| ------------------ | ------------------------------------------------------ | --------------------- |
| `#team-dev`        | Team discussions, daily standup results, announcements | Everyone              |
| `#proj-<name>`     | Project-specific discussion, technical decisions       | Everyone              |
| `#proj-<name>-dev` | Automated notifications (GitHub PRs, CI/CD results)    | Bots only             |
| `#code-review`     | PR links that need review, review discussions          | Everyone              |
| `#til-learning`    | "Today I Learned" — share what you learned             | Everyone (encouraged) |
| `#random`          | Non-work chat, bonding, memes                          | Everyone              |

### Required Integrations

#### 1. GitHub Integration (Free)

```
Setup: /github subscribe owner/repo pulls,reviews,comments,deployments
Channel: #proj-<name>-dev (automated channel)
```

What it does:

- Notifies when PRs are created, reviewed, or merged
- Notifies when CI fails
- Lead gets instant visibility without checking GitHub manually

#### 2. Geekbot (Free for ≤3 people)

Async standup bot — asks 3 questions every morning at 08:30 WIB:

```
1. What did you do yesterday?
2. What will you do today?
3. Any blockers?
```

- Answers compiled to `#team-dev` channel
- Lead reviews before the live standup meeting
- Live meeting then focuses on **demo and deep-dive**, not status updates

#### 3. Slack Reminders (Built-in)

```
/remind #team-dev "Daily standup in 15 minutes ☕" every weekday at 8:45am
/remind #team-dev "Update task status in Google Sheets before EOD 📋" every weekday at 5:00pm
/remind #team-dev "Weekly retro in 30 minutes 🔄" every Friday at 3:30pm
```

### Slack Rules

| Rule                                                                      | Why                              |
| ------------------------------------------------------------------------- | -------------------------------- |
| Always reply in **threads**, not main channel                             | Keep channels scannable          |
| Paste code in **code blocks** (triple backtick), never screenshot code    | Searchable, copyable, reviewable |
| Set Slack status to current task: `🔨 Working on CA-123 - Payout feature` | Team visibility                  |
| Respond within **30 minutes** during core hours                           | Maintain team flow               |
| Use `@here` sparingly, `@channel` almost never                            | Avoid notification fatigue       |

### Escalation Protocol

```
Stuck for 30 minutes  → Search docs, Google, Stack Overflow
Stuck for 1 hour      → DM the Lead immediately with:
                          1. What you're trying to do
                          2. What you've tried
                          3. The error/blocker
Stuck for 2+ hours    → Pair programming session with Lead (screen share)
```

> **Rule: Never stay stuck silently.** It's always better to ask "dumb" questions than to waste hours going in circles.

---

## 4. Task Management Workflow — Google Sheets

### Sheet Structure

| Column         | Purpose                             | Example                            |
| -------------- | ----------------------------------- | ---------------------------------- |
| **Task**       | Clear, actionable description       | "Implement payout withdrawal flow" |
| **Priority**   | P0-P3                               | P1                                 |
| **Estimation** | Man-days (after technical analysis) | 3 days                             |
| **Status**     | Current state                       | In Progress                        |
| **Assign**     | Who is responsible                  | Junior A                           |

### Recommended Additional Columns

| Column                      | Purpose                      | Example                               |
| --------------------------- | ---------------------------- | ------------------------------------- |
| **Technical Analysis Link** | Google Doc with analysis     | [Link]                                |
| **PR Link**                 | GitHub PR when ready         | [Link]                                |
| **Actual Days**             | How long it actually took    | 4 days                                |
| **Notes**                   | Blockers, decisions, context | "Waiting for payment gateway API key" |
| **Due Date**                | Expected completion          | 2026-02-21                            |
| **Sprint**                  | Which sprint/week            | Sprint 5                              |

### Status Flow

```
Backlog → Analysis → Review Analysis → In Progress → In Review → Done
   │          │            │                │            │          │
   │          │            │                │            │          └─ Merged + deployed
   │          │            │                │            └─ PR created, awaiting review
   │          │            │                └─ Coding in progress
   │          │            └─ Lead reviewing the technical analysis
   │          └─ Junior writing technical analysis
   └─ Not yet started, in the queue
```

### Priority Definitions

| Priority | Label    | Description                             | Response Time           |
| -------- | -------- | --------------------------------------- | ----------------------- |
| **P0**   | Critical | Production is broken, data loss risk    | Immediately (hotfix)    |
| **P1**   | High     | Blocking other work, deadline-sensitive | Start within 1 day      |
| **P2**   | Medium   | Important but not urgent                | Start within the sprint |
| **P3**   | Low      | Nice to have, improvements              | When time allows        |

### Weekly Task Review Process

**Monday Sprint Planning (30-45 min):**

1. Review previous week's completed vs planned (accuracy check)
2. Review backlog together
3. Junior picks tasks (guided by Lead)
4. Junior writes estimated man-days
5. Lead approves or adjusts estimates
6. Update Google Sheets

**Friday Check:**

1. Compare estimated vs actual days for completed tasks
2. Identify carry-over tasks and why
3. Feed into retrospective discussion

---

## 5. Technical Analysis Process

### Why Technical Analysis?

- Forces thinking **before** coding → fewer rewrites
- Improves estimation accuracy → better delivery predictability
- Catches edge cases **early** → higher quality
- Creates a record of **why** decisions were made

### Template

```markdown
# Technical Analysis: [Task Name]

## 1. Objective

What are we trying to achieve? What problem does this solve?

## 2. Affected Files / Modules

List the specific files, models, controllers, services that will be created or modified.

| File                                         | Action | Description                       |
| -------------------------------------------- | ------ | --------------------------------- |
| `app/models/payout.rb`                       | Modify | Add new state machine transitions |
| `app/services/payouts/withdrawal_service.rb` | Create | Handle withdrawal business logic  |
| `db/migrate/xxx_add_status_to_payouts.rb`    | Create | Add status column                 |

## 3. Database Changes

- New tables?
- New columns?
- New indexes?
- Migrations needed?
- Data migration required?

## 4. Architecture Approach

Which layers will be used? (Service, Interactor, Form Object, Query Object, etc.)
Why this approach?

## 5. Dependencies / Blockers

- External APIs needed?
- Other tasks that must be completed first?
- Data that needs to be seeded?
- Credentials or access needed?

## 6. Edge Cases

- What happens if X fails?
- What about empty data?
- Concurrent access?
- Permission checks?

## 7. Test Plan

How will this be verified?

- Model tests for: ...
- Service tests for: ...
- Manual testing steps: ...

## 8. Estimated Effort

| Subtask                | Estimated Days |
| ---------------------- | -------------- |
| Database migration     | 0.5            |
| Service implementation | 1              |
| Controller + views     | 1              |
| Tests                  | 0.5            |
| Code review + fixes    | 0.5            |
| **Total**              | **3.5 days**   |

## 9. Questions / Open Items

Anything unclear that needs Lead input before starting?
```

### Technical Analysis Workflow

```
1. Lead assigns task in Google Sheets (status: "Backlog")
2. Junior picks task, changes status to "Analysis"
3. Junior writes Technical Analysis in Google Doc
4. Junior shares link in Google Sheets + pings Lead on Slack
5. Lead reviews analysis:
   a. APPROVED → Junior starts coding (status: "In Progress")
   b. NEEDS REVISION → Lead provides feedback, junior revises
6. Technical Analysis doc stays linked for future reference
```

### Common Estimation Mistakes

| Mistake                           | How to Avoid                                                    |
| --------------------------------- | --------------------------------------------------------------- |
| Forgetting to account for tests   | Always add 20-30% for testing                                   |
| Not considering code review cycle | Add 0.5 day for review + fixes                                  |
| Underestimating database changes  | Check if migration affects existing data                        |
| Ignoring edge cases               | List at least 3 edge cases before estimating                    |
| Not breaking into subtasks        | Never estimate a task > 3 days as a single item — break it down |

---

## 6. Development Workflow

### End-to-End Flow

```
┌──────────────────────────────────────────────────────────┐
│                    TASK LIFECYCLE                          │
│                                                           │
│  1. Pick Task        Google Sheets → "Analysis"           │
│         │                                                 │
│  2. Tech Analysis    Write analysis → Lead approves       │
│         │                                                 │
│  3. Create Branch    feature/<task>-<description>         │
│         │                                                 │
│  4. Implement        Follow SOP + Architecture Rules      │
│         │                                                 │
│  5. Quality Check    RuboCop ✓ Tests ✓ Manual QA ✓       │
│         │                                                 │
│  6. Push             Git hooks auto-run checks            │
│         │                                                 │
│  7. Create PR        Use PR template checklist            │
│         │                                                 │
│  8. Code Review      Lead reviews in daily meeting        │
│         │                                                 │
│  9. Merge            Lead approves → merge to develop     │
│         │                                                 │
│  10. Update Sheet    Status → "Done", log actual days     │
└──────────────────────────────────────────────────────────┘
```

### Git Branch Convention

| Branch Type | Format                          | Example                                   |
| ----------- | ------------------------------- | ----------------------------------------- |
| Feature     | `feature/<task>-<description>`  | `feature/CA-012-payout-withdrawal`        |
| Bug Fix     | `fix/<task>-<description>`      | `fix/CA-045-order-status-stuck`           |
| Hotfix      | `hotfix/<task>-<description>`   | `hotfix/CA-078-payment-timeout`           |
| Refactor    | `refactor/<task>-<description>` | `refactor/CA-090-extract-payment-service` |

### Commit Convention

```
<type>: <short description>

Types:
  feat:     New feature
  fix:      Bug fix
  refactor: Code restructuring (no behavior change)
  chore:    Dependencies, config, CI/CD
  test:     Adding or updating tests
  docs:     Documentation updates
  style:    Formatting, whitespace (no logic change)

Examples:
  feat: add payout withdrawal endpoint
  fix: resolve N+1 query in orders index
  refactor: extract payment logic to service object
  test: add model tests for Payout
  docs: update architecture guide with presenter pattern
```

---

## 7. Code Review Process

### Review Happens In Two Places

1. **Daily Meeting (Live):** Junior shares screen, demos the code, explains approach
2. **GitHub PR (Written):** Lead leaves comments on specific lines

### What Lead Reviews

| Aspect           | What to Check                                                      |
| ---------------- | ------------------------------------------------------------------ |
| **Architecture** | Is the code in the right layer? (Service, Interactor, Query, etc.) |
| **Code Quality** | Clean, readable, follows naming conventions?                       |
| **SOLID**        | Single responsibility? Not doing too many things?                  |
| **Edge Cases**   | Handles nil, empty, invalid input?                                 |
| **Tests**        | Are there tests? Do they cover the important paths?                |
| **Performance**  | N+1 queries? Unnecessary database calls?                           |
| **Security**     | Strong parameters? Authorization checks?                           |
| **Migrations**   | Reversible? Indexes on foreign keys?                               |

### Review Protocol

```
Lead reviews PR → one of:
  ✅ APPROVED       → Merge immediately
  💬 COMMENT        → Minor suggestions, can merge after addressing
  ❌ CHANGES NEEDED → Must fix and re-request review
```

### Definition of Done

A task is "Done" when **all** of the following are true:

- [ ] Code is merged to `develop` (or `main`)
- [ ] Reviewed by at least the Lead
- [ ] All tests pass (CI green)
- [ ] RuboCop clean
- [ ] Manually tested
- [ ] Google Sheets status updated to "Done"
- [ ] Actual days logged in Google Sheets

---

## 8. Metrics & Accountability

### Weekly Metrics (Tracked in Google Sheets)

| Metric                  | How to Measure                      | Target                         |
| ----------------------- | ----------------------------------- | ------------------------------ |
| **Tasks Completed**     | Count of tasks moved to "Done"      | Increase over time             |
| **Estimation Accuracy** | Actual days / Estimated days × 100% | 80-120% range                  |
| **PR Turnaround**       | Time from PR created to merged      | < 24 hours                     |
| **RuboCop Violations**  | New violations introduced           | 0 new violations               |
| **Test Coverage**       | Tests written for new code          | Every new service/model tested |

### Monthly Check-in (1-on-1)

| Area         | Questions to Discuss                                                     |
| ------------ | ------------------------------------------------------------------------ |
| **Workload** | Are you overwhelmed or bored? Is the task difficulty appropriate?        |
| **Growth**   | What new skill did you learn this month? What do you want to learn next? |
| **Blockers** | Are there recurring blockers? Do you need better tools/access?           |
| **Process**  | Is the SOP helpful or too rigid? What would you change?                  |
| **Team**     | How is communication with the team? Any concerns?                        |

### Estimation Tracking Table

Add this to Google Sheets or maintain separately:

| Sprint | Task           | Estimated | Actual  | Accuracy | Notes                     |
| ------ | -------------- | --------- | ------- | -------- | ------------------------- |
| S1     | Payout feature | 3 days    | 4 days  | 75%      | Underestimated edge cases |
| S1     | Fix order bug  | 0.5 day   | 0.5 day | 100%     | Good estimate             |

Over time, this table reveals patterns:

- Consistently underestimating? → Add buffer
- Certain task types always take longer? → Adjust estimation formula
- Getting more accurate? → Junior is improving

---

## 9. Junior Growth Plan

### Month 1-2: Foundation (Guided)

```
Goal: Follow SOP strictly, learn project patterns, build trust

Activities:
├── Follow JUNIOR_DEVELOPER_SOP.md for every task
├── Pair programming with Lead: 2x per week (30-60 min)
├── Write Technical Analysis for every task (Lead reviews all)
├── Demo code in daily standup with explanation
├── Read and understand ENTERPRISE_ARCHITECTURE_GUIDE.md
└── Complete at least 3 small features end-to-end

Checkpoints:
☐ Can set up development environment independently
☐ Can create branch, commit, push, create PR correctly
☐ Can write a Technical Analysis without major revisions
☐ Understands Service/Interactor/Query/Form layers
☐ Can write basic model and service tests
☐ RuboCop passes consistently without help
```

### Month 3-4: Autonomy (Semi-guided)

```
Goal: Work more independently, start contributing to team processes

Activities:
├── Write Technical Analysis independently (Lead spot-checks)
├── Pair programming: 1x per week (as needed)
├── Start reviewing each other's PRs (peer review)
├── Take on medium-complexity features
├── Write mini-docs for features they implement
└── Participate actively in retrospectives with improvement ideas

Checkpoints:
☐ Technical Analysis requires minimal revision
☐ Estimation accuracy improves to 80-120% range
☐ Can identify and fix N+1 queries independently
☐ Peer reviews are constructive and catch real issues
☐ Can explain their code decisions with reasoning
☐ Contributes at least 1 improvement idea per retrospective
```

### Month 5-6: Ownership (Self-directed)

```
Goal: Own features end-to-end, mentor newer team members

Activities:
├── Take ownership of entire features from analysis to deployment
├── Propose technical approaches to Lead (not just receive)
├── Contribute to architecture docs
├── Lead at least 1 daily standup per week
├── Help onboard any new team members
└── Identify technical debt and propose solutions

Checkpoints:
☐ Can break down complex features into subtasks independently
☐ Estimation accuracy consistently within 80-120%
☐ Code quality requires minimal review feedback
☐ Proactively identifies edge cases and security concerns
☐ Has documented at least 2 features in docs/
☐ Team considers them reliable for independent feature delivery
```

### Skills Development Checklist

| Skill Category    | Skills                                                      | Target Completion |
| ----------------- | ----------------------------------------------------------- | ----------------- |
| **Ruby/Rails**    | ActiveRecord, migrations, validations, associations, scopes | Month 1-2         |
| **Architecture**  | dry-monads, Service objects, Interactors, Query objects     | Month 2-3         |
| **Testing**       | Minitest, fixtures, model tests, service tests              | Month 2-3         |
| **Frontend**      | Turbo, Stimulus, ERB templates, Bootstrap                   | Month 3-4         |
| **DevOps**        | Docker basics, CI/CD pipeline, deployment flow              | Month 4-5         |
| **Security**      | Strong parameters, Pundit policies, OWASP basics            | Month 4-5         |
| **Code Review**   | Reading others' code, giving constructive feedback          | Month 3-6         |
| **Communication** | Technical writing, estimation, stakeholder updates          | Month 1-6         |

---

## 10. Boss Presentation Outline

### One-Page Summary for Friday Session

```
REMOTE TEAM MANAGEMENT PLAN
============================

TEAM: 3 people (Lead + 2 Juniors), spread across Surabaya, Mojokerto, Blitar

CURRENT STATE (Already Running):
├── Daily standup with screen share + demo
├── RuboCop for code formatting
├── CI pipeline (RuboCop, Brakeman, tests)
└── Architecture documentation in place

PROPOSED IMPROVEMENTS:
├── 1. Structured SOP for juniors (detailed blueprint document)
├── 2. Technical Analysis before coding (estimation + quality)
├── 3. Google Sheets task board (Task | Priority | Estimation | Status | Assign)
├── 4. PR template with quality checklist
├── 5. Slack integrations (GitHub bot, Geekbot async standup)
├── 6. Git hooks (auto-run RuboCop + tests before push)
├── 7. Weekly retrospective (continuous improvement)
└── 8. Junior growth plan with 6-month milestones

HOW WE MEASURE SUCCESS:
├── Tasks completed per sprint
├── Estimation accuracy (target: 80-120%)
├── PR review turnaround (target: < 24 hours)
├── Code quality (zero new RuboCop violations)
└── Junior growth milestones met on schedule

EXPECTED OUTCOMES:
├── Consistent code quality regardless of who writes it
├── Predictable delivery timelines
├── Juniors growing into independent contributors within 6 months
└── Scalable process — works for 3 people, works for 10
```

### Talking Points

1. **"Why structure?"** → Remote teams fail without rhythm. Clear processes reduce confusion, increase autonomy, and make quality predictable.

2. **"Why technical analysis?"** → Forces thinking before coding. Reduces rewrites by catching issues early. Improves estimation accuracy over time.

3. **"How do we ensure code quality?"** → Multi-layer defense: SOP guidelines → git hooks (auto-format) → CI pipeline (automated checks) → PR review (human review) → daily demo (live inspection).

4. **"How do we grow the juniors?"** → Structured 6-month plan. Month 1-2 guided, Month 3-4 semi-independent, Month 5-6 autonomous. Measured by concrete checkpoints.

5. **"What if a junior is stuck?"** → 1-hour escalation rule. Geekbot catches blockers in async standup. Daily live meeting catches everything else.

6. **"Is this scalable?"** → Yes. Google Sheets scales to 5-10 people. SOP is project-agnostic. Slack channels can be added per project. The process is the same whether the team is 3 or 15.

---

## Appendix: Quick Reference

### Daily Checklist (Lead)

```
☐ Review Geekbot standup answers before daily meeting
☐ Run daily standup + demo meeting (09:00)
☐ Review any open PRs
☐ Check Google Sheets for blocked tasks
☐ Respond to Slack messages within core hours
☐ End of day: quick scan of tomorrow's priorities
```

### Daily Checklist (Junior)

```
☐ Answer Geekbot standup questions (08:30)
☐ Join daily standup + demo (09:00)
☐ Update Google Sheets status
☐ Work on assigned task following SOP
☐ Push code + create/update PR
☐ End of day: update Google Sheets, prepare demo for tomorrow
```

### Weekly Checklist (Lead)

```
☐ Monday: Sprint planning meeting, assign tasks
☐ Wednesday: Check estimation accuracy mid-week
☐ Friday: Weekly retrospective
☐ Friday: Update metrics in Google Sheets
☐ Biweekly: 1-on-1 with each junior
```
