# Sentry Issues (Feed) Guide

> **TL;DR** — Sentry Issues is the **main error dashboard**. Every unhandled exception, rescued
> error, or manually captured problem in your Rails app becomes an "issue" in Sentry. The Feed
> shows them all — grouped, deduplicated, and prioritized.

---

## Table of Contents

- [What Is This?](#what-is-this)
- [Why Do We Use It?](#why-do-we-use-it)
- [When Do We Use It?](#when-do-we-use-it)
- [Who Uses It?](#who-uses-it)
- [Where Is It Used?](#where-is-it-used)
- [How It Works](#how-it-works)
- [Our Setup](#our-setup)
- [How to Use the Issues Dashboard](#how-to-use-the-issues-dashboard)
- [Issue Lifecycle](#issue-lifecycle)
- [How Errors Are Captured](#how-errors-are-captured)
- [Manually Capturing Errors](#manually-capturing-errors)
- [Issue Context & Metadata](#issue-context--metadata)
- [Alerts & Notifications](#alerts--notifications)
- [Best Practices](#best-practices)
- [Troubleshooting](#troubleshooting)
- [FAQ](#faq)
- [References](#references)

---

## What Is This?

**Sentry Issues** (the "Feed") is the core error tracking feature. When your Rails app throws
an exception or you manually report a problem, Sentry creates an **issue** — a grouped collection
of similar error events.

```
Your Rails App                          Sentry Issues Feed
┌─────────────────┐                    ┌──────────────────────────────┐
│                  │                    │  Feed                        │
│  500 Error! ─────┼───────────────────▶│  🔍 is:unresolved            │
│  NoMethodError   │   auto-captured    │                              │
│                  │                    │  ❌ NoMethodError             │
│  rescue => e ────┼───────────────────▶│     undefined method 'round' │
│  Sentry.capture  │   manually sent    │     payslip_calculator.rb:42 │
│                  │                    │     238 events · 15 users    │
│  Validation ─────┼───────────────────▶│                              │
│  Error           │   auto-captured    │  ⚠️  ActiveRecord::NotFound  │
│                  │                    │     Couldn't find Worker     │
└─────────────────┘                    │     workers_controller.rb:27 │
                                       │     12 events · 8 users      │
                                       └──────────────────────────────┘
```

### Key concepts

- **Event** — A single occurrence of an error (one crash, one exception)
- **Issue** — A group of similar events (e.g., all `NoMethodError` from the same line)
- **Feed** — The list view of all issues, filterable and sortable

---

## Why Do We Use It?

| Problem (Without)                                     | Solution (With Sentry Issues)                      |
| ----------------------------------------------------- | -------------------------------------------------- |
| "Did anything break in production?"                   | Issues Feed shows all errors in real-time          |
| "How many users are affected by this bug?"            | Each issue shows affected user count               |
| "Is this a new bug or an old one?"                    | Issues are grouped — you see first/last seen dates |
| "The user says something is broken but I can't repro" | Full stack trace, request data, user info attached |
| "I fixed the bug, did it come back?"                  | Regression detection auto-reopens resolved issues  |
| "We have too many errors, which one matters most?"    | Issues are sorted by frequency, users affected     |

---

## When Do We Use It?

| Scenario                 | How Issues Feed Helps                             |
| ------------------------ | ------------------------------------------------- |
| **After a deployment**   | Check Feed for new issues in the latest release   |
| **User reports a bug**   | Search Feed for the error to see full context     |
| **Daily health check**   | Glance at Feed to see if anything is unresolved   |
| **Sprint retrospective** | Review resolved vs. new issues this sprint        |
| **Before a release**     | Verify all critical issues are resolved           |
| **On-call monitoring**   | Feed + alerts notify you of new/escalating issues |

---

## Who Uses It?

| Role                | Use Case                                                       |
| ------------------- | -------------------------------------------------------------- |
| **Developers**      | Debug errors using stack traces, request data, and breadcrumbs |
| **Tech Lead**       | Prioritize which errors to fix, track error trends             |
| **QA**              | Verify that reported bugs match Sentry issues                  |
| **Product Manager** | Understand impact (how many users affected)                    |

---

## Where Is It Used?

| Environment     | Issues Captured? | Notes                                      |
| --------------- | ---------------- | ------------------------------------------ |
| **Production**  | ✅ Yes           | All unhandled exceptions + manual captures |
| **Development** | ✅ Yes           | If `SENTRY_DSN` is set in `.env`           |
| **Test**        | ❌ No            | `SENTRY_DSN` is not set in test env        |

---

## How It Works

### The Error Flow

```
1. An error occurs in your Rails app
   (unhandled exception, rescued error, or manual capture)
   │
   ▼
2. Sentry SDK captures the error with:
   - Full stack trace
   - Request parameters (URL, headers, body)
   - User info (if send_default_pii is enabled)
   - Breadcrumbs (recent actions leading to the error)
   - Release version
   - Environment (production/development)
   │
   ▼
3. SDK sends the event to Sentry's API
   │
   ▼
4. Sentry groups the event into an existing Issue
   (or creates a new Issue if it's a new error type)
   │
   ▼
5. Issue appears in the Feed
   - Shows event count, affected users, first/last seen
   - Linked to the release that introduced it
   - Linked to the suspect commit (if release tracking is set up)
```

### Grouping: How Sentry Knows Two Errors Are "The Same"

Sentry groups errors into issues by **fingerprint** — a combination of:

- Exception type (`NoMethodError`, `ActiveRecord::RecordNotFound`, etc.)
- Stack trace (the file and line where the error occurred)
- Error message pattern

So if 100 users hit the same `NoMethodError` on line 42, Sentry creates **1 issue with 100 events**,
not 100 separate issues.

---

## Our Setup

### What's Already Configured

Everything needed for Issues is already set up in our project:

```ruby
# config/initializers/sentry.rb
Sentry.init do |config|
  config.dsn = ENV.fetch('SENTRY_DSN', nil)           # ① Where to send events
  config.release = ENV.fetch('SENTRY_RELEASE', nil)    # ② Tag issues with deploy version
  config.send_default_pii = true                       # ③ Include user data & request info
  config.breadcrumbs_logger = %i[                      # ④ Record recent actions as breadcrumbs
    active_support_logger
    http_logger
  ]
end
```

| Config                    | What It Does for Issues                                     |
| ------------------------- | ----------------------------------------------------------- |
| `config.dsn`              | Enables Sentry — required for anything to work              |
| `config.release`          | Tags each issue with the deployed version (suspect commits) |
| `config.send_default_pii` | Attaches user IP, request headers, cookies to the issue     |
| `breadcrumbs_logger`      | Records a trail of recent events leading to the error       |

### Gems Required (`Gemfile`)

```ruby
gem "sentry-ruby"    # Core SDK — captures exceptions
gem "sentry-rails"   # Rails integration — auto-captures controller/job errors
```

### What Gets Auto-Captured (Zero Code Required)

`sentry-rails` automatically captures:

| Error Type                      | Example                                      |
| ------------------------------- | -------------------------------------------- |
| Unhandled controller exceptions | 500 Internal Server Error                    |
| ActiveRecord errors             | `RecordNotFound`, `RecordInvalid`            |
| Routing errors                  | `ActionController::RoutingError` (404)       |
| Background job failures         | ActiveJob raising an exception               |
| CSRF token errors               | `ActionController::InvalidAuthenticityToken` |

You don't need to add `rescue` blocks for these — `sentry-rails` intercepts them automatically.

---

## How to Use the Issues Dashboard

### Accessing the Feed

1. Go to [sentry.io](https://sentry.io)
2. Select org **st-advisory** → project **ruby-rails**
3. Click **Issues** in the left sidebar (this is the "Feed")

### Dashboard Layout

```
┌────────────────────────────────────────────────────────────┐
│  Feed                                                      │
│                                                            │
│  [All Projects ▼] [All Envs ▼] [1H ▼]    [Last Seen ▼]   │
│  🔍 is:unresolved                                          │
│                                                            │
│  ┌──────────────────────────────────────────────────────┐  │
│  │  ❌ NoMethodError: undefined method 'round'          │  │
│  │     app/services/payslip_calculator.rb:42            │  │
│  │     238 events · 15 users · First seen: 2h ago       │  │
│  ├──────────────────────────────────────────────────────┤  │
│  │  ⚠️  ActiveRecord::RecordNotFound                    │  │
│  │     app/controllers/workers_controller.rb:27         │  │
│  │     12 events · 8 users · First seen: 1d ago         │  │
│  ├──────────────────────────────────────────────────────┤  │
│  │  ❌ ActionController::RoutingError                   │  │
│  │     No route matches [GET] "/api/v2/users"           │  │
│  │     5 events · 3 users · First seen: 3h ago          │  │
│  └──────────────────────────────────────────────────────┘  │
│                                                            │
│  "No issues match your search" = Everything is good! ✅    │
└────────────────────────────────────────────────────────────┘
```

### Search & Filter

| Filter          | Example                     | Purpose                               |
| --------------- | --------------------------- | ------------------------------------- |
| `is:unresolved` | Default — shows open issues | Active bugs that need attention       |
| `is:resolved`   | Shows fixed issues          | Verify your fix worked                |
| `is:ignored`    | Shows ignored issues        | Low-priority issues you've snoozed    |
| `release:X`     | Filter by deploy version    | "Did this deploy introduce new bugs?" |
| `assigned:me`   | Issues assigned to you      | Your personal bug queue               |
| Text search     | `"PayslipService"`          | Find issues mentioning a keyword      |

### Sorting

| Sort By        | When to Use                            |
| -------------- | -------------------------------------- |
| **Last Seen**  | Default — see the most recent activity |
| **First Seen** | Find newly introduced bugs             |
| **Events**     | Find the most frequent errors          |
| **Users**      | Find bugs affecting the most people    |
| **Priority**   | Sentry's automatic prioritization      |

---

## Issue Lifecycle

Every issue goes through a lifecycle:

```
 ┌───────────┐    Developer    ┌───────────┐    Deploy    ┌───────────┐
 │ UNRESOLVED │──── fixes ────▶│ RESOLVED  │──── new ───▶│ REGRESSION│
 │ (new bug)  │    the bug     │ (marked   │    error!   │ (reopened) │
 └───────────┘                 │  fixed)   │             └───────────┘
       │                       └───────────┘                    │
       │                                                        │
       ▼                                                        ▼
 ┌───────────┐                                           Back to
 │  IGNORED  │                                           UNRESOLVED
 │ (snoozed) │
 └───────────┘
```

| Status         | Meaning                                                         |
| -------------- | --------------------------------------------------------------- |
| **Unresolved** | Active bug — needs investigation and a fix                      |
| **Resolved**   | Bug has been fixed (manually marked or auto-resolved by deploy) |
| **Ignored**    | Intentionally dismissed (noise, known limitation, etc.)         |
| **Regression** | A resolved issue that reappeared — high priority!               |

---

## How Errors Are Captured

### 1. Automatic Capture (No Code Needed)

`sentry-rails` automatically captures any unhandled exception:

```ruby
# This error is auto-captured — no Sentry code needed
class WorkersController < ApplicationController
  def show
    @worker = Worker.find(params[:id])  # Raises RecordNotFound if not found
  end
end
```

If `Worker.find(999)` fails, Sentry automatically captures the `ActiveRecord::RecordNotFound`
with the full stack trace, request params, and user info.

### 2. Manual Capture in Rescue Blocks

When you rescue an error but still want Sentry to know:

```ruby
class PayslipService
  def generate(worker)
    payslip = Payslip.create!(worker: worker, amount: calculate(worker))
    send_email(payslip)
  rescue StandardError => e
    # Handle the error gracefully (e.g., show user a message)
    # But still report it to Sentry:
    Sentry.capture_exception(e)

    # Optionally return a fallback
    nil
  end
end
```

### 3. Capture with Extra Context

Add business-specific context to help with debugging:

```ruby
class PayslipService
  def generate(worker)
    payslip = Payslip.create!(worker: worker, amount: calculate(worker))
  rescue StandardError => e
    Sentry.capture_exception(e, extra: {
      worker_id: worker.id,
      worker_name: worker.name,
      calculation_method: "monthly",
      attempted_amount: calculate(worker)
    })
  end
end
```

### 4. Capture a Message (Not an Exception)

For non-exception problems you want to track:

```ruby
# Something weird happened but didn't crash
if worker.bank_account.nil?
  Sentry.capture_message(
    "Worker has no bank account — cannot process payout",
    level: :warning,
    extra: { worker_id: worker.id }
  )
end
```

### 5. Set User Context

Sentry can track which user experienced the error:

```ruby
# Typically in ApplicationController
class ApplicationController < ActionController::Base
  before_action :set_sentry_context

  private

  def set_sentry_context
    if current_user
      Sentry.set_user(
        id: current_user.id,
        email: current_user.email,
        username: current_user.name
      )
    end
  end
end
```

> **Note:** Our config has `config.send_default_pii = true`, which automatically includes
> request IP and headers. The `set_user` call adds user identity on top of that.

---

## Issue Context & Metadata

When you click on an issue in the Feed, you see a detailed page with:

### Stack Trace

The exact code path that caused the error:

```
NoMethodError: undefined method 'round' for nil:NilClass

  app/services/payslip_calculator.rb:42  in `calculate_gross`
  app/services/payslip_service.rb:15     in `generate`
  app/controllers/payslips_controller.rb:28  in `create`
```

### Breadcrumbs

A timeline of events leading up to the error:

```
12:30:01  HTTP  GET /workers/42             → 200 OK
12:30:02  SQL   SELECT * FROM workers ...   → 1 row
12:30:02  HTTP  POST /payslips              → started
12:30:02  SQL   SELECT * FROM deductions .. → 0 rows
12:30:02  ERROR NoMethodError               → 💥
```

### Tags & Context

| Tag           | Value              | Purpose                       |
| ------------- | ------------------ | ----------------------------- |
| `release`     | `abc1234...`       | Which deploy this occurred in |
| `environment` | `production`       | Which environment             |
| `url`         | `/payslips`        | Which page/endpoint           |
| `browser`     | `Chrome 120`       | User's browser                |
| `os`          | `Windows 11`       | User's OS                     |
| `user`        | `arya@example.com` | Who experienced the error     |

---

## Alerts & Notifications

### Setting Up Alerts

1. Go to Sentry → **Alerts** in the left sidebar
2. Click **Create Alert Rule**
3. Common alert types:

| Alert Type          | Trigger                             | Use Case                      |
| ------------------- | ----------------------------------- | ----------------------------- |
| **New Issue**       | A never-before-seen error occurs    | Catch new bugs immediately    |
| **Issue Frequency** | An issue gets >100 events in 1 hour | Existing bug is getting worse |
| **Regression**      | A resolved issue reappears          | Your fix didn't work          |

### Notification Channels

Alerts can be sent to:

- **Email** — Default, per-user
- **Slack** — Via Sentry's Slack integration
- **Webhook** — Custom integrations

---

## Best Practices

### Do

- ✅ Check the Feed after every deployment ("did we break anything?")
- ✅ Use `Sentry.capture_exception(e)` in rescue blocks for important operations
- ✅ Add `extra:` context when capturing (IDs, amounts, operation names)
- ✅ Set user context with `Sentry.set_user` for user-specific debugging
- ✅ Resolve issues after fixing them — enables regression detection
- ✅ Use `is:unresolved` as your daily bug triage view

### Don't

- ❌ Don't ignore the Feed — check it regularly
- ❌ Don't capture expected errors (e.g., validation failures from user input)
- ❌ Don't use `Sentry.capture_exception` for flow control
- ❌ Don't leave all issues as "unresolved" forever — triage them
- ❌ Don't include sensitive data in `extra:` context (passwords, tokens)

---

## Troubleshooting

| Problem                             | Cause                          | Fix                                                                             |
| ----------------------------------- | ------------------------------ | ------------------------------------------------------------------------------- |
| No issues appearing                 | `SENTRY_DSN` not set           | Check `.env` file                                                               |
| Issues show without stack trace     | Source maps/debug info missing | Ensure production builds include debug info                                     |
| Too many issues (noise)             | Capturing expected errors      | Don't capture validation/auth errors                                            |
| "No issues match your search"       | Everything is working fine! 🎉 | This is the goal — zero unresolved issues                                       |
| Issue shows no user info            | `send_default_pii` is false    | Set `config.send_default_pii = true` in initializer                             |
| Same error shows as multiple issues | Different stack traces         | Sentry groups by fingerprint — slightly different paths create different issues |

---

## FAQ

**Q: What does "No issues match your search" mean?**
Good news! It means there are no unresolved errors. Your app is running cleanly.
(As shown in your screenshot — this is the ideal state.)

**Q: Should I capture every rescued exception?**
No. Only capture exceptions that indicate **unexpected problems**. Don't capture things like
`RecordNotFound` when it's a 404 page — that's expected behavior.

**Q: What's the difference between Issues and Logs?**

- **Issues** = Errors/exceptions (grouped, with stack traces, assignable)
- **Logs** = Informational messages (info/warn/debug, not grouped as issues)

Think of it as: Issues are "something broke", Logs are "here's what happened".

**Q: Can I assign an issue to a team member?**
Yes. Click on an issue → click "Assign" → select a team member. You can also set up
auto-assignment rules based on code ownership.

**Q: How do I mark an issue as fixed?**
Click on the issue → click "Resolve". If the error occurs again in a new release,
Sentry will reopen it as a **regression**.

**Q: Does the Feed show errors from both st_intent_harvest and st_accorn?**
If both apps use the same `SENTRY_DSN` and project, yes. If they use separate projects,
use the "All Projects" dropdown to toggle between them.

---

## References

- [Sentry Issues Documentation](https://docs.sentry.io/product/issues/)
- [Issue Grouping](https://docs.sentry.io/product/issues/grouping/)
- [Sentry Alerts](https://docs.sentry.io/product/alerts/)
- [sentry-ruby Error Capturing](https://docs.sentry.io/platforms/ruby/usage/)
- [Breadcrumbs](https://docs.sentry.io/platforms/ruby/enriching-events/breadcrumbs/)
- [Sentry Releases Guide](SENTRY_RELEASES_GUIDE.md) — How releases link to issues
- [Sentry Logs Guide](SENTRY_LOGS_GUIDE.md) — How logs complement issues
