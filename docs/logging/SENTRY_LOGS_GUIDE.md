# Sentry Logs Guide

> **TL;DR** — Sentry Logs captures structured log messages (info, warn, error, debug) from your
> Rails app and displays them in a searchable, filterable dashboard. Think of it as a **cloud-based
> log viewer** that's linked to your errors, traces, and releases.

---

## Table of Contents

- [What Is This?](#what-is-this)
- [Why Do We Use It?](#why-do-we-use-it)
- [When Do We Use It?](#when-do-we-use-it)
- [Who Uses It?](#who-uses-it)
- [Where Is It Used?](#where-is-it-used)
- [How It Works](#how-it-works)
- [Our Setup](#our-setup)
- [How to Use the Logs Dashboard](#how-to-use-the-logs-dashboard)
- [How to Send Logs from Code](#how-to-send-logs-from-code)
- [Structured Logging Subscribers](#structured-logging-subscribers)
- [Log Levels Explained](#log-levels-explained)
- [Best Practices](#best-practices)
- [Troubleshooting](#troubleshooting)
- [FAQ](#faq)
- [References](#references)

---

## What Is This?

**Sentry Logs** is a feature that collects structured log messages from your running application
and displays them in the Sentry dashboard. Instead of SSHing into a server and tailing log files,
you can search, filter, and analyze logs directly in your browser.

```
Your Rails App                         Sentry Dashboard
┌─────────────────┐                   ┌─────────────────────────┐
│                  │                   │  Logs                   │
│  Rails.logger   ─┼──────────────────▶│  ┌───────────────────┐ │
│  .info("...")    │   sent via SDK    │  │ 12:50 PM  INFO .. │ │
│                  │                   │  │ 12:51 PM  WARN .. │ │
│  Sentry.logger  ─┼──────────────────▶│  │ 12:52 PM  ERROR..│ │
│  .error("...")   │                   │  └───────────────────┘ │
│                  │                   │                         │
│  Auto-captured: ─┼──────────────────▶│  528 logs (1H)         │
│  ActiveRecord    │                   │  Searchable, filterable │
│  ActionController│                   │  Linked to releases     │
│  ActiveJob       │                   └─────────────────────────┘
│  ActionMailer    │
└─────────────────┘
```

---

## Why Do We Use It?

| Problem (Without)                            | Solution (With Sentry Logs)                        |
| -------------------------------------------- | -------------------------------------------------- |
| "I need to SSH into the server to read logs" | View logs in the browser from anywhere             |
| "Logs are lost when the container restarts"  | Logs are stored in Sentry (retained based on plan) |
| "I can't search across multiple log files"   | Full-text search across all logs in one place      |
| "I can't correlate a log with an error"      | Logs are linked to errors, traces, and releases    |
| "Which server generated this log?"           | `server.address` filter shows the source           |
| "I only want to see error-level logs"        | Filter by severity: info, warn, error, debug       |

---

## When Do We Use It?

| Scenario                         | How Sentry Logs Helps                              |
| -------------------------------- | -------------------------------------------------- |
| **Debugging a production error** | See the logs leading up to the error               |
| **Investigating slow requests**  | Check if there were N+1 queries or timeouts logged |
| **Monitoring background jobs**   | See ActiveJob execution logs without SSHing        |
| **Verifying a deploy worked**    | Check for startup logs after a deployment          |
| **Auditing user actions**        | Search for specific user activity in logs          |
| **Checking email delivery**      | See ActionMailer logs for sent/failed emails       |

---

## Who Uses It?

| Role           | Use Case                                           |
| -------------- | -------------------------------------------------- |
| **Developers** | Debug errors, trace request flow, investigate bugs |
| **Tech Lead**  | Monitor application health, review log patterns    |
| **DevOps**     | Check deployment logs, monitor infrastructure      |

---

## Where Is It Used?

| Environment     | Enabled? | Notes                                       |
| --------------- | -------- | ------------------------------------------- |
| **Production**  | ✅ Yes   | All logs are sent to Sentry                 |
| **Development** | ✅ Yes   | Sent if `SENTRY_DSN` is set in `.env`       |
| **Test**        | ❌ No    | `SENTRY_DSN` is not set in test environment |

---

## How It Works

### The Flow

```
1. Your code writes a log message
   │
   ▼
2. Rails logger / Sentry logger captures it
   │
   ▼
3. Sentry SDK packages the log with metadata:
   - Timestamp
   - Severity (info/warn/error/debug)
   - Release version (SENTRY_RELEASE)
   - Server address
   - Message content
   │
   ▼
4. SDK sends the log to Sentry's API
   │
   ▼
5. Log appears in Sentry → Logs dashboard
   (searchable, filterable, linked to errors/traces)
```

### Two Ways Logs Get to Sentry

1. **Automatic (Subscribers)** — Certain Rails events are captured automatically:
   - `ActiveRecord` — Database queries
   - `ActionController` — HTTP request processing
   - `ActiveJob` — Background job execution
   - `ActionMailer` — Email delivery

2. **Manual (Logger Patch)** — Any `Rails.logger` or `Sentry.logger` call is forwarded:
   - `Rails.logger.info("...")` → sent to Sentry
   - `Sentry.logger.warn("...")` → sent to Sentry

---

## Our Setup

### Configuration (`config/initializers/sentry.rb`)

Here's what each log-related line does:

```ruby
Sentry.init do |config|
  # ① Enable the Logs feature
  config.enable_logs = true

  # ② Auto-capture structured logs from Rails subsystems
  config.rails.structured_logging.subscribers = {
    active_record: Sentry::Rails::LogSubscribers::ActiveRecordSubscriber,
    action_controller: Sentry::Rails::LogSubscribers::ActionControllerSubscriber,
    active_job: Sentry::Rails::LogSubscribers::ActiveJobSubscriber,
    action_mailer: Sentry::Rails::LogSubscribers::ActionMailerSubscriber
  }

  # ③ Forward ALL Rails.logger calls to Sentry
  config.enabled_patches << :logger
end
```

| Line                                | What It Does                                                                        |
| ----------------------------------- | ----------------------------------------------------------------------------------- |
| `config.enable_logs = true`         | Turns on the Sentry Logs feature                                                    |
| `structured_logging.subscribers`    | Auto-captures logs from ActiveRecord, ActionController, ActiveJob, and ActionMailer |
| `config.enabled_patches << :logger` | Forwards every `Rails.logger.*` call to Sentry                                      |

### Gems Required (`Gemfile`)

```ruby
gem "sentry-ruby"    # Core SDK
gem "sentry-rails"   # Rails integration (provides the subscribers)
```

These are already installed in the project.

### Environment Variable (`.env`)

```bash
# Required — tells the SDK where to send logs
SENTRY_DSN=https://xxx@xxx.ingest.us.sentry.io/xxx
```

---

## How to Use the Logs Dashboard

### Accessing Logs

1. Go to [sentry.io](https://sentry.io)
2. Select org **st-advisory** → project **ruby-rails**
3. Click **Logs** in the left sidebar

### Dashboard Overview

The Logs dashboard (as seen in your screenshot) shows:

```
┌──────────────────────────────────────────────────────────┐
│  Logs                                                    │
│                                                          │
│  [All Projects ▼] [All Envs ▼] [1H ▼]  🔍 Search...    │
│                                                          │
│  Filters: message is... | severity is... | release is... │
│                                                          │
│  ┌──── count(logs) ─── Bar ─── 1 minute ──────────┐     │
│  │  █      █  █       █  █      █  █       █  █    │     │
│  │  ▁▁█▁▁▁▁█▁▁█▁▁▁▁▁▁▁█▁▁█▁▁▁▁█▁▁█▁▁▁▁▁▁▁█▁▁█▁▁ │     │
│  │  12:40  12:50 1:00  1:10 1:20  1:30             │     │
│  └──────────────────────────────────────────────────┘     │
│  528 logs                                                │
│                                                          │
│  TIMESTAMP ↓    MESSAGE                                  │
│  1:30:12 PM     Processing by DashboardController#index  │
│  1:30:12 PM     Worker Load (0.5ms)                      │
│  1:30:11 PM     SendPayslipEmailJob performed            │
│  ...                                                     │
└──────────────────────────────────────────────────────────┘
```

### Searching & Filtering

| Filter       | Example                        | Purpose                                |
| ------------ | ------------------------------ | -------------------------------------- |
| **Message**  | `message is "PayslipService"`  | Find logs containing a specific string |
| **Severity** | `severity is error`            | Show only error-level logs             |
| **Release**  | `release is abc1234...`        | Show logs from a specific deploy       |
| **Server**   | `server.address is 172.18.0.5` | Show logs from a specific container    |
| **Time**     | `1H`, `24H`, `7D`              | Adjust the time window                 |

### Quick Filter Examples

**"Show me all errors in the last hour":**

- Set time to `1H`
- Add filter: `severity is error`

**"Show me logs from the latest deploy":**

- Add filter: `release is <git-sha>`

**"Find all database queries for WorkOrder":**

- Search: `WorkOrder Load`

---

## How to Send Logs from Code

### Option 1: Use `Rails.logger` (auto-forwarded)

Since we have the `:logger` patch enabled, any `Rails.logger` call is automatically sent to Sentry:

```ruby
# All of these go to Sentry automatically:
Rails.logger.info("User #{user.id} logged in")
Rails.logger.warn("Slow query detected: #{duration}ms")
Rails.logger.error("Payment failed for order #{order.id}")
Rails.logger.debug("Cache key: #{cache_key}")
```

### Option 2: Use `Sentry.logger` (explicit, recommended)

For intentional, targeted logging to Sentry:

```ruby
# These are explicit — you're choosing to send this to Sentry
Sentry.logger.info("Payslip generated successfully", payslip_id: payslip.id)
Sentry.logger.warn("Worker has no bank account", worker_id: worker.id)
Sentry.logger.error("Export failed", export_type: "csv", error: e.message)
```

### Option 3: Use `AppLogger` (our custom logger)

Our `AppLogger` writes to `Rails.logger`, which is forwarded to Sentry:

```ruby
# This goes to Rails.logger → then to Sentry
AppLogger.info("Work order created", context: "WorkOrderService", id: wo.id)
AppLogger.error("Validation failed", context: "PayslipService", error: e.message)
```

### Which Should I Use?

| Method            | When to Use                                       |
| ----------------- | ------------------------------------------------- |
| `Sentry.logger.*` | When you specifically want this in Sentry         |
| `AppLogger.*`     | General application logging (also goes to Sentry) |
| `Rails.logger.*`  | General purpose (also goes to Sentry)             |

> **Note:** Since all `Rails.logger` calls are forwarded to Sentry, it can be noisy.
> For targeted, important logs, prefer `Sentry.logger` or `AppLogger`.

---

## Structured Logging Subscribers

These automatically capture logs from Rails subsystems without any code changes:

### ActiveRecord Subscriber

Captures all database queries:

```
WorkOrder Load (0.5ms)  SELECT "work_orders".* FROM "work_orders" WHERE ...
Worker Create (1.2ms)   INSERT INTO "workers" ...
```

### ActionController Subscriber

Captures HTTP request processing:

```
Processing by DashboardController#index as HTML
Completed 200 OK in 45ms (Views: 30ms | ActiveRecord: 10ms)
```

### ActiveJob Subscriber

Captures background job execution:

```
[ActiveJob] Performing SendPayslipEmailJob (Job ID: abc-123)
[ActiveJob] Performed SendPayslipEmailJob (Job ID: abc-123) in 1200ms
```

### ActionMailer Subscriber

Captures email delivery:

```
PayslipMailer#monthly_payslip: processed outbound mail in 50ms
PayslipMailer#monthly_payslip: delivered mail abc123 (500ms)
```

---

## Log Levels Explained

| Level   | When to Use                                | Example                                            |
| ------- | ------------------------------------------ | -------------------------------------------------- |
| `debug` | Detailed info for debugging (very verbose) | `"Cache key: worker_#{id}_payslips"`               |
| `info`  | Normal operations, confirmations           | `"Payslip generated for worker 42"`                |
| `warn`  | Something unexpected but not broken        | `"Worker 42 has no bank account, skipping payout"` |
| `error` | Something broke, needs attention           | `"Failed to generate PDF: memory limit exceeded"`  |

> In production, you typically care about `warn` and `error`. Use `info` for
> important business events. Use `debug` sparingly — it's very noisy.

---

## Best Practices

### Do

- ✅ Use `Sentry.logger` for important, targeted logs you want to find easily
- ✅ Include context (IDs, names, amounts) in log messages
- ✅ Use appropriate log levels (don't log everything as `error`)
- ✅ Use the `release` filter to see logs from a specific deploy
- ✅ Use the `severity` filter to focus on errors/warnings

### Don't

- ❌ Don't log passwords, tokens, or sensitive data
- ❌ Don't use `debug` level in production for high-frequency operations
- ❌ Don't ignore the `count(logs)` chart — sudden spikes may indicate problems
- ❌ Don't rely solely on Sentry Logs — also check Docker logs for container-level issues

---

## Troubleshooting

| Problem                         | Cause                                       | Fix                                                           |
| ------------------------------- | ------------------------------------------- | ------------------------------------------------------------- |
| No logs appearing in Sentry     | `enable_logs` not set to `true`             | Check `config/initializers/sentry.rb`                         |
| No logs appearing in Sentry     | `SENTRY_DSN` not set                        | Check `.env` file for `SENTRY_DSN`                            |
| Missing ActiveRecord logs       | Subscriber not configured                   | Ensure `active_record` is in `structured_logging.subscribers` |
| Too many logs / very noisy      | `:logger` patch forwards everything         | Remove `config.enabled_patches << :logger` if unwanted        |
| Logs don't show release version | `SENTRY_RELEASE` not set                    | See [Sentry Releases Guide](SENTRY_RELEASES_GUIDE.md)         |
| Logs appear with delay          | Normal — SDK batches and sends periodically | Wait 30-60 seconds, then refresh                              |

---

## FAQ

**Q: Does this replace our Docker logs?**
No. Sentry Logs is complementary. Docker logs capture everything including boot messages,
system errors, and container events. Sentry Logs captures application-level logs with
metadata like release version and user context.

**Q: Does sending logs to Sentry slow down the app?**
Minimal impact. The SDK batches logs and sends them asynchronously. The overhead is
negligible for most applications.

**Q: Is there a log limit on the free plan?**
Sentry has a quota based on your plan. Logs count toward your event quota. If you
exceed the quota, logs may be dropped. Monitor your usage in Sentry → Settings → Usage.

**Q: Can I see logs in development?**
Yes, if your `.env` has `SENTRY_DSN` set. Logs from your local machine will appear in
Sentry, which is useful for testing. Remove or unset `SENTRY_DSN` to disable.

**Q: How long are logs retained?**
Depends on your Sentry plan. Free tier typically retains data for 30 days.

---

## References

- [Sentry Logs Feature](https://docs.sentry.io/product/explore/logs/)
- [sentry-ruby Logging](https://docs.sentry.io/platforms/ruby/guides/rails/logging/)
- [Structured Logging Subscribers](https://docs.sentry.io/platforms/ruby/guides/rails/)
- [AppLogger Guide](APP_LOGGER_GUIDE.md) — Our custom application logger
- [Sentry Releases Guide](SENTRY_RELEASES_GUIDE.md) — How releases link to logs
