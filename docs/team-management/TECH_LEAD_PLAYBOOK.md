# Tech Lead Playbook — Leading a Mixed Remote Team

## A Practical Guide for Managing a Distributed Engineering Team Across Experience Levels

| Field        | Value                                                              |
| ------------ | ------------------------------------------------------------------ |
| Author       | Arya Pratama                                                       |
| Created      | February 2026                                                      |
| Last Updated | February 2026                                                      |
| Status       | Active                                                             |
| Team Size    | 1 Tech Lead + 4 Developers (mixed levels)                         |
| Context      | Remote team across Indonesia, Brunei, and Malaysia                 |
| Builds On    | JUNIOR_DEVELOPER_SOP.md, TEAM_MANAGEMENT_PLAN.md                   |

---

## Table of Contents

1. [The Challenge](#1-the-challenge)
2. [Leadership Philosophy](#2-leadership-philosophy)
3. [Team Structure & Collaboration Model](#3-team-structure--collaboration-model)
4. [Daily Operations (Redesigned for 5 People)](#4-daily-operations-redesigned-for-5-people)
5. [Code Review — Breaking the Bottleneck](#5-code-review--breaking-the-bottleneck)
6. [Onboarding Plan for Mid/Senior New Hires — Anang & Fachri](#6-onboarding-plan-for-midsenior-new-hires--anang--fachri)
7. [Probation Evaluation Framework — Anang & Fachri (3 Months)](#7-probation-evaluation-framework--anang--fachri-3-months)
8. [Post-Probation Management — Leading Experienced Developers](#8-post-probation-management--leading-experienced-developers)
9. [Amirul's Growth Path (Month 4-6)](#9-amiruls-growth-path-month-4-6)
10. [Approaching Haziq — Building a Working Relationship from Zero](#10-approaching-haziq--building-a-working-relationship-from-zero)
11. [Delivery & Quality Framework](#11-delivery--quality-framework)
12. [The Human Side — Leading with Empathy](#12-the-human-side--leading-with-empathy)
13. [Risk Management](#13-risk-management)
14. [Pre-Launch Checklist](#14-pre-launch-checklist)
15. [Success Metrics](#15-success-metrics)

---

## 1. The Challenge

### The Situation

You are a **solo Tech Lead** (External Consultant — ST Datablu Sdn. Bhd.) managing a **distributed remote team of 4 developers** across 3 countries: Indonesia, Brunei, and Malaysia. This is not a uniform team — every member has a different experience level, history, and relationship with you.

| Member                    | Location          | Level              | Status                                         |
| ------------------------- | ----------------- | ------------------ | ---------------------------------------------- |
| **Amirul**                | Brunei            | Junior             | 3 months in. Proven. Great attitude.            |
| **Anang**                 | Blitar, Indonesia | Mid to Mid-Senior  | **NEW.** 3-month probation starts now.          |
| **Fachri**                | Mojokerto, Indonesia | Mid to Mid-Senior | **NEW.** 3-month probation starts now.         |
| **Haziq**                 | Malaysia          | Developer          | In team structure but **never worked together**. |

### Why This Is Hard

| Challenge                              | Why It Matters                                                                       |
| -------------------------------------- | ------------------------------------------------------------------------------------ |
| **Mixed experience levels**            | You cannot apply the same management approach to everyone                            |
| **2 new hires on probation**           | You must evaluate objectively while giving them a fair chance to succeed              |
| **1 team member you've never met**     | Haziq is under you on paper, but zero rapport exists. Authority must be earned.       |
| **Fully remote, 3 countries**          | No shoulder-tapping. Time zones vary. Cultural differences matter.                   |
| **Small startup, no safety net**       | No mid-management layer. No PM. No QA team. You are process, quality, and people.    |
| **You must still write code**          | 60% of your scope is development. You cannot spend all day in meetings and reviews.  |

### What This Playbook Solves

This document designs team operations for a **mixed-level distributed team** without:

- Becoming a bottleneck (every PR waiting for you)
- Burning out (context-switching between management and coding)
- Losing quality (more people = more places for inconsistency)
- Losing the human touch (efficiency should not kill empathy)
- Misjudging probation (clear indicators prevent bias)

The goal: **Lead effectively AND humanely.** Evaluate fairly, build trust, deliver quality, stay sane.

---

## 2. Leadership Philosophy

### The 7 Principles

These principles define how you lead. They are not optional — they are the foundation of every decision in this playbook.

| #   | Principle                                  | What It Means in Practice                                                             |
| --- | ------------------------------------------ | ------------------------------------------------------------------------------------- |
| 1   | **Structure creates freedom**              | Clear processes reduce confusion. People feel confident when they know what to do     |
| 2   | **Measure output, not hours online**       | Results matter. If someone finishes a task in 4 hours, don't make them sit until 5 PM |
| 3   | **Async-first, sync when it matters**      | Write it down by default. Meet only for demos, alignment, and unblocking              |
| 4   | **No one stays stuck alone**               | The 1-hour rule. Asking for help is rewarded, not punished                            |
| 5   | **Learn by doing, supported by mentoring** | Guided practice, not lectures. Let them struggle productively, then debrief           |
| 6   | **Every review is a teaching moment**      | Explain the "why," not just the "what." Build understanding, not dependency           |
| 7   | **Trust is given, then verified**          | Start from trust. Verify through output and demos. Never micromanage                  |

### The Mindset Shift: Managing Mixed Levels

With a uniform team (all junior), you could apply the same approach to everyone. A **mixed-level team** demands adapting your style per person:

```
  ┌─ AMIRUL (Junior, Proven) ──────────────────────────────────────┐
  │  Approach: COACHING                                             │
  │  You: Guide his growth, stretch his capabilities               │
  │  He needs: Technical mentoring, increasing responsibility       │
  │  He does NOT need: Hand-holding. He's earned autonomy.          │
  └────────────────────────────────────────────────────────────────┘

  ┌─ ANANG & FACHRI (Mid/Senior, New, Probation) ─────────────────┐
  │  Approach: DELEGATING + EVALUATING                              │
  │  You: Set clear expectations, observe output, measure fairly   │
  │  They need: Codebase orientation, process alignment, real tasks │
  │  They do NOT need: Junior-style tutoring. Respect their skill. │
  └────────────────────────────────────────────────────────────────┘

  ┌─ HAZIQ (Developer, Existing, Never Collaborated) ─────────────┐
  │  Approach: PARTNERING                                           │
  │  You: Build rapport first, establish mutual respect             │
  │  He needs: To see your competence, to feel heard and valued     │
  │  He does NOT need: Top-down mandates from a stranger.           │
  └────────────────────────────────────────────────────────────────┘
```

This means:

- **Differentiated management** replaces one-size-fits-all
- **Peer review** replaces "Lead reviews everything first"
- **Codebase partnerships** replace "Lead answers every question"
- **SOP + Documentation** replaces "Lead explains the same thing 4 times"
- **Automated quality gates** replace "Lead manually checks formatting"

You are building a **team machine**, not running a one-man support desk.

---

## 3. Team Structure & Collaboration Model

### Organization

```
                    ┌──────────────────────────────────┐
                    │           TECH LEAD               │
                    │        Arya Pratama               │
                    │        (Surabaya, Indonesia)      │
                    │                                   │
                    │  • Architecture decisions          │
                    │  • Final code review               │
                    │  • Sprint planning                 │
                    │  • Stakeholder communication       │
                    │  • Probation evaluation (Anang,    │
                    │    Fachri)                         │
                    │  • System design                   │
                    └───────────────┬──────────────────┘
                                    │
            ┌───────────┬───────────┼───────────┐
            │           │           │           │
     ┌──────▼──────┐ ┌──▼──────────┐ ┌──▼──────────┐ ┌──▼──────────┐
     │  AMIRUL     │ │  ANANG      │ │  FACHRI     │ │  HAZIQ      │
     │  Brunei     │ │  Blitar     │ │  Mojokerto  │ │  Malaysia   │
     │  Junior     │ │  Mid/Senior │ │  Mid/Senior │ │  Developer  │
     │             │ │  NEW        │ │  NEW        │ │  Existing   │
     │  3 months   │ │  PROBATION  │ │  PROBATION  │ │  Never      │
     │  in team.   │ │  (3 months) │ │  (3 months) │ │  worked     │
     │  Proven.    │ │             │ │             │ │  together.  │
     └─────────────┘ └─────────────┘ └─────────────┘ └─────────────┘
```

### Collaboration Model (Not a Traditional Buddy System)

A traditional buddy system pairs a senior with a junior for hand-holding. This team is different — it has **mixed levels with different needs**. The collaboration model adapts to each relationship:

| Relationship            | Model                  | What It Looks Like                                                    |
| ----------------------- | ---------------------- | --------------------------------------------------------------------- |
| Lead → Amirul           | **Coaching**           | Weekly mentoring, increasing task complexity, codebase guide role      |
| Lead → Anang / Fachri   | **Onboarding Partner** | Architecture walkthrough, process alignment, probation observation     |
| Lead → Haziq            | **Partnership**        | Rapport-building, shared tasks early on, earn-based authority          |
| Amirul → Anang / Fachri | **Codebase Guide**     | Amirul knows the project inside-out; they know advanced patterns. Mutual exchange. |
| Anang ↔ Fachri          | **Peer Support**       | Both new, both on probation. They can share experiences and help each other settle. |

### Why This Model Works

| Without This Model                         | With This Model                                                     |
| ------------------------------------------ | ------------------------------------------------------------------- |
| All 4 devs DM the Lead with every question | New devs ask Amirul for codebase context → Lead gets fewer interruptions |
| Lead reviews 4 PRs daily (bottleneck)      | Experienced devs (Anang, Fachri) do peer reviews → Lead does final review |
| New dev feels isolated in remote setup     | Anang & Fachri support each other; Amirul guides codebase navigation |
| Lead burns out from context-switching      | Lead focuses on architecture, planning, probation evaluation, and complex reviews |

### Amirul as Codebase Guide (Not a Buddy)

Amirul is junior in experience level, but he **knows this codebase**. Anang and Fachri are experienced developers, but they **don't know this project**. This creates a powerful mutual exchange:

| Amirul Teaches Them                          | They Teach Amirul                                    |
| -------------------------------------------- | ---------------------------------------------------- |
| Project architecture and file organization   | Advanced design patterns they've used before          |
| CI/CD pipeline and deploy process            | Code review techniques from their experience          |
| Existing conventions and SOP                 | Problem-solving approaches for complex features       |
| Where things are and why decisions were made | New perspectives on architecture and optimization     |

**How to frame this for Amirul:**

> "You know this project better than anyone on the team except me. Anang and Fachri are experienced developers, but they need YOUR help to understand our codebase. In return, you'll learn a lot from how they approach problems. This is a mutual exchange — you're each bringing something the other needs."

### Escalation Flow (Redesigned for Mixed Team)

```
  ┌─ QUESTION / BLOCKER ─────────────────────────────────────────┐
  │                                                               │
  │  Step 1: TRY YOURSELF (30 min max)                            │
  │  └─ Read the docs, check the SOP, search the codebase        │
  │     This applies to ALL levels. Self-sufficiency first.       │
  │                                                               │
  │  Step 2: ASK A TEAMMATE (before escalating to Lead)           │
  │  └─ Amirul: Codebase / architecture / "where is X?"          │
  │  └─ Anang / Fachri: Code patterns / technical approach        │
  │  └─ Haziq: If relevant to work he's been doing               │
  │                                                               │
  │  Step 3: ASK THE LEAD (Arya)                                  │
  │  └─ Architecture decisions                                    │
  │  └─ Business logic questions                                  │
  │  └─ Cross-system concerns                                     │
  │  └─ Anything teammates couldn't resolve                       │
  │                                                               │
  │  RULE: No one stays stuck for more than 1 hour.               │
  │  Asking for help is a STRENGTH, not a weakness.               │
  └───────────────────────────────────────────────────────────────┘
```

---

## 4. Daily Operations (Redesigned for 5 People)

### Async Standup (Before Live Call)

Every morning, each developer posts in Slack (via Slack Workflow Builder) answering 3 questions:

1. **What did I complete yesterday?** (link to PR or Google Sheets task)
2. **What am I working on today?** (specific task, not vague)
3. **Any blockers?** (be specific — what's blocking and what help is needed)

**Why async first:** Lead reads all 4 answers before the live call. Saves 10+ minutes of status reporting in the meeting. The live call focuses on **demos and discussion**, not updates.

### Live Standup (Daily, 45 min max)

| Segment                       | Time   | What Happens                                                            |
| ----------------------------- | ------ | ----------------------------------------------------------------------- |
| Quick sync (async was unclear) | 5 min  | Clarify anything from async posts. Address blockers immediately.        |
| Demo round                    | 32 min | Each dev demos their work (~8 min each). Screen share, explain code.    |
| Alignment                     | 8 min  | Lead shares priorities, answers team questions, any announcements.      |

**Demo round rules:**

- Show your screen. Walk through the code or feature.
- Explain WHAT you did and WHY you chose that approach.
- Team asks questions. Lead gives feedback.
- If nothing to demo (blocked, research day): Explain what you've learned / tried.

**Timer is enforced.** If a discussion goes deep, "take it offline" — schedule a 1-on-1 or a focused pairing session.

### Weekly Rhythm

| Day       | Activity                    | Duration | Who                        |
| --------- | --------------------------- | -------- | -------------------------- |
| Monday    | Sprint planning             | 45 min   | Full team                  |
| Mon-Thu   | Daily standup + demo        | 45 min   | Full team                  |
| Friday    | Weekly retro + wins round   | 20 min   | Full team                  |
| Biweekly  | 1-on-1 with Anang           | 20 min   | Lead + Anang               |
| Biweekly  | 1-on-1 with Fachri          | 20 min   | Lead + Fachri              |
| Biweekly  | 1-on-1 with Amirul          | 20 min   | Lead + Amirul              |
| Monthly   | 1-on-1 with Haziq           | 20 min   | Lead + Haziq               |

> **Note on Anang & Fachri:** During probation (first 3 months), 1-on-1s are **biweekly** to maintain close signal. After successful probation, shifts to monthly.

### Core Hours & Availability

Given 3 countries (Indonesia WIB, Brunei BN, Malaysia MYT — all UTC+8 or close):

- **Core overlap:** 09:00 - 17:00 (local time, mostly aligned)
- **Response SLA:** Reply to Slack messages within 2 hours during core hours
- **If blocked:** Communicate immediately. Do not wait for standup.

---

## 5. Code Review — Breaking the Bottleneck

### The Problem at 4 Developers

With 4 developers producing PRs, the Lead becomes a bottleneck if reviewing every PR end-to-end. A **two-stage review** system distributes the load while maintaining quality.

### Two-Stage Review Process

```
  Developer submits PR
        │
        ▼
  ┌─────────────────────────────────────────────────┐
  │  STAGE 1: PEER REVIEW (within 4 hours)          │
  │                                                  │
  │  Who reviews:                                    │
  │  • Anang or Fachri review each other's PRs       │
  │  • Amirul's PRs → reviewed by Anang or Fachri   │
  │  • Anang/Fachri's PRs → can also be reviewed    │
  │    by each other + Lead final review             │
  │                                                  │
  │  What they check:                                │
  │  ✓ Tests exist and make sense                    │
  │  ✓ Code follows project conventions              │
  │  ✓ Architecture layers respected                 │
  │  ✓ Readability and naming                        │
  │  ✓ SOP compliance                                │
  └────────────────────┬────────────────────────────┘
                       │
                       ▼
  ┌─────────────────────────────────────────────────┐
  │  STAGE 2: LEAD REVIEW (within 24 hours)         │
  │                                                  │
  │  What Lead checks:                               │
  │  ✓ Architecture alignment                        │
  │  ✓ Business logic correctness                    │
  │  ✓ Edge cases and error handling                 │
  │  ✓ Security considerations                       │
  │  ✓ Performance implications                      │
  │  ✓ At least 1 teaching/knowledge-sharing comment │
  └────────────────────┬────────────────────────────┘
                       │
                       ▼
                 ✅ Merge to develop
```

### Review Assignment Matrix

| PR Author | Peer Reviewer (Stage 1)           | Lead Review (Stage 2) |
| --------- | --------------------------------- | --------------------- |
| Amirul    | Anang or Fachri                   | Always                |
| Anang     | Fachri (or reverse)               | Always during probation, then spot-check |
| Fachri    | Anang (or reverse)                | Always during probation, then spot-check |
| Haziq     | Anang or Fachri                   | Always initially, then spot-check |

### Post-Probation Trust Escalation

After Anang and Fachri pass their 3-month probation (and demonstrate consistent code quality):

- **P3 tasks (low-risk improvements):** Peer review only. Lead spot-checks weekly.
- **P2 tasks (standard features):** Peer review + Lead review.
- **P1 tasks (critical/complex):** Always full Lead review.

This gives them **earned autonomy** — they prove quality, they get more trust.

---

## 6. Onboarding Plan for Mid/Senior New Hires — Anang & Fachri

### Why This Is Different from Junior Onboarding

Anang and Fachri are **experienced developers**. They know how to code, use Git, and write tests. What they do NOT know is:

- This specific codebase, its architecture, and its conventions
- The team's processes (SOP, CI/CD, review workflow, task management)
- The project's business domain and requirements
- How this team communicates and collaborates

The onboarding is about **orientation and integration**, not teaching fundamentals.

### Timeline Overview

```
  ┌─ Week 1: SETUP & CODEBASE DEEP DIVE ──────────────────────┐
  │  Focus: Environment, architecture, team introduction        │
  │  Guide: Amirul (codebase walkthrough) + Lead (architecture) │
  │  Task: Explore codebase. Read architecture docs. Run tests. │
  │  Output: Can explain project structure on a whiteboard.     │
  └────────────────────────┬───────────────────────────────────┘
                           │
  ┌─ Week 2: FIRST REAL TASK ─────────────────────────────────┐
  │  Focus: Deliver a meaningful feature (mid-level scope)      │
  │  Context: This is both onboarding AND the first probation   │
  │           signal. Give a real task, not a toy exercise.      │
  │  Support: Amirul available for codebase questions            │
  │  Output: PR submitted, reviewed, merged.                    │
  └────────────────────────┬───────────────────────────────────┘
                           │
  ┌─ Week 3-4: FULL VELOCITY ────────────────────────────────┐
  │  Focus: Complete tasks at near-normal pace                  │
  │  Expectation: Following team process independently          │
  │  Support: Minimal — they should be self-sufficient          │
  │  Output: 2-3 features completed. Process integrated.        │
  └────────────────────────┬───────────────────────────────────┘
                           │
  ┌─ Month 2-3: FULLY INTEGRATED ────────────────────────────┐
  │  Focus: Contributing at full capacity                       │
  │  Expectation: Peer reviewing, architecture input, velocity  │
  │  Support: Normal team interaction                           │
  │  Output: Probation evaluation data is accumulating.         │
  └────────────────────────────────────────────────────────────┘
```

### Week 1: Setup & Codebase Deep Dive

**Day 1:**

- Welcome call with Lead (30 min): Introduce team, explain how we work, set expectations, explain probation timeline transparently
- Amirul introduction on Slack (#team-dev): "This is Anang/Fachri, our new team member"
- Access setup: GitHub, Slack channels, Google Sheets, Portainer (viewer)

**Day 2-3:**

- Environment setup (they should handle this mostly independently — they're experienced):
  - [ ] Docker & Docker Compose running
  - [ ] Ruby version matching project
  - [ ] Project cloned and running locally
  - [ ] `rails test` passes
  - [ ] `rubocop` runs clean
- **Architecture walkthrough with Amirul** (60 min screen share):
  - Project structure, service objects, query objects, policies
  - CI/CD pipeline overview (GitHub Actions → Docker → Portainer)
  - Database schema key tables and relationships
  - "Where does X go?" — the architecture decision patterns
- Read: Architecture documentation in `docs/architecture/`

**Day 4-5:**

- Read: JUNIOR_DEVELOPER_SOP.md (not because they're junior — because it documents team conventions)
- Read: TEAM_MANAGEMENT_PLAN.md Sections 1-5 (team overview, communication, workflow)
- Explore the codebase independently: Read controllers, models, services, tests
- Join daily standup — participate from Day 1 (they have the experience to contribute immediately)

**End of Week 1 Checkpoint (Lead):**

- [ ] Environment 100% operational
- [ ] Can explain project architecture at a high level
- [ ] Understands CI/CD pipeline and deployment flow
- [ ] Joined standup, communicated clearly
- [ ] No red flags in communication or attitude

### Week 2: First Real Task

Assign a **meaningful feature** — not a trivial P3 validation fix. Something that requires:

- Understanding multiple layers of the codebase
- Writing proper tests
- Following team conventions
- A PR with thoughtful implementation

**Good first tasks for mid/senior devs:**

- Implement a new service object with business logic + tests
- Build an API endpoint end-to-end (controller, service, tests)
- Refactor an existing feature with improved architecture
- Add a new report/dashboard feature with query optimization

**What you observe (probation signal):**

- How they approach the task (jump in blindly or ask good questions first?)
- Quality of questions asked (relevant, well-researched, or lazy?)
- Code quality of the first PR (patterns, tests, readability)
- Response to code review feedback (defensive or receptive?)

### Week 3-4: Full Velocity

- Assign tasks at normal mid-level complexity
- They should follow the full process independently: Google Sheets updates, PR conventions, test coverage
- Start assigning them as peer reviewers (review Amirul's PRs, review each other's PRs)
- By end of Week 4, expect them to be operating at ~80% of their eventual velocity

### Month 2-3: Fully Integrated

- Full velocity expected
- Contributing to peer reviews consistently
- Participating in architecture discussions when relevant
- Any process gaps should have been addressed long ago
- Probation data accumulates through daily observation, weekly scorecard, monthly checkpoints

---

## 7. Probation Evaluation Framework — Anang & Fachri (3 Months)

### Purpose

The 3-month probation exists to answer a single question:

> **Should this person continue on the team?**

This framework ensures the answer is **objective, fair, and well-documented** — never a gut feeling.

### The 7 Probation Indicators

Each indicator is scored on a **5-point scale** during monthly evaluations:

| Score | Meaning           |
| ----- | ----------------- |
| 1     | Unacceptable      |
| 2     | Below expectation |
| 3     | Meets expectation |
| 4     | Above expectation |
| 5     | Exceptional        |

#### Indicator 1: Delivery on Time

> Does this person complete assigned tasks within the estimated timeframe?

| Score | Behavior                                                                     |
| ----- | ---------------------------------------------------------------------------- |
| 1     | Consistently misses deadlines without communication                          |
| 2     | Frequently late, sometimes with advance notice                               |
| 3     | Generally on time; communicates delays early when they happen                |
| 4     | Consistently on time; proactively adjusts scope when risks emerge            |
| 5     | Delivers ahead of schedule; identifies and resolves risks before they cause delay |

#### Indicator 2: Responsiveness

> How quickly do they respond to messages, attend meetings, and communicate blockers?

| Score | Behavior                                                                     |
| ----- | ---------------------------------------------------------------------------- |
| 1     | Frequently unresponsive; misses standups without notice                      |
| 2     | Slow to respond (>4 hours); occasionally misses meetings                     |
| 3     | Responds within 2 hours during core hours; attends all scheduled meetings    |
| 4     | Responds quickly; proactively communicates status without being asked        |
| 5     | Highly responsive; communicates blockers and status in real-time              |

#### Indicator 3: Code Quality

> Does their code follow architecture, include proper tests, and pass review with minimal feedback?

| Score | Behavior                                                                     |
| ----- | ---------------------------------------------------------------------------- |
| 1     | Code frequently breaks conventions; no tests; many review rounds needed      |
| 2     | Inconsistent quality; tests missing for edge cases; repeated review feedback |
| 3     | Follows conventions; tests included; 1-2 rounds of review feedback typical   |
| 4     | Clean code; comprehensive tests; review feedback is minor/nit                |
| 5     | Exemplary code; reviewers learn from their PRs; sets quality bar higher      |

#### Indicator 4: Communication

> Are standup updates clear? Do they document decisions? Do they escalate effectively?

| Score | Behavior                                                                     |
| ----- | ---------------------------------------------------------------------------- |
| 1     | Vague updates; doesn't document; teammates confused about their work         |
| 2     | Inconsistent clarity; sometimes forgets to update Google Sheets status        |
| 3     | Clear standup updates; documents work; uses proper channels                  |
| 4     | Proactive communication; thorough documentation; clear PR descriptions       |
| 5     | Excellent written communication; creates knowledge for others; improves team docs |

#### Indicator 5: Teamwork

> Do they participate in discussions, help teammates, and behave respectfully in reviews?

| Score | Behavior                                                                     |
| ----- | ---------------------------------------------------------------------------- |
| 1     | Works in silo; dismissive of others; no participation in team discussions    |
| 2     | Minimal interaction; does only what's assigned; passive in discussions        |
| 3     | Participates when asked; helpful when teammates reach out; respectful        |
| 4     | Actively participates; offers help proactively; constructive review feedback |
| 5     | Team multiplier; makes others better; drives positive team culture            |

#### Indicator 6: Initiative

> Do they proactively identify improvements, suggest solutions, and look beyond their assigned tasks?

| Score | Behavior                                                                     |
| ----- | ---------------------------------------------------------------------------- |
| 1     | Waits to be told everything; zero proactive behavior                         |
| 2     | Occasionally suggests something; mostly passive                               |
| 3     | Identifies issues and raises them; suggests solutions when asked             |
| 4     | Proactively proposes improvements; takes ownership of problems they find     |
| 5     | Drives innovation; identifies opportunities before anyone else; initiates change |

#### Indicator 7: Adaptability

> How well do they adapt to the team's processes, integrate feedback, and handle change?

| Score | Behavior                                                                     |
| ----- | ---------------------------------------------------------------------------- |
| 1     | Resists process adoption; defensive about feedback; unwilling to change       |
| 2     | Slow to adapt; needs repeated reminders about process; takes feedback personally |
| 3     | Follows process after initial guidance; receives feedback constructively      |
| 4     | Adapts quickly; applies feedback immediately; suggests process improvements  |
| 5     | Thrives in ambiguity; turns constraints into improvements; models adaptability |

### Monthly Scorecard Template

Copy this template and fill it monthly for each probation member:

```
  ┌─────────────────────────────────────────────────────────────────┐
  │  PROBATION SCORECARD                                            │
  │                                                                 │
  │  Name: _______________    Month: ☐ 1  ☐ 2  ☐ 3                │
  │  Evaluator: Arya Pratama                                        │
  │  Date: _______________                                          │
  │                                                                 │
  │  ┌─────────────────────────┬───────┬──────────────────────────┐ │
  │  │ Indicator               │ Score │ Evidence / Notes          │ │
  │  ├─────────────────────────┼───────┼──────────────────────────┤ │
  │  │ 1. Delivery on Time     │  /5   │                          │ │
  │  │ 2. Responsiveness       │  /5   │                          │ │
  │  │ 3. Code Quality         │  /5   │                          │ │
  │  │ 4. Communication        │  /5   │                          │ │
  │  │ 5. Teamwork             │  /5   │                          │ │
  │  │ 6. Initiative           │  /5   │                          │ │
  │  │ 7. Adaptability         │  /5   │                          │ │
  │  ├─────────────────────────┼───────┼──────────────────────────┤ │
  │  │ TOTAL                   │  /35  │                          │ │
  │  │ AVERAGE                 │  /5   │                          │ │
  │  └─────────────────────────┴───────┴──────────────────────────┘ │
  │                                                                 │
  │  Strengths observed:                                            │
  │  _______________________________________________________________│
  │                                                                 │
  │  Areas for improvement:                                         │
  │  _______________________________________________________________│
  │                                                                 │
  │  Action items for next month:                                   │
  │  _______________________________________________________________│
  │                                                                 │
  │  Overall assessment: ☐ On Track  ☐ Needs Attention  ☐ At Risk  │
  └─────────────────────────────────────────────────────────────────┘
```

### Monthly Checkpoint Meetings

#### Month 1 Checkpoint: "How Are You Settling In?"

**Purpose:** Check integration, gather initial signals, set expectations clearly.

**Agenda:**

1. "How has the first month been? What surprised you? What confused you?"
2. Share your preliminary observations (strengths first, then areas to watch)
3. Confirm they understand the probation indicators: "Here's exactly how I'll evaluate you"
4. Ask: "Is there anything about our process or codebase that's frustrating you?"
5. Set Month 2 focus area if needed

**Result:** They should leave knowing exactly where they stand and what's expected.

#### Month 2 Checkpoint: "Here's Where You Are"

**Purpose:** Mid-probation calibration. No surprises at Month 3.

**Agenda:**

1. Share the Month 1 and Month 2 scorecards side by side
2. Highlight strengths: "These are going really well..."
3. Address gaps directly: "I need to see improvement in X and Y. Here's what good looks like..."
4. Ask for their self-assessment: "How do you think you're doing?"
5. Clarify: "If this trajectory continues, here's where Month 3 evaluation lands"

**Result:** If they are at risk of failing probation, they KNOW by Month 2. No one should be surprised at the final decision.

#### Month 3 Checkpoint: "The Decision"

**Purpose:** Formal probation evaluation. Clear outcome.

**Agenda:**

1. Present the 3-month scorecard summary (all 3 months side by side)
2. Discuss trajectory: improving, stable, or declining?
3. Announce the decision: Pass / Extend (1 month) / Fail

### Pass/Fail Criteria

| Decision                 | Criteria                                                                     |
| ------------------------ | ---------------------------------------------------------------------------- |
| **Pass**                 | No indicator below 3 in Month 3. Overall average ≥ 3.5. Positive trajectory. |
| **Extend (1 month)**     | 1-2 indicators at 2 in Month 3 BUT showing improvement. Overall average ≥ 3.0. |
| **Fail**                 | Any indicator at 1 in Month 3. Overall average < 3.0. Negative trajectory.   |

### Red Flags to Watch (Act Immediately, Don't Wait for Checkpoint)

| Red Flag                                           | Immediate Action                                              |
| -------------------------------------------------- | ------------------------------------------------------------- |
| Consistently missing deadlines without communication | Private conversation: "I noticed X. What's going on?"         |
| Defensive or dismissive when receiving code review  | 1-on-1: "Feedback is how we grow here. Let's talk about this." |
| Not following team process despite reminders        | Clear written expectation: "This is required, not optional."  |
| Silo mentality (refuses to collaborate)             | Frame collaboration as a core team value: "We succeed together." |
| Disrespect toward Amirul or any teammate            | Zero tolerance. Address same day. Document.                   |
| Misrepresenting work status (says done, it isn't)   | Document evidence. Address in 1-on-1 with specific examples.  |

---

## 8. Post-Probation Management — Leading Experienced Developers

### The Shift After Probation Passes

Once Anang and Fachri pass their 3-month probation, the management approach shifts fundamentally:

```
  DURING PROBATION                       AFTER PROBATION
  ┌────────────────────┐                 ┌─────────────────────────┐
  │ Evaluate            │       →        │ Empower                  │
  │ Observe closely     │       →        │ Trust through outcomes   │
  │ Assign tasks        │       →        │ Delegate ownership       │
  │ Review everything   │       →        │ Spot-check + peer review │
  │ Biweekly 1-on-1     │       →        │ Monthly 1-on-1           │
  └────────────────────┘                 └─────────────────────────┘
```

### Principle: Trust First, Verify Through Outcomes

Mid/senior developers thrive on **autonomy** and **ownership**. Post-probation management is about:

1. **Give them features, not tasks.** Instead of "add a column to this table," give them "build the inventory reporting module." Let them decide the approach.
2. **Code review shifts to architectural alignment.** They know how to code. Your review focus is: "Does this fit our architecture? Does this align with our patterns?"
3. **1-on-1 focus shifts.** Not "are you okay?" but "What would you improve about our system/process?"
4. **Leverage their experience.** Invite them to architecture decisions. Ask for their input on team process improvements. They bring outside perspectives that improve the team.

### Adapting Management Style Per Person

Every human is different. The Situational Leadership model helps you adapt:

| Their State                              | Your Approach         | What It Looks Like                                          |
| ---------------------------------------- | --------------------- | ----------------------------------------------------------- |
| **High skill, high motivation**          | **Delegate**          | Set goals, get out of the way. Check results, not process.  |
| **High skill, variable motivation**      | **Support**           | Listen. Understand what motivates them. Remove blockers.     |
| **Moderate skill, high motivation**      | **Coach**             | Guide. Give feedback. Stretch assignments.                   |
| **Lower skill, high motivation**         | **Direct**            | Clear instructions. Close follow-up. More pair sessions.     |

- Anang might be "high skill, needs support" — your job: remove friction and give interesting work
- Fachri might be "high skill, high motivation" — your job: delegate and trust
- They might swap categories over time — **re-assess monthly**

### Career Growth Conversations

Post-probation, 1-on-1s should include career growth:

| Question                                                       | Why It Matters                                               |
| -------------------------------------------------------------- | ------------------------------------------------------------ |
| "What do you want to learn or build in the next 6 months?"     | Shows you care about their growth, not just their output     |
| "If you could change one thing about how we work, what is it?" | Gets process improvement ideas + signals potential frustration |
| "What work do you find most engaging? Least engaging?"         | Helps you assign tasks that match their motivation            |
| "Where do you see your career heading?"                        | Aligns their ambition with team opportunities                 |

---

## 9. Amirul's Growth Path (Month 4-6)

### Where Amirul Is Now (Month 3)

Based on 3 months of mentoring, Amirul has demonstrated:

**Strengths (proven):**

- **Attitude:** Fast response, initiative, great communication, hard-working
- **Reliability:** Can implement features end-to-end using project architecture
- **Process:** Follows Git workflow and SOP consistently
- **Independence:** Independently handled Intent Harvest when Lead was away
- **Character:** Great attitude — the kind of person you build a team around

**Growth area:**

- **Technical depth:** Needs improvement in advanced patterns, optimization, complex architecture decisions
- **But:** Hardskill is easy to change when the attitude is right. Amirul has the right attitude.

### The Next 3 Months: From Autonomy to Ownership

With Anang and Fachri joining, Amirul's growth path is enhanced — he learns FROM them while teaching them the codebase.

```
  ┌─ Month 4: CODEBASE GUIDE + SKILL ABSORPTION ─────────────────┐
  │                                                                │
  │  Core work:                                                    │
  │  • Takes on medium-complexity features                         │
  │  • Technical Analysis with minimal Lead revision               │
  │  • Estimation accuracy reaching 80-120%                        │
  │                                                                │
  │  Codebase guide role:                                          │
  │  • Walks Anang & Fachri through architecture when asked        │
  │  • Answers "where is X?" and "why was this designed this way?" │
  │  • Pair sessions for codebase-specific context (30 min/week)   │
  │                                                                │
  │  Growth from new teammates:                                    │
  │  • Learns advanced patterns by reviewing their PRs             │
  │  • Absorbs new approaches from their code review feedback      │
  │  • Sees different problem-solving styles up close              │
  │                                                                │
  │  Lead's role:                                                  │
  │  • Spot-check TAs (not review all)                             │
  │  • Final PR review (lighter)                                   │
  │  • Weekly 15 min check: "What are you learning from the team?" │
  └────────────────────┬──────────────────────────────────────────┘
                       │
  ┌─ Month 5: OWNERSHIP + TECHNICAL GROWTH ───────────────────────┐
  │                                                                │
  │  Core work:                                                    │
  │  • Owns features end-to-end (analysis → deploy)               │
  │  • Proposes technical approaches, not just receives            │
  │  • Writes documentation for features implemented              │
  │                                                                │
  │  Technical growth acceleration:                                │
  │  • Lead assigns one "stretch" task per sprint (slightly above  │
  │    current level — forces growth without overwhelming)         │
  │  • Anang or Fachri pair with Amirul on complex patterns       │
  │  • Amirul starts giving constructive code reviews (not just ✅)│
  │                                                                │
  │  Lead's role:                                                  │
  │  • Architecture guidance only (not hand-holding)               │
  │  • Reviews Amirul's code review comments for quality           │
  │  • Monthly 1-on-1 focused on career growth                    │
  └────────────────────┬──────────────────────────────────────────┘
                       │
  ┌─ Month 6: RELIABLE INDEPENDENT CONTRIBUTOR ───────────────────┐
  │                                                                │
  │  Checkpoints:                                                  │
  │  ☐ Breaks down complex features independently                  │
  │  ☐ Estimation accuracy consistently 80-120%                    │
  │  ☐ Code quality requires minimal review feedback               │
  │  ☐ Proactively identifies edge cases and risks                 │
  │  ☐ Has documented at least 2 features in docs/                │
  │  ☐ Technical skills visibly improved (compare to Month 3)     │
  │  ☐ Can be trusted with P2 tasks unsupervised                  │
  │                                                                │
  │  If all checkpoints met:                                       │
  │  → Amirul is on the path to mid-level                         │
  │  → Can approve + merge P3 PRs independently                   │
  │  → Can onboard future new team members                        │
  └────────────────────────────────────────────────────────────────┘
```

### Framing Amirul's Role with New Teammates

This is critical. Amirul must see the arrival of Anang and Fachri as an **opportunity**, not a threat:

| Wrong Framing                                        | Right Framing                                                         |
| ---------------------------------------------------- | --------------------------------------------------------------------- |
| "They're senior so you need to learn from them"      | "You each bring something the other doesn't. You know our codebase — they bring experience. Learn from each other." |
| "Help me because I'm too busy"                       | "I trust you enough to be the team's codebase expert"                 |
| "They might replace you"                             | "The team is growing BECAUSE of your good work. We need more people like you." |
| "Review their code since they don't know the project" | "You'll see code from experienced devs up close — learn their patterns while teaching them ours" |

---

## 10. Approaching Haziq — Building a Working Relationship from Zero

### The Context

Haziq is already in the team structure under Arya, but they have **never worked together**. There is no existing rapport, no shared history, no trust built through collaboration. The organizational chart says "reports to Arya" — but authority on paper means nothing without relationship.

### The Principle

> **Authority comes from competence and care, not from org charts. Haziq will follow your lead because you EARN it, not because the structure says so.**

### Phase 1: Build Rapport First, Work Second (Week 1-2)

The first interaction must NOT be a task assignment. It must be a human connection.

**The First 1-on-1 (Week 1, 30-45 min):**

This is NOT a performance review. This is a "getting to know you" conversation.

| Do                                                    | Don't                                                        |
| ----------------------------------------------------- | ------------------------------------------------------------ |
| "I want to understand how you like to work"           | Start with process changes or new rules                      |
| "What are you currently working on? Tell me about it" | "Here's how things are going to change"                      |
| "What do you enjoy most about your work here?"        | Jump into task assignments                                   |
| "What frustrates you about working remotely?"         | Immediately impose your standup/review process               |
| Share YOUR working style openly — be transparent      | Act like you know everything about the team already          |
| Ask about HIS preferences (async? calls? communication style?) | Assume your preferences are the default                |
| "I'm new to this leadership role with you. I want to make this work well for both of us." | Assert authority: "I'm your new lead, here's how it works" |

**Goals for Week 1-2:**

- [ ] Haziq feels HEARD, not managed
- [ ] You understand his current work, strengths, and preferences
- [ ] He knows your working style and communication preferences
- [ ] There is a casual, friendly tone established
- [ ] Zero process changes imposed yet

### Phase 2: Collaborate, Don't Manage (Week 3-4)

After rapport is established, the next step is **shared work**. This serves two purposes: Haziq sees your technical competence firsthand, and you both build trust through doing.

**Actions:**

1. **Assign a shared task** where you work TOGETHER — pair programming or co-designing a feature
   - This is not about checking his work. It's about showing him how you think and vice versa.
   - Choose something interesting, not grunt work.

2. **Ask for his input on team process:**
   - "You've been here longer than me in some ways. What works? What doesn't?"
   - "I'm thinking about introducing X process. What do you think?"
   - Genuinely consider his feedback. If he suggests something good, adopt it and credit him.

3. **Show technical competence:**
   - Solve a hard problem together. Let him see your code, your thinking.
   - Don't show off — just be competent. Respect is earned by being good at what you do.

**Goals for Week 3-4:**

- [ ] At least one shared task completed together
- [ ] He has seen your technical abilities firsthand
- [ ] He has been asked for — and given — input on team process
- [ ] Relationship feels collaborative, not hierarchical

### Phase 3: Establish Rhythm (Month 2+)

Gradually introduce team processes — but frame them as **team alignment**, not "my rules":

1. **Invite, don't mandate:** "We have a daily standup at 9 AM. The team finds it helpful — would you like to join?"
2. **Adapt to him where possible:** If he prefers async communication, accommodate it. Don't force sync for the sake of uniformity.
3. **Give meaningful work:** Assign tasks that leverage his strengths. Make him feel valued and challenged.
4. **Regular 1-on-1 (monthly):** Keep the human connection. Ask about his goals, not just deliverables.
5. **Include him in decisions:** "We're deciding on X approach. I'd value your perspective since you've been working on related features."

### If Things Don't Improve

If after 2 months of genuine effort, Haziq remains disengaged or resistant:

1. **Direct conversation:** "I've noticed X. I want us to work well together. What can I do differently?"
2. **Document observations.** Not for a report — for your own clarity.
3. **Escalate to boss** only after exhausting direct approaches. Frame it as "I want to make this work — here's what I've tried, and here's where I need help."

### The Measure of Success

You will know the Haziq approach is working when:

- He responds to your messages promptly and warmly (not just politely)
- He shares problems proactively, trusting you to help rather than judge
- He gives honest input in discussions (not just agreeing to avoid conflict)
- He considers himself part of this team, not just "someone under Arya"

---

## 11. Delivery & Quality Framework

### Sprint Planning (Monday, 45 min)

#### Capacity Calculation

```
  Team capacity per week (realistic):

  Mixed team × 5 days = 20 person-days (theoretical)

  Minus:
  - Daily standup: 0.75 hr/day × 5 = 3.75 hrs = ~0.5 day per person
  - Code reviews (doing + receiving): ~0.5 day per person
  - Process overhead (Sheets, docs, communication): ~0.25 day per person

  Realistic capacity:
  - Amirul (Junior, 3 months in): ~3.5 productive days/week
  - Anang (Mid/Senior, Month 1): ~3.5 productive days/week (process learning curve)
  - Anang (Mid/Senior, Month 2+): ~4 productive days/week
  - Fachri (Mid/Senior, Month 1): ~3.5 productive days/week (process learning curve)
  - Fachri (Mid/Senior, Month 2+): ~4 productive days/week
  - Haziq: ~4 productive days/week (once integrated)

  Total team capacity (Month 1): ~14.5 productive days/sprint
  Total team capacity (Month 3+): ~15.5 productive days/sprint

  Rule: NEVER plan more than 80% of capacity.
  Usable: ~12 days/sprint (Month 1) → ~12.5 days/sprint (Month 3+)
```

#### Task Assignment Strategy

| Developer                       | Task Types                                    | Max Task Size |
| ------------------------------- | --------------------------------------------- | ------------- |
| Amirul (Junior, Month 4)       | P2-P3 tasks, medium complexity                | 3 days        |
| Anang (Mid/Senior, probation)  | P1-P2 tasks, meaningful features              | 3-5 days      |
| Fachri (Mid/Senior, probation) | P1-P2 tasks, meaningful features              | 3-5 days      |
| Haziq (Developer)              | Based on strengths identified in Phase 2      | 3-5 days      |
| Amirul (Month 5-6)             | P1-P2 tasks, own end-to-end                   | 5 days (broken into subtasks) |

#### The "Primary + Backup" Rule

Each dev gets:

- **1 primary task** — the main thing they're working on
- **1 backup task** — a smaller task to switch to if they're blocked on primary

This prevents the "I'm blocked on X so I'm doing nothing" problem.

### Quality Defense (6 Layers)

```
  ┌─────────────────────────────────────────────────────────────┐
  │              6-LAYER QUALITY DEFENSE                          │
  │                                                              │
  │  Layer 1: SOP & DOCUMENTATION                                │
  │  └─ Developer knows WHAT to do and WHERE code goes           │
  │     Before writing a single line of code                     │
  │                                                              │
  │  Layer 2: GIT HOOKS (Automated — on every commit)            │
  │  └─ Auto-format code (RuboCop)                               │
  │     Block commits with violations                            │
  │     Run tests before push                                    │
  │                                                              │
  │  Layer 3: CI PIPELINE (Automated — on every PR)              │
  │  └─ RuboCop, Brakeman, Bundler Audit, Rails Tests            │
  │     Impossible to merge if any check fails                   │
  │                                                              │
  │  Layer 4: PEER REVIEW (within 4 hours)                       │
  │  └─ SOP compliance, tests, architecture layer, readability   │
  │     Mid/senior devs review each other for deeper feedback    │
  │                                                              │
  │  Layer 5: LEAD REVIEW (Final — within 24 hours)              │
  │  └─ Architecture, business logic, edge cases, security       │
  │     Every review includes at least 1 knowledge-sharing note  │
  │                                                              │
  │  Layer 6: DAILY DEMO (Live — 8 min per person)               │
  │  └─ Developer explains code to the team                      │
  │     Team catches issues, shares knowledge                    │
  │     Builds confidence and communication skills               │
  └─────────────────────────────────────────────────────────────┘
```

### Definition of Done (Updated)

A task is "Done" when ALL of the following are true:

- [ ] Technical Analysis was approved before coding (Amirul: always; Anang/Fachri: complex features only post-probation)
- [ ] Code follows SOP and architecture rules
- [ ] Tests exist and pass (CI green)
- [ ] RuboCop clean (no new violations)
- [ ] Peer reviewed ✅
- [ ] Lead reviewed and approved ✅ (or peer-only for approved P3 post-probation)
- [ ] Manually tested
- [ ] Code merged to `develop`
- [ ] Google Sheets status → "Done"
- [ ] Actual days logged

---

## 12. The Human Side — Leading with Empathy

### This Is Not a Management Manual. This Is a People Playbook.

Remote developers across 3 countries face real human challenges:

- Isolation (working alone all day, different timezone from some teammates)
- Uncertainty about new roles and relationships (especially Anang, Fachri, Haziq)
- Cultural differences between Indonesian, Bruneian, and Malaysian work styles
- Fear of judgment during probation (Anang, Fachri)
- The pressure of remote collaboration without in-person rapport

A good Tech Lead addresses these actively, not accidentally.

### 12.1 The 1-on-1 — Your Most Important Meeting

The 1-on-1 is NOT a status update. It is not about tasks. It is about **the person.**

#### Questions That Build Trust

| Category      | Questions                                                                |
| ------------- | ------------------------------------------------------------------------ |
| **Wellbeing** | "How are you doing? Not work — how are YOU doing?"                       |
| **Energy**    | "Are you feeling overwhelmed, balanced, or bored? Be honest."            |
| **Growth**    | "What's one new thing you learned this week that you're proud of?"       |
| **Blockers**  | "Is there anything making your work harder that I don't know about?"     |
| **Process**   | "Is anything about our process frustrating or unclear?"                  |
| **Safety**    | "Do you feel comfortable raising concerns with the team?"                |
| **Ambition**  | "Where do you want to be in 6 months? What skills do you want to build?" |

#### 1-on-1 Approach Per Person

| Person  | Focus                                                                  | Frequency            |
| ------- | ---------------------------------------------------------------------- | -------------------- |
| Amirul  | Career growth, technical stretch, how codebase guide role is going     | Biweekly             |
| Anang   | Integration, probation feedback, what support they need                | Biweekly (probation) |
| Fachri  | Integration, probation feedback, what support they need                | Biweekly (probation) |
| Haziq   | Relationship building, his goals, his input on team direction          | Monthly              |

#### Rules for 1-on-1:

- **They talk more than you.** If you're talking 70% of the time, you're doing it wrong.
- **No surprises.** Never deliver critical feedback for the first time in a 1-on-1. Address issues as they happen; use 1-on-1 for patterns and growth.
- **Follow through.** If they mention a blocker, resolve it. Nothing kills trust faster than "I told my lead and nothing changed."
- **Private and safe.** What's said in 1-on-1 stays in 1-on-1. Never use it against them.

### 12.2 Feedback Framework — SBI (Situation, Behavior, Impact)

When giving feedback — positive or corrective — use this structure:

#### Positive Example:

> **Situation:** "In yesterday's standup, when you demo'd the withdrawal feature..."
> **Behavior:** "...you explained the edge case handling really clearly, including what you considered and rejected."
> **Impact:** "That helped the whole team understand the approach. It showed real growth in your technical communication."

#### Corrective Example:

> **Situation:** "I noticed the PR for the order status feature..."
> **Behavior:** "...didn't include tests for the failure path — only the happy path was tested."
> **Impact:** "That means we can't be confident the error handling works. When we catch it in CI, it takes longer to fix than if it was written upfront."
> **Follow-up:** "Let's do a 15-minute pair session on writing failure path tests. I'll show you the pattern, and then you can apply it."

**Key rules:**

- **Never personal.** "The code doesn't have tests" NOT "you don't write tests"
- **Timely.** Give feedback the same day, not 2 weeks later
- **Balanced.** Aim for at least 3 positive feedback moments for every 1 corrective
- **Actionable.** Every corrective feedback ends with a clear next step or offer to help

**Note for probation feedback:** Same rules apply. Probation does NOT mean harsher feedback — it means more frequent feedback so course correction happens early.

### 12.3 Celebrating Wins

Remote teams miss the organic "good job" moments of an office. You have to create them deliberately.

#### In Daily Standup:

- When someone demos a clean solution: "That's really well-structured. Nice work."
- When someone catches their own bug during demo: "Good catch. That's exactly why we demo."

#### In Friday Retro — "Wins of the Week" Round:

- Each person shares one thing they're proud of this week
- Lead adds wins that people forgot or were too humble to mention
- Takes 5 minutes. Impact on team morale: enormous.

#### In Slack:

- `#til-learning` channel — encourage sharing what they learned
- React to posts with genuine feedback, not just emoji
- Occasionally highlight good PRs or TAs in `#team-dev`

### 12.4 Safe-to-Fail Environment

Create explicit psychological safety for ALL levels — not just juniors:

| What You Say                                                       | What They Hear                                     |
| ------------------------------------------------------------------ | -------------------------------------------------- |
| "There's no dumb question. I'd rather you ask than waste 3 hours." | "It's safe to not know things."                    |
| "That's a good mistake — it's how we learn the codebase faster."   | "Mistakes are expected, not punished."             |
| "The CI caught it — that's exactly what it's there for."           | "The system protects me. I can try things."        |
| "What would you do differently next time?"                         | "This is a learning conversation, not punishment." |
| "I've broken things before too. Here's what helped me..."          | "Even the Lead isn't perfect. We're all human."    |

**For Anang & Fachri specifically:** Probation can make people afraid to take risks. Explicitly tell them: "I evaluate your judgment, not your error count. Taking smart risks and learning from them is exactly what I want to see."

### 12.5 Protecting Against Burnout

| Signal                                         | Action                                                             |
| ---------------------------------------------- | ------------------------------------------------------------------ |
| Standup updates getting shorter and vaguer     | 1-on-1: "How's your energy? Are the tasks the right difficulty?"   |
| Working outside core hours consistently        | Private DM: "I noticed you're pushing late. Everything okay?"      |
| Quality of code noticeably dropping            | Don't criticize. Ask: "Is there something blocking your focus?"    |
| Becoming quiet in discussions / retros         | Direct invite: "I'd love to hear your thoughts on this."           |
| Saying "fine" to everything without engagement | 1-on-1: "Be honest with me — are you feeling challenged or stuck?" |

**Your rule:** Output drops are SYMPTOMS, not the problem. Investigate the human cause before addressing the work cause.

### 12.6 Remote Team Bonding

Don't underestimate this. Remote teams across 3 countries that never connect as humans eventually feel like freelancers, not a team.

| Activity                     | Frequency | How                                                                |
| ---------------------------- | --------- | ------------------------------------------------------------------ |
| `#random` channel            | Daily     | Memes, food pics, non-work chat — Lead posts first to set the tone |
| Friday retro "wins" round    | Weekly    | 5 min of celebrating what went well                                |
| Virtual coffee / casual call | Monthly   | 30 min, no agenda, just chat — great for Haziq integration         |
| Skill sharing session        | Monthly   | One person teaches something (tool, trick, concept) — volunteers   |

---

## 13. Risk Management

| #   | Risk                                                    | Likelihood | Impact | Mitigation                                                               |
| --- | ------------------------------------------------------- | ---------- | ------ | ------------------------------------------------------------------------ |
| 1   | **Lead becomes review bottleneck**                      | High       | High   | Two-stage review. Peer review handles first-pass. Lead does focused final |
| 2   | **Standup exceeds 45 minutes**                          | Medium     | Medium | Timer enforced. 8 min/person hard cap. "Take it offline" for deep-dives  |
| 3   | **Mid/senior devs resist team processes**               | Medium     | High   | Frame processes as alignment, not control. Explain WHY each process exists. Invite their input on improvements. |
| 4   | **Quality drops with more contributors**                | Medium     | High   | 6-layer quality defense. CI blocks bad code. Peer + Lead review both     |
| 5   | **Haziq disengaged or resentful of new Lead**           | Medium     | High   | Rapport-first approach (Section 10). If unresolved after 2 months, escalate to boss with documented efforts. |
| 6   | **Anang or Fachri don't pass probation**                | Low-Med    | High   | Clear framework (Section 7). Communicate early at Month 2 if red flags. Never surprise anyone. Have Plan B for workload redistribution. |
| 7   | **Skill mismatch — listed as mid but performs as junior** | Low-Med  | Medium | Adjust expectations, provide more support, document in probation review. Separate from attitude — skill gaps can be fixed if attitude is right. |
| 8   | **One dev is significantly slower than others**         | Medium     | Medium | Track individually but address privately. Adjust task scope, not blame   |
| 9   | **Google Sheets becomes chaotic at 4 devs**             | Medium     | Low    | Add Sprint column, Assign column filter views per person. Review weekly  |
| 10  | **Cultural misunderstandings (3 countries)**            | Low        | Medium | Be explicit about expectations. Ask when unsure. Respect differences.    |
| 11  | **Lead burnout from managing 4 + coding 60%**           | Medium     | High   | Peer review reduces load. Protect 60% focus time. Delegate what you can  |

---

## 14. Pre-Launch Checklist

Before Anang and Fachri start, complete everything below:

### Infrastructure

- [ ] GitHub repository access granted (read + write to `develop`, no direct push to `main`)
- [ ] Branch protection rules configured (require PR + CI pass + 1 review)
- [ ] Portainer user accounts created (viewer role initially)
- [ ] Slack accounts created and added to all required channels
- [ ] Google Sheets task board access granted (editor)
- [ ] Google Meet / video call tool access confirmed

### Process

- [ ] Amirul briefed on codebase guide role (framed as growth opportunity and mutual exchange)
- [ ] 2-3 meaningful first tasks ready for Anang (mid-level scope, not trivial)
- [ ] 2-3 meaningful first tasks ready for Fachri (mid-level scope, not trivial)
- [ ] Standup format updated: 8 min/person, rotation order set
- [ ] Slack Workflow standup bot configured (replaces Geekbot)
- [ ] Sprint capacity updated in Google Sheets (4 devs, adjusted for onboarding)
- [ ] Probation scorecard template prepared (from Section 7)

### Documentation

- [ ] JUNIOR_DEVELOPER_SOP.md is up-to-date and accessible (for team conventions, not just juniors)
- [ ] TEAM_MANAGEMENT_PLAN.md is up-to-date and accessible
- [ ] Architecture documentation in `docs/architecture/` is current
- [ ] This playbook (TECH_LEAD_PLAYBOOK.md) is reviewed and ready

### Communication

- [ ] Team announcement: "We're growing! Here's what to expect."
- [ ] 1-on-1 with Amirul: explain codebase guide role, frame as mutual learning opportunity
- [ ] Welcome message prepared for Anang & Fachri (warm, transparent about process and probation)
- [ ] Intro 1-on-1 scheduled with Haziq (rapport-building, NOT task assignment)

---

## 15. Success Metrics

### 3-Month Checkpoint — Anang & Fachri (Probation Outcome)

| Metric                     | Target                                                              |
| -------------------------- | ------------------------------------------------------------------- |
| Probation scorecard        | All 7 indicators ≥ 3 in Month 3. Overall average ≥ 3.5.            |
| Features completed         | Multiple features end-to-end, increasing complexity over 3 months   |
| Code quality               | PRs require minimal feedback by Month 3                             |
| Architecture alignment     | Code follows project patterns; no persistent convention violations  |
| Peer review participation  | Actively reviewing teammates' PRs with constructive feedback        |
| Process adoption           | Full SOP compliance without reminders                               |
| Communication              | Clear standup updates, proactive blocker escalation                 |
| Team integration           | Positive interactions with all teammates; not working in silo       |

### 6-Month Checkpoint — Amirul

| Metric              | Target                                                     |
| ------------------- | ---------------------------------------------------------- |
| Feature ownership   | Owns features end-to-end (analysis → deploy)               |
| Technical growth    | Visible improvement in code complexity and patterns handled |
| Code review quality | Gives constructive feedback, not just approvals            |
| Estimation accuracy | Consistently 80-120%                                       |
| Documentation       | Has documented at least 2 features in docs/                |
| Independence        | Can be trusted with P2 tasks without daily Lead check-in   |

### Haziq Integration Metrics (Ongoing)

| Metric                     | Healthy Signal                                                |
| -------------------------- | ------------------------------------------------------------- |
| Response time              | Replies within 2 hours during core hours                      |
| Standup participation      | Attends consistently, provides meaningful updates             |
| Proactive communication    | Raises blockers and shares status without prompting           |
| Team interaction           | Engages in discussions, helps teammates, shares knowledge     |
| Relationship with Lead     | Comfortable raising concerns, gives honest input              |

### Team-Level Metrics (Monthly)

| Metric                             | Target                           | How to Measure                          |
| ---------------------------------- | -------------------------------- | --------------------------------------- |
| Sprint velocity                    | Stable or increasing             | Tasks completed per sprint              |
| Estimation accuracy (team average) | 80-120%                          | Actual / Estimated across all devs      |
| PR turnaround — peer review        | < 4 hours (same day)             | Time from PR open to peer review        |
| PR turnaround — Lead review        | < 24 hours                       | Time from peer approval to Lead review  |
| Production incidents               | 0 from code quality              | CI + review should catch everything     |
| RuboCop violations                 | 0 new violations per sprint      | CI report                               |
| Team happiness                     | No unresolved concerns in 1-on-1 | Qualitative, tracked by Lead            |

### The Ultimate Success Test

> **Can the team deliver a sprint's worth of features with consistent quality while the Lead is away for 1 week?**

If yes — you've built a team, not a dependency.

---

## Appendix: Quick Reference Cards

### Lead's Daily Checklist

```
☐ 08:30  Review async standup answers (all 4 devs)
☐ 09:00  Run daily standup (45 min, enforce timer)
☐ 09:45  Review PRs that passed peer review (prioritize by age)
☐ 10:00  Focus work (your 60% development scope)
☐ 12:00  Quick Slack scan — any blockers?
☐ PM      Continue focus work
☐ EOD     Quick Google Sheets scan — any status updates needed?
```

### Lead's Weekly Checklist

```
☐ Monday    Sprint planning (45 min)
☐ Monday    Ensure each dev has primary + backup task assigned
☐ Wednesday Quick scan of team health (any issues?)
☐ Friday    Weekly retro (20 min) — include "wins of the week"
☐ Friday    Update team metrics in Google Sheets
☐ Biweekly  1-on-1 with Anang (20 min) — probation tracking
☐ Biweekly  1-on-1 with Fachri (20 min) — probation tracking
☐ Biweekly  1-on-1 with Amirul (20 min) — growth focused
☐ Monthly   1-on-1 with Haziq (20 min) — relationship + goals
☐ Monthly   Fill probation scorecards for Anang & Fachri
☐ Monthly   Review and update this playbook if needed
```

### Probation Tracking Calendar

```
  Month 1:
  ☐ Week 2  — Observational notes on Anang & Fachri performance
  ☐ Week 4  — Month 1 Scorecard filled. Month 1 Checkpoint meeting.

  Month 2:
  ☐ Week 6  — Mid-point check. Any concerns documented.
  ☐ Week 8  — Month 2 Scorecard filled. Month 2 Checkpoint meeting.
              If at risk: explicit communication. No surprises at Month 3.

  Month 3:
  ☐ Week 10 — Final observation period. Compile all evidence.
  ☐ Week 12 — Month 3 Scorecard filled. Month 3 Decision meeting.
              Decision communicated: Pass / Extend / Fail.
```

---

_Document created by Arya Pratama — February 2026_
_Builds on: JUNIOR_DEVELOPER_SOP.md, TEAM_MANAGEMENT_PLAN.md_
_Review and update quarterly or when team structure changes._
