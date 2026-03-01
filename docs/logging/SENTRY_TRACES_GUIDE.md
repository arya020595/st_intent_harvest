# Sentry Traces Guide

> **TL;DR** — Sentry Traces (Performance Monitoring) shows you **how long things take** in your
> app. Every HTTP request, database query, and background job is measured as a "span" — you can
> see exactly where time is being spent and find bottlenecks.

---

## Table of Contents

- [What Is This?](#what-is-this)
- [Why Do We Use It?](#why-do-we-use-it)
- [When Do We Use It?](#when-do-we-use-it)
- [Who Uses It?](#who-uses-it)
- [Where Is It Used?](#where-is-it-used)
- [How It Works](#how-it-works)
- [Our Setup](#our-setup)
- [Key Concepts](#key-concepts)
- [How to Use the Traces Dashboard](#how-to-use-the-traces-dashboard)
- [Reading a Trace Waterfall](#reading-a-trace-waterfall)
- [Trace Propagation (Frontend ↔ Backend)](#trace-propagation-frontend--backend)
- [Custom Spans](#custom-spans)
- [Sample Rate Explained](#sample-rate-explained)
- [Best Practices](#best-practices)
- [Troubleshooting](#troubleshooting)
- [FAQ](#faq)
- [References](#references)

---

## What Is This?

**Sentry Traces** (also called Performance Monitoring) captures **timing data** for your
application's operations. It answers: _"How long did this request take, and where was the
time spent?"_

```
User clicks "Generate Payslip"
│
├─ Transaction: POST /payslips (total: 1200ms)
│   │
│   ├─ Span: SQL SELECT workers (5ms)
│   ├─ Span: SQL SELECT deductions (3ms)
│   ├─ Span: PayslipCalculator.calculate (50ms)
│   ├─ Span: SQL INSERT payslips (8ms)
│   ├─ Span: PDF Generation (900ms)        ← 🐌 Bottleneck!
│   └─ Span: SendPayslipEmailJob.enqueue (2ms)
│
└─ Total: 1200ms → "PDF generation is the bottleneck"
```

Without traces, you know a request is slow. With traces, you know **exactly which part** is slow.

---

## Why Do We Use It?

| Problem (Without)                                 | Solution (With Sentry Traces)                           |
| ------------------------------------------------- | ------------------------------------------------------- |
| "The page is slow but I don't know why"           | Trace waterfall shows time breakdown per operation      |
| "Which database queries are taking too long?"     | SQL spans show individual query durations               |
| "Is it the controller, the service, or the view?" | Each layer is a separate span with its own timing       |
| "Are background jobs performing well?"            | ActiveJob traces show job execution time                |
| "How does this release compare to the last one?"  | Compare performance metrics between releases            |
| "Which endpoints are the slowest?"                | Traces dashboard ranks endpoints by p50/p75/p95 latency |

---

## When Do We Use It?

| Scenario                         | How Traces Helps                                        |
| -------------------------------- | ------------------------------------------------------- |
| **User reports slow page**       | Find the exact trace and see the waterfall              |
| **After a deployment**           | Compare performance metrics before/after                |
| **Optimizing a feature**         | Identify bottleneck spans (DB, external API, PDF, etc.) |
| **Monitoring daily performance** | Check p95 response times are within acceptable range    |
| **Investigating N+1 queries**    | Trace shows many small SQL spans instead of one batch   |
| **Capacity planning**            | Understand how much time is spent in DB vs. app logic   |

---

## Who Uses It?

| Role           | Use Case                                                 |
| -------------- | -------------------------------------------------------- |
| **Developers** | Debug slow requests, find N+1 queries, optimize code     |
| **Tech Lead**  | Monitor overall app performance, set performance budgets |
| **DevOps**     | Identify infrastructure bottlenecks, plan capacity       |

---

## Where Is It Used?

| Environment     | Tracing Enabled? | Sample Rate  | Notes                            |
| --------------- | ---------------- | ------------ | -------------------------------- |
| **Production**  | ✅ Yes           | 100% (`1.0`) | Every request is traced          |
| **Development** | ✅ Yes           | 100% (`1.0`) | If `SENTRY_DSN` is set in `.env` |
| **Test**        | ❌ No            | N/A          | `SENTRY_DSN` is not set          |

---

## How It Works

### The Tracing Flow

```
1. User makes an HTTP request
   │
   ▼
2. sentry-rails creates a TRANSACTION
   (represents the entire request lifecycle)
   │
   ├─▶ 3a. ActiveRecord creates SQL SPANS
   │       (one span per database query)
   │
   ├─▶ 3b. ActionController creates controller SPANS
   │       (processing time, view rendering)
   │
   ├─▶ 3c. HTTP client creates external request SPANS
   │       (API calls to external services)
   │
   └─▶ 3d. Custom code creates custom SPANS
           (your own instrumented operations)
   │
   ▼
4. Transaction completes → sent to Sentry
   │
   ▼
5. Appears in Sentry → Traces dashboard
   (with timing waterfall, span details, and metadata)
```

### What Gets Auto-Instrumented (Zero Code)

`sentry-rails` and `sentry-ruby` automatically instrument:

| Component          | What It Measures                                      |
| ------------------ | ----------------------------------------------------- |
| **HTTP Requests**  | Full request lifecycle (controller → view → response) |
| **SQL Queries**    | Every ActiveRecord query with duration and SQL text   |
| **View Rendering** | ERB template rendering time                           |
| **ActiveJob**      | Background job execution time                         |
| **HTTP Clients**   | Outgoing HTTP calls (Net::HTTP, Faraday, etc.)        |
| **Redis**          | Redis commands (if Redis is configured)               |

---

## Our Setup

### Configuration (`config/initializers/sentry.rb`)

```ruby
Sentry.init do |config|
  config.dsn = ENV.fetch('SENTRY_DSN', nil)

  # ① Enable tracing and set sample rate (1.0 = 100% of requests)
  config.traces_sample_rate = 1.0

  # ② Record HTTP request breadcrumbs
  config.breadcrumbs_logger = %i[active_support_logger http_logger]
end
```

| Config                      | What It Does for Traces                              |
| --------------------------- | ---------------------------------------------------- |
| `config.traces_sample_rate` | Controls what percentage of requests are traced      |
| `config.breadcrumbs_logger` | Records HTTP and ActiveSupport events as breadcrumbs |
| `http_logger`               | Traces outgoing HTTP requests                        |

### Trace Propagation (`app/views/layouts/application.html.erb`)

```erb
<%= Sentry.get_trace_propagation_meta.html_safe %>
```

This line injects trace headers into the HTML `<head>`, enabling **distributed tracing**
between the frontend and backend (if a JavaScript Sentry SDK is also installed).

### Gems Required (`Gemfile`)

```ruby
gem "sentry-ruby"    # Core SDK — provides tracing engine
gem "sentry-rails"   # Rails integration — auto-instruments controllers, queries, jobs
```

---

## Key Concepts

### Transaction

A **transaction** represents a complete operation — usually one HTTP request or one background
job execution.

```
Transaction: GET /dashboard
  Duration: 250ms
  Status: 200 OK
```

### Span

A **span** represents a single operation within a transaction — a database query, a method call,
a template render, etc.

```
Transaction: GET /dashboard (250ms)
 ├── Span: SQL SELECT workers (15ms)
 ├── Span: SQL SELECT work_orders (8ms)
 ├── Span: Render dashboard/index.html.erb (180ms)
 └── Span: SQL SELECT notifications (5ms)
```

### Trace

A **trace** is the complete tree of a transaction + all its spans. The Traces dashboard shows
a list of traces, and clicking one shows the span waterfall.

### Percentiles (p50, p75, p95)

- **p50** — Median: 50% of requests are faster than this
- **p75** — 75% of requests are faster than this
- **p95** — 95% of requests are faster than this (only 5% are slower)

> Rule of thumb: Optimize for **p95**. If your p95 is 2 seconds, 1 in 20 users waits 2+ seconds.

---

## How to Use the Traces Dashboard

### Accessing Traces

1. Go to [sentry.io](https://sentry.io)
2. Select org **st-advisory** → project **ruby-rails**
3. Click **Traces** in the left sidebar

### Dashboard Layout

```
┌──────────────────────────────────────────────────────────────┐
│  Traces                                                      │
│                                                              │
│  [All Projects ▼] [All Envs ▼] [1H ▼]  🔍 Search...        │
│                                                              │
│  Filters: browser.name | user.email | os.name | span.op ... │
│                                                              │
│  Visualize: [count ▼] [spans ▼]                              │
│                                                              │
│  ┌──── count(spans) ─── Bar ─── 1 minute ──────────────┐    │
│  │  █ █ █ █ █ █ █ █ █ █ █ █ █ █ █ █ █ █ █ █ █ █ █ █ █  │    │
│  │  12:40    12:50    1:00    1:10    1:20    1:30       │    │
│  └──────────────────────────────────────────────────────┘    │
│  717 spans                                                   │
│                                                              │
│  [Span Samples] [Trace Samples] [Aggregates]                 │
└──────────────────────────────────────────────────────────────┘
```

### Useful Visualizations

| Visualize Setting  | Shows You                                  |
| ------------------ | ------------------------------------------ |
| `count` + `spans`  | How many operations are happening (volume) |
| `avg` + `duration` | Average time per operation                 |
| `p95` + `duration` | Worst-case performance (95th percentile)   |
| `count` + `errors` | How many traced operations failed          |

### Filtering & Searching

| Filter           | Example                   | Purpose                         |
| ---------------- | ------------------------- | ------------------------------- |
| `span.op`        | `db`, `http.client`, `ui` | Filter by operation type        |
| `is_transaction` | `true`                    | Show only top-level requests    |
| `browser.name`   | `Chrome`                  | Filter by user's browser        |
| `user.email`     | `arya@example.com`        | Find traces for a specific user |
| `os.name`        | `Windows`, `macOS`        | Filter by user's OS             |

### Views

| Tab               | What It Shows                                       |
| ----------------- | --------------------------------------------------- |
| **Span Samples**  | Individual span examples with durations             |
| **Trace Samples** | Full transaction traces you can click into          |
| **Aggregates**    | Grouped statistics (avg duration by endpoint, etc.) |

---

## Reading a Trace Waterfall

When you click on a trace, you see a **waterfall view**:

```
Transaction: POST /payslips/create (1200ms)
├──────────────────────────────────────────────────────┤
│                                                       │
│  ┌─ db ─────┐                                        │
│  │ SELECT    │ 5ms                                   │
│  │ workers   │                                       │
│  └──────────┘                                        │
│    ┌─ db ──────┐                                     │
│    │ SELECT     │ 3ms                                │
│    │ deductions │                                    │
│    └───────────┘                                     │
│      ┌─ app ────────────┐                            │
│      │ calculate_gross   │ 50ms                      │
│      └──────────────────┘                            │
│        ┌─ db ────┐                                   │
│        │ INSERT   │ 8ms                              │
│        │ payslips │                                  │
│        └─────────┘                                   │
│          ┌─ app ──────────────────────────────────┐  │
│          │ PDF Generation                          │  │
│          │ 900ms  ← 🐌 THIS IS YOUR BOTTLENECK    │  │
│          └────────────────────────────────────────┘  │
│                                                  ┌──┐│
│                                                  │2 ││
│                                                  └──┘│
│                                                  enqueue
├──────────────────────────────────────────────────────┤
```

**How to read it:**

- **Horizontal length** = duration (longer = slower)
- **Vertical stacking** = sequence (top to bottom = chronological order)
- **Color coding** = operation type (blue = DB, green = app, orange = HTTP)
- **The widest bar** = your bottleneck

---

## Trace Propagation (Frontend ↔ Backend)

### What We Have

In `app/views/layouts/application.html.erb`:

```erb
<%= Sentry.get_trace_propagation_meta.html_safe %>
```

This outputs something like:

```html
<meta name="sentry-trace" content="abc123-def456-1" />
<meta name="baggage" content="sentry-trace_id=abc123,sentry-release=..." />
```

### Why It Matters

If you add the Sentry JavaScript SDK to the frontend, these meta tags allow Sentry to
**connect frontend and backend traces**:

```
User clicks button (frontend span)
  └── AJAX POST /payslips (frontend span)
        └── POST /payslips (backend transaction)  ← connected!
              ├── SQL SELECT workers
              ├── PayslipCalculator
              └── SQL INSERT payslips
```

Without trace propagation, frontend and backend traces are separate.
With it, you get a **single end-to-end trace** from button click to database insert.

---

## Custom Spans

### Adding Custom Instrumentation

For operations not auto-instrumented, add your own spans:

```ruby
class PayslipService
  def generate(worker)
    # Wrap a slow operation in a custom span
    Sentry.with_child_span(op: "payslip.calculate", description: "Calculate payslip") do |span|
      result = PayslipCalculator.new(worker).calculate

      # Add data to the span for debugging
      span.set_data("worker_id", worker.id)
      span.set_data("deductions_count", worker.deductions.count)

      result
    end
  end
end
```

### When to Add Custom Spans

| Operation                   | Auto-Instrumented? | Need Custom Span? |
| --------------------------- | :----------------: | :---------------: |
| SQL queries                 |         ✅         |        No         |
| HTTP requests               |         ✅         |        No         |
| View rendering              |         ✅         |        No         |
| ActiveJob execution         |         ✅         |        No         |
| Complex business logic      |         ❌         |      **Yes**      |
| PDF generation              |         ❌         |      **Yes**      |
| File I/O operations         |         ❌         |      **Yes**      |
| External API calls (custom) |         ❌         |      **Yes**      |
| Calculation-heavy methods   |         ❌         |      **Yes**      |

### Example: Instrumenting PDF Generation

```ruby
class PayslipPdfService
  def generate(payslip)
    Sentry.with_child_span(op: "pdf.generate", description: "Generate payslip PDF") do |span|
      span.set_data("payslip_id", payslip.id)
      span.set_data("worker_name", payslip.worker.name)

      # Grover PDF generation (this is typically slow)
      html = render_html(payslip)
      pdf = Grover.new(html).to_pdf

      span.set_data("pdf_size_bytes", pdf.bytesize)
      pdf
    end
  end
end
```

---

## Sample Rate Explained

### What Is `traces_sample_rate`?

```ruby
config.traces_sample_rate = 1.0  # Our current setting
```

This controls what **percentage** of requests get traced:

| Value | Meaning                        | Use Case                           |
| ----- | ------------------------------ | ---------------------------------- |
| `1.0` | 100% — every request is traced | Small apps, development, debugging |
| `0.5` | 50% — half of requests         | Medium traffic apps                |
| `0.1` | 10% — one in ten requests      | High traffic apps (cost saving)    |
| `0.0` | 0% — tracing disabled          | Not recommended                    |

### Why It Matters

- **Higher rate** = More data, better visibility, higher Sentry usage/cost
- **Lower rate** = Less data, lower cost, but may miss intermittent performance issues

> **Our setting is `1.0` (100%)** because our app has moderate traffic. If traffic increases
> significantly, consider lowering to `0.5` or `0.1` to manage Sentry quota.

### Dynamic Sampling (Advanced)

For fine-grained control:

```ruby
config.traces_sampler = lambda do |sampling_context|
  transaction_context = sampling_context[:transaction_context]
  op = transaction_context[:op]
  name = transaction_context[:name]

  case name
  when /health_check/  then 0.0   # Never trace health checks
  when /admin/         then 1.0   # Always trace admin actions
  else                      0.5   # 50% for everything else
  end
end
```

---

## Best Practices

### Do

- ✅ Add custom spans for slow business logic (PDF generation, complex calculations)
- ✅ Check the Traces dashboard after deployments for performance regressions
- ✅ Use the `p95` visualization to find worst-case performance
- ✅ Look for N+1 patterns: many small identical SQL spans instead of one batch query
- ✅ Use trace waterfall to identify bottlenecks before optimizing

### Don't

- ❌ Don't set `traces_sample_rate` to `0.0` — you lose all performance visibility
- ❌ Don't add custom spans for trivial operations (< 1ms) — it adds noise
- ❌ Don't ignore consistently slow spans — they compound into bad user experience
- ❌ Don't optimize without data — check the trace first, then optimize

### Performance Red Flags

| Pattern in Trace Waterfall          | Likely Problem                   | Fix                                  |
| ----------------------------------- | -------------------------------- | ------------------------------------ |
| Many small identical SQL spans      | N+1 query                        | Use `includes()` / eager loading     |
| One very long SQL span              | Missing database index           | Add an index                         |
| Long "view rendering" span          | Complex view with too much logic | Move logic to presenters/serializers |
| Long custom span (PDF, calculation) | CPU-intensive operation          | Background job, caching, or optimize |
| Long HTTP client span               | Slow external API                | Timeout, caching, or async           |

---

## Troubleshooting

| Problem                            | Cause                                           | Fix                                                     |
| ---------------------------------- | ----------------------------------------------- | ------------------------------------------------------- |
| No traces appearing                | `traces_sample_rate` is `0.0`                   | Set to `1.0` (or higher than `0`)                       |
| No traces appearing                | `SENTRY_DSN` not set                            | Check `.env` file                                       |
| Traces missing SQL spans           | `sentry-rails` not installed                    | Verify Gemfile has `sentry-rails`                       |
| Very few traces                    | Low sample rate                                 | Increase `traces_sample_rate`                           |
| Frontend-backend traces not linked | Missing trace propagation meta                  | Ensure `Sentry.get_trace_propagation_meta` is in layout |
| Custom spans not appearing         | Not inside a transaction                        | Custom spans only work inside an active transaction     |
| High Sentry usage/cost             | `traces_sample_rate` is `1.0` with high traffic | Lower to `0.5` or `0.1`                                 |

---

## FAQ

**Q: What's the difference between Traces, Issues, and Logs?**

| Feature    | What It Tracks         | Key Question It Answers         |
| ---------- | ---------------------- | ------------------------------- |
| **Issues** | Errors / exceptions    | "What broke?"                   |
| **Logs**   | Informational messages | "What happened?"                |
| **Traces** | Performance / timing   | "How long did it take and why?" |

They work together: an error (Issue) links to the trace showing _what was happening when it broke_,
and the logs show _the messages leading up to it_.

**Q: Does tracing slow down the app?**
Minimal overhead. The SDK adds ~1-2ms per request for instrumentation. With `traces_sample_rate = 1.0`,
every request has this small overhead. At high traffic, lowering the rate reduces even this.

**Q: What does "717 spans" mean in the dashboard?**
A span is a single measured operation (one SQL query, one HTTP call, one method execution).
717 spans in 1 hour means ~12 spans per minute across all requests — a normal amount for
a moderately active app.

**Q: Should I lower the sample rate from 1.0?**
Not yet. At our current traffic level, 100% sampling is fine. Consider lowering it if:

- Sentry shows quota warnings
- The app handles >1000 requests/minute
- You want to reduce costs

**Q: Can I see traces for background jobs?**
Yes. `sentry-rails` automatically creates transactions for ActiveJob executions.
They appear in Traces with `op: "queue.active_job"`.

**Q: How do I find a specific slow request?**

1. Go to Traces
2. Use the search: `user.email is arya@example.com` (or other identifier)
3. Sort by duration (descending)
4. Click on the slowest trace to see the waterfall

---

## References

- [Sentry Performance Monitoring](https://docs.sentry.io/product/performance/)
- [Sentry Traces Explorer](https://docs.sentry.io/product/explore/traces/)
- [sentry-ruby Performance](https://docs.sentry.io/platforms/ruby/tracing/)
- [Custom Instrumentation](https://docs.sentry.io/platforms/ruby/tracing/instrumentation/custom-instrumentation/)
- [Sampling](https://docs.sentry.io/platforms/ruby/tracing/trace-propagation/)
- [Sentry Issues Guide](SENTRY_ISSUES_GUIDE.md) — Error tracking
- [Sentry Logs Guide](SENTRY_LOGS_GUIDE.md) — Log monitoring
- [Sentry Releases Guide](SENTRY_RELEASES_GUIDE.md) — Release tracking
