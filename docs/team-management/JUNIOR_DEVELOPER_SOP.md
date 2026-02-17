# Junior Developer SOP (Standard Operating Procedure)

## Blueprint for Code Quality and Development Workflow

| Field        | Value                             |
| ------------ | --------------------------------- |
| Author       | Team Lead                         |
| Created      | February 2026                     |
| Last Updated | February 2026                     |
| Status       | Active                            |
| Applies To   | All junior developers on the team |

> **This is your bible.** Follow it strictly, especially in your first 3 months.
> If something is unclear, ask the Lead — never guess.

---

## Table of Contents

1. [Environment Setup (Onboarding Checklist)](#chapter-1-environment-setup-onboarding-checklist)
2. [Git Workflow](#chapter-2-git-workflow)
3. [Technical Analysis (Before You Code)](#chapter-3-technical-analysis-before-you-code)
4. [Architecture Rules (Where Does My Code Go?)](#chapter-4-architecture-rules-where-does-my-code-go)
5. [Code Quality Standards](#chapter-5-code-quality-standards)
6. [Testing Standards](#chapter-6-testing-standards)
7. [PR Workflow](#chapter-7-pr-workflow)
8. [Anti-Patterns (Things You Must NEVER Do)](#chapter-8-anti-patterns-things-you-must-never-do)
9. [Daily Workflow Checklist](#chapter-9-daily-workflow-checklist)
10. [Useful Commands Reference](#chapter-10-useful-commands-reference)
11. [Slack Communication Guidelines](#chapter-11-slack-communication-guidelines)

---

## Chapter 1: Environment Setup (Onboarding Checklist)

### 1.1 Required Software

Install everything in order. Check each box when done.

#### System Tools

- [ ] **Git** (latest)

  ```bash
  sudo apt install git
  git --version  # should show 2.40+
  ```

- [ ] **Docker & Docker Compose**

  ```bash
  # Follow official Docker install for your distro:
  # https://docs.docker.com/engine/install/ubuntu/
  docker --version      # should show 24+
  docker compose version # should show 2.20+
  ```

- [ ] **Ruby** (check project's `.ruby-version` file for exact version)

  ```bash
  # Install via rbenv (recommended)
  # https://github.com/rbenv/rbenv
  rbenv install <version>
  rbenv global <version>
  ruby --version
  ```

- [ ] **PostgreSQL** (if running locally without Docker)

  ```bash
  sudo apt install postgresql postgresql-contrib libpq-dev
  psql --version
  ```

- [ ] **Redis** (if running locally without Docker)

  ```bash
  sudo apt install redis-server
  redis-cli ping  # should return PONG
  ```

- [ ] **Node.js** (LTS version)
  ```bash
  # Install via nvm: https://github.com/nvm-sh/nvm
  nvm install --lts
  node --version
  ```

#### Ruby Gems (Global)

- [ ] **Bundler**

  ```bash
  gem install bundler
  bundler --version
  ```

- [ ] **Solargraph** (Ruby language server for VS Code)
  ```bash
  gem install solargraph
  solargraph --version
  ```

---

### 1.2 VS Code Extensions (MANDATORY)

Open VS Code, go to Extensions panel (`Ctrl+Shift+X`), and install all of these:

| Extension                     | ID                             | Purpose                                                       |
| ----------------------------- | ------------------------------ | ------------------------------------------------------------- |
| **Ruby LSP**                  | `Shopify.ruby-lsp`             | Language server — autocomplete, diagnostics, go-to-definition |
| **Solargraph**                | `castwide.solargraph`          | Advanced Ruby autocomplete, documentation                     |
| **RuboCop**                   | `misogi.ruby-rubocop`          | Lint Ruby code in real-time, auto-fix on save                 |
| **ERB Formatter/Beautify**    | `aliariff.vscode-erb-beautify` | Format `.html.erb` files                                      |
| **ESLint**                    | `dbaeumer.vscode-eslint`       | JavaScript linting                                            |
| **Prettier**                  | `esbenp.prettier-vscode`       | Format JS, CSS, JSON, HTML                                    |
| **YAML**                      | `redhat.vscode-yaml`           | YAML syntax, validation                                       |
| **GitLens**                   | `eamodio.gitlens`              | See who changed what line, when, and why                      |
| **ERB**                       | `CraigMaslowski.erb`           | ERB syntax highlighting                                       |
| **Tailwind CSS IntelliSense** | `bradlc.vscode-tailwindcss`    | Tailwind autocomplete (if project uses Tailwind)              |
| **GitHub Copilot**            | `GitHub.copilot`               | AI coding assistant                                           |
| **EditorConfig**              | `EditorConfig.EditorConfig`    | Reads `.editorconfig` for consistent formatting               |
| **endwise**                   | `kaiwood.endwise`              | Auto-close Ruby `do...end`, `if...end`, `def...end`           |
| **Better Comments**           | `aaron-bond.better-comments`   | Highlight TODO, FIXME, NOTE in code                           |

> **Tip:** When you open the project for the first time, VS Code may prompt you to install recommended extensions from `.vscode/extensions.json`. Click **Install All**.

---

### 1.3 VS Code Settings

The project includes shared settings in `.vscode/settings.json`. Key features:

- **Auto-format on save** — RuboCop for Ruby, Prettier for JS/CSS/JSON, ERB Beautify for ERB
- **Trim trailing whitespace** automatically
- **Insert final newline** automatically
- **2-space indentation** for all file types

> **DO NOT override these settings** with your personal preferences. The team must use consistent formatting.

---

### 1.4 Git Hooks Setup

```bash
# Navigate to the project root
cd /path/to/project

# Configure git to use the project's hooks
git config core.hooksPath .githooks

# Make hooks executable
chmod +x .githooks/*

# Verify
git config --get core.hooksPath  # should output: .githooks
```

What the hooks do:

- **pre-commit**: Runs `rubocop -a` before every commit. Blocks commit if there are unfixable violations.
- **pre-push**: Runs `rubocop -a` AND `rails test` before every push. Blocks push if tests fail.

> **Never bypass hooks** with `--no-verify` unless you have explicit Lead approval.

---

### 1.5 Project Setup

```bash
# 1. Clone the repository
git clone <repository-url>
cd <project-name>

# 2. Install dependencies
bundle install

# 3. Setup database
rails db:setup  # creates DB + runs migrations + seeds

# 4. Start the server
# Option A: Docker (recommended)
docker compose up -d

# Option B: Local
bin/dev  # starts Rails + CSS watcher via Procfile.dev

# 5. Verify everything works
rails test      # all tests should pass
rubocop         # should show no offenses (or only minor ones)
```

---

### 1.6 Verification Checklist

Before you start any task, verify ALL of the following:

- [ ] Can access the project repository on GitHub
- [ ] Can run the development server (see the app in browser)
- [ ] Can run `rails test` with all tests passing
- [ ] Can run `rubocop` with no (or minimal) violations
- [ ] VS Code shows Ruby syntax highlighting and autocomplete
- [ ] Git hooks are active (try a test commit — RuboCop should run automatically)
- [ ] Can access the shared Google Sheets task board
- [ ] Slack is installed with all required channels joined
- [ ] Daily standup time is on your calendar

> **If any of the above fails, tell the Lead immediately.** Do not try to work around it.

---

## Chapter 2: Git Workflow

### 2.1 Branch Strategy

```
main (production)
 │
 ├── develop (integration/staging)
 │    │
 │    ├── feature/CA-012-payout-withdrawal    ← Junior A
 │    ├── feature/CA-015-event-categories     ← Junior B
 │    ├── fix/CA-018-order-status-stuck       ← Junior A
 │    └── refactor/CA-020-extract-service     ← Lead
 │
 └── hotfix/CA-099-payment-crash              ← Emergency from main
```

**Rules:**

- **Never push directly to `main` or `develop`**
- All changes go through Pull Requests
- `main` = production code (deployed to live server)
- `develop` = integration branch (latest development)
- Feature/fix branches always branch from `develop`

### 2.2 Branch Naming Convention

```
<type>/<task-id>-<short-description>
```

| Type        | When to Use                          | Example                                   |
| ----------- | ------------------------------------ | ----------------------------------------- |
| `feature/`  | New functionality                    | `feature/CA-012-payout-withdrawal`        |
| `fix/`      | Bug fix                              | `fix/CA-018-order-status-stuck`           |
| `hotfix/`   | Urgent production fix                | `hotfix/CA-099-payment-crash`             |
| `refactor/` | Code improvement, no behavior change | `refactor/CA-020-extract-payment-service` |

**Rules:**

- Always lowercase
- Use hyphens (not underscores or spaces)
- Include the task ID from Google Sheets
- Keep description short (3-5 words)

### 2.3 Step-by-Step: Creating a Branch

```bash
# 1. Make sure you're on develop and up-to-date
git checkout develop
git pull origin develop

# 2. Create your feature branch
git checkout -b feature/CA-012-payout-withdrawal

# 3. Verify you're on the new branch
git branch  # should show * feature/CA-012-payout-withdrawal
```

### 2.4 Commit Message Convention

```
<type>: <short description>
```

**Types:**

| Type        | When to Use              | Example                                             |
| ----------- | ------------------------ | --------------------------------------------------- |
| `feat:`     | New feature              | `feat: add payout withdrawal endpoint`              |
| `fix:`      | Bug fix                  | `fix: resolve N+1 query in orders index`            |
| `refactor:` | Code restructuring       | `refactor: extract payment logic to service object` |
| `chore:`    | Dependencies, config, CI | `chore: update rubocop configuration`               |
| `test:`     | Adding/updating tests    | `test: add model tests for Payout`                  |
| `docs:`     | Documentation            | `docs: update architecture guide`                   |
| `style:`    | Formatting only          | `style: fix indentation in orders controller`       |

**Rules:**

- Start with lowercase after the colon
- Use imperative mood ("add" not "added", "fix" not "fixed")
- Keep the first line under 72 characters
- One commit = one logical change (don't bundle unrelated changes)

### 2.5 Step-by-Step: Making Commits

```bash
# 1. Check what you've changed
git status
git diff

# 2. Stage specific files (preferred) or all changes
git add app/services/payouts/withdrawal_service.rb
git add test/services/payouts/withdrawal_service_test.rb
# OR stage all changes:
git add -A

# 3. Commit with a descriptive message
git commit -m "feat: add payout withdrawal service"

# 4. If you need to amend the last commit (typo in message, forgot a file):
git add <forgotten-file>
git commit --amend  # opens editor, change message if needed
```

### 2.6 Step-by-Step: Pushing and Creating a PR

```bash
# 1. Before pushing, make sure your branch is up-to-date with develop
git fetch origin
git rebase origin/develop

# 2. If there are conflicts during rebase:
#    a. Fix conflicts in the files
#    b. Stage the fixed files: git add <file>
#    c. Continue rebase: git rebase --continue
#    d. If truly stuck: git rebase --abort (and ask Lead for help)

# 3. Push your branch
git push origin feature/CA-012-payout-withdrawal

# 4. Go to GitHub and create a Pull Request
#    - Base: develop
#    - Compare: feature/CA-012-payout-withdrawal
#    - Fill in the PR template (see Chapter 7)
```

### 2.7 Common Git Scenarios

#### I accidentally committed to `develop` instead of my branch

```bash
# If you haven't pushed yet:
git branch feature/CA-012-my-feature   # create branch from current point
git checkout develop
git reset --hard HEAD~1                # undo the commit on develop
git checkout feature/CA-012-my-feature # switch to your branch
```

#### I need to update my branch with latest develop

```bash
git checkout feature/CA-012-my-feature
git fetch origin
git rebase origin/develop
# Fix any conflicts, then:
git push --force-with-lease origin feature/CA-012-my-feature
```

#### I want to undo my last commit (keep changes)

```bash
git reset --soft HEAD~1  # undoes commit, keeps changes staged
```

#### I want to see what changed in a file

```bash
git diff <file>              # unstaged changes
git diff --staged <file>     # staged changes
git log --oneline -10        # last 10 commits
git log --oneline <file>     # commit history for a specific file
```

> **Golden Rule: When in doubt, ask the Lead.** A bad `git reset --hard` or `git push --force` can lose work.

---

## Chapter 3: Technical Analysis (Before You Code)

### 3.1 Why We Do This

**You must write a Technical Analysis before writing any code.**

- Forces you to **think before typing** → fewer rewrites
- Improves **estimation accuracy** → better delivery predictability
- Catches **edge cases early** → higher quality
- Creates a **record of decisions** → future reference

### 3.2 Template

Create a Google Doc for each task. Use this exact template:

```markdown
# Technical Analysis: [Task Name]

## 1. Objective

What are we trying to achieve? What problem does this solve?

## 2. Affected Files / Modules

| File                                               | Action (Create/Modify/Delete) | Description                 |
| -------------------------------------------------- | ----------------------------- | --------------------------- |
| `app/models/payout.rb`                             | Modify                        | Add withdrawal status       |
| `app/services/payouts/withdrawal_service.rb`       | Create                        | Handle withdrawal logic     |
| `db/migrate/xxx_add_withdrawal_status.rb`          | Create                        | Add column to payouts table |
| `test/services/payouts/withdrawal_service_test.rb` | Create                        | Tests for the service       |

## 3. Database Changes

- New tables? (describe schema)
- New columns? (name, type, default, nullable?)
- New indexes? (which columns?)
- Data migration needed? (existing data needs updating?)

## 4. Architecture Approach

Which layers will be used? (Service, Interactor, Form Object, Query Object, etc.)
Why this approach? (Reference the architecture guide)

## 5. Dependencies / Blockers

- External APIs needed?
- Other tasks that must be completed first?
- Data or credentials needed?

## 6. Edge Cases

- What if the input is nil or empty?
- What if the record doesn't exist?
- What if there's a concurrent request?
- What about permission checks?
- What if a related record is deleted?

## 7. Test Plan

- Model tests for: [list validations, associations, scopes]
- Service tests for: [list success path, failure paths]
- Manual testing steps: [step-by-step to verify in browser]

## 8. Estimated Effort

| Subtask                | Estimated Days |
| ---------------------- | -------------- |
| Database migration     | 0.5            |
| Service implementation | 1              |
| Controller + views     | 1              |
| Tests                  | 0.5            |
| Code review + fixes    | 0.5            |
| **Total**              | **3.5 days**   |

## 9. Questions for Lead

Anything unclear? List questions here before starting.
```

### 3.3 Example: Real Technical Analysis

Here's a filled example so you know what a good analysis looks like:

```markdown
# Technical Analysis: Implement Payout Withdrawal Feature

## 1. Objective

Allow organizers to withdraw their payout balance. When an organizer
requests a withdrawal, the system should validate the amount, check
the payout status, and create a withdrawal record.

## 2. Affected Files / Modules

| File                                                            | Action | Description                           |
| --------------------------------------------------------------- | ------ | ------------------------------------- |
| `app/models/payout.rb`                                          | Modify | Add AASM events for withdrawal states |
| `app/services/payouts/withdrawal_service.rb`                    | Create | Validate and process withdrawal       |
| `app/controllers/organizer_dashboard/payouts_controller.rb`     | Modify | Add withdraw action                   |
| `app/views/organizer_dashboard/payouts/_withdraw_form.html.erb` | Create | Withdrawal form partial               |
| `app/policies/organizer_dashboard/payout_policy.rb`             | Modify | Add withdraw? permission              |
| `db/migrate/20260217_add_withdrawn_at_to_payouts.rb`            | Create | Add timestamp column                  |
| `test/models/payout_test.rb`                                    | Modify | Add state transition tests            |
| `test/services/payouts/withdrawal_service_test.rb`              | Create | Service tests                         |
| `config/routes.rb`                                              | Modify | Add withdraw route                    |

## 3. Database Changes

- Add `withdrawn_at` (datetime, nullable) to `payouts` table
- Add index on `withdrawn_at` for reporting queries
- No data migration needed (new column, defaults to nil)

## 4. Architecture Approach

- **Service** (`Payouts::WithdrawalService`) — single operation: validate + process withdrawal
- NOT an Interactor because there's only one step (no orchestration needed)
- Returns `Success(payout)` on success, `Failure(errors)` on failure
- Controller calls the service and handles the result

## 5. Dependencies / Blockers

- Depends on: AASM states already being defined on Payout model ✅
- Depends on: Organizer dashboard namespace being set up ✅
- No external API needed for now (bank transfer is manual)

## 6. Edge Cases

- Payout amount is 0 → reject with error
- Payout is already withdrawn → reject with error
- Payout is still "pending" (not approved) → reject with error
- Organizer doesn't own this payout → Pundit policy blocks it
- Concurrent withdrawal requests → AASM state check handles this

## 7. Test Plan

- Model tests: state transitions (pending → approved → withdrawn)
- Service tests: success path, amount=0 rejection, already-withdrawn rejection
- Manual: login as organizer → go to payouts → click withdraw → verify status

## 8. Estimated Effort

| Subtask                            | Estimated Days |
| ---------------------------------- | -------------- |
| Database migration + model changes | 0.5            |
| Service implementation             | 0.5            |
| Controller + views + routes        | 0.5            |
| Policy update                      | 0.25           |
| Tests                              | 0.5            |
| Code review + fixes                | 0.25           |
| **Total**                          | **2.5 days**   |

## 9. Questions for Lead

- Should we send an email notification when withdrawal is processed?
- What's the minimum withdrawal amount?
```

### 3.4 Estimation Tips

| Rule                                     | Explanation                                   |
| ---------------------------------------- | --------------------------------------------- |
| **Never estimate without breaking down** | Split into subtasks first, then estimate each |
| **Add 20-30% buffer for testing**        | Tests always take longer than you think       |
| **Add 0.5 day for code review cycle**    | You'll get feedback, need to make changes     |
| **Maximum 3 days per subtask**           | If a subtask > 3 days, break it down further  |
| **Double your first instinct**           | Beginners consistently underestimate by 50%   |
| **Track actual vs estimated**            | Over time, you'll calibrate your estimates    |

### 3.5 Workflow

```
1. Lead assigns task in Google Sheets → status: "Backlog"
2. You pick the task → change status to "Analysis"
3. You write Technical Analysis in Google Doc
4. Paste the Google Doc link in the Google Sheets "Technical Analysis Link" column
5. Ping Lead on Slack: "TA ready for review: [task name] [link]"
6. Lead reviews:
   ✅ APPROVED → Change status to "In Progress", start coding
   ❌ NEEDS REVISION → Lead gives feedback, you revise, re-submit
```

---

## Chapter 4: Architecture Rules (Where Does My Code Go?)

### 4.1 The Decision Flowchart

**Before writing any code, ask yourself:**

```
Is it a database query?
  └── YES → Query Object (app/queries/)

Is it form validation / parameter handling?
  └── YES → Form Object (app/forms/)

Is it a single business operation?
  └── YES → Service (app/services/)

Does it orchestrate multiple services/queries?
  └── YES → Interactor (app/interactors/)

Is it display/formatting logic for a single object?
  └── YES → Decorator (app/decorators/)

Is it complex view logic involving multiple objects?
  └── YES → Presenter (app/presenters/)

Is it authorization logic?
  └── YES → Policy (app/policies/)

Is it shared behavior across multiple classes?
  └── YES → Concern (app/models/concerns/ or app/controllers/concerns/)

Is it a controller action?
  └── YES → Keep it THIN. Delegate to the layers above.
```

> **When in doubt, ask the Lead.** It's better to ask than to put code in the wrong place.

### 4.2 Architecture Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                        CONTROLLER                                │
│  Receives HTTP request → Delegates to Interactor/Service →       │
│  Handles result → Returns response                               │
│  MAX 5-7 LINES PER ACTION                                        │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                        INTERACTOR                                │
│  Orchestrates a use case (coordinates multiple services)         │
│  Uses Do notation for railway-oriented programming               │
└─────────────────────────────────────────────────────────────────┘
                              │
              ┌───────────────┼───────────────┐
              ▼               ▼               ▼
┌──────────────────┐ ┌──────────────┐ ┌──────────────────┐
│     SERVICE      │ │    QUERY     │ │      FORM        │
│  Single business │ │  Database    │ │  Validation &    │
│  operation       │ │  queries     │ │  sanitization    │
└──────────────────┘ └──────────────┘ └──────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                         MODEL                                    │
│  Data persistence, associations, basic validations               │
└─────────────────────────────────────────────────────────────────┘
              │                               │
              ▼                               ▼
┌──────────────────┐              ┌──────────────────┐
│    DECORATOR     │              │    PRESENTER     │
│  Display logic   │              │  Complex view    │
│  (single object) │              │  (multi-object)  │
└──────────────────┘              └──────────────────┘
```

### 4.3 Controller — The Thin Entry Point

**Purpose:** Receive HTTP requests, delegate to services/interactors, return responses.

**Rule: MAX 5-7 lines per action.** If your controller action is longer, you're doing too much.

```ruby
# ✅ GOOD — Thin controller, delegates to interactor
class OrganizerDashboard::PayoutsController < OrganizerDashboard::BaseController
  def create
    result = OrganizerRequests::CreateInteractor.call(
      user: current_user,
      attributes: organizer_params
    )

    case result
    in Success(organizer)
      redirect_to dashboard_path, notice: "Request submitted!"
    in Failure(errors)
      @errors = errors
      render :new, status: :unprocessable_entity
    end
  end
end
```

```ruby
# ❌ BAD — Fat controller, business logic in the controller
class OrganizerDashboard::PayoutsController < OrganizerDashboard::BaseController
  def create
    @organizer = Organizer.new(organizer_params)
    @organizer.user = current_user
    @organizer.status = :pending

    if current_user.organizer.present?
      flash[:alert] = "You already have an organizer"
      redirect_to dashboard_path and return
    end

    if @organizer.save
      UserMailer.organizer_request(@organizer).deliver_later
      AuditLog.create(action: "organizer_request", user: current_user)
      redirect_to dashboard_path, notice: "Request submitted!"
    else
      render :new, status: :unprocessable_entity
    end
  end
end
```

### 4.4 Service — Single Business Operation

**Purpose:** Encapsulate ONE business operation. Returns `Success` or `Failure`.

**When to use:**

- Logic that doesn't belong in a model
- Coordinates between multiple models
- Has side effects (emails, API calls, file operations)
- Complex validation logic

**Base class:**

```ruby
# app/services/application_service.rb
class ApplicationService
  include Dry::Monads[:result, :do]

  def self.call(...)
    new(...).call
  end

  def call
    raise NotImplementedError, "#{self.class.name} must implement #call"
  end
end
```

**Real example from this project:**

```ruby
# app/services/organizer_requests/creation_service.rb
module OrganizerRequests
  class CreationService < ApplicationService
    def initialize(user:, attributes:)
      @user = user
      @attributes = attributes
    end

    def call
      return Failure(["User is required"]) if @user.nil?

      organizer = build_organizer

      if organizer.save
        Success(organizer)
      else
        Failure(organizer.errors.full_messages)
      end
    end

    private

    attr_reader :user, :attributes

    def build_organizer
      Organizer.new(attributes).tap do |organizer|
        organizer.user = user
        organizer.status = :pending
      end
    end
  end
end
```

**Template for creating a new service:**

```ruby
# app/services/<namespace>/<name>_service.rb
module <Namespace>
  class <Name>Service < ApplicationService
    # @param param1 [Type] Description
    # @param param2 [Type] Description
    def initialize(param1:, param2:)
      @param1 = param1
      @param2 = param2
    end

    # @return [Dry::Monads::Result] Success(data) or Failure(errors)
    def call
      # Validate inputs
      return Failure(["Error message"]) if @param1.nil?

      # Do the work
      result = do_something

      # Return result
      if result
        Success(result)
      else
        Failure(["Something went wrong"])
      end
    end

    private

    attr_reader :param1, :param2

    def do_something
      # Business logic here
    end
  end
end
```

### 4.5 Interactor — Orchestrate Multiple Steps

**Purpose:** Orchestrate a **use case** that involves multiple steps. Each step is a service, query, or operation. If any step fails, the whole chain stops.

**When to use:**

- Multiple services need to run in sequence
- You need railway-oriented programming (fail fast)
- The use case has 2+ distinct steps

**Real example from this project:**

```ruby
# app/interactors/organizer_requests/create_interactor.rb
module OrganizerRequests
  class CreateInteractor < ApplicationInteractor
    def call(params = {})
      user = params[:user]
      attributes = params[:attributes] || {}

      # Step 1: Check eligibility (yield unwraps Success or short-circuits on Failure)
      yield check_eligibility(user)

      # Step 2: Create organizer
      organizer = yield create_organizer(user, attributes)

      # All steps passed!
      Success(organizer)
    end

    private

    def check_eligibility(user)
      eligibility = EligibilityQuery.new(user).call

      if eligibility.eligible?
        Success(eligibility)
      else
        Failure([eligibility.message])
      end
    end

    def create_organizer(user, attributes)
      CreationService.call(user: user, attributes: attributes)
    end
  end
end
```

**How `yield` works (Railway-Oriented Programming):**

```
Step 1: check_eligibility
  ├── Success → unwrap value, continue to Step 2
  └── Failure → STOP HERE, return Failure immediately

Step 2: create_organizer
  ├── Success → unwrap value, continue to Step 3
  └── Failure → STOP HERE, return Failure immediately

Step 3: Success(organizer) → final result
```

Think of it like a train on rails:

- **Success track:** Train keeps going to the next station
- **Failure track:** Train gets diverted immediately, skips all remaining stations

### 4.6 Query Object — Database Queries

**Purpose:** Encapsulate complex database queries. Keeps models clean.

**When to use:**

- Query is more than a simple `where` clause
- Query is reused in multiple places
- Query needs to be composable (chain with other queries)

**Base class:**

```ruby
# app/queries/application_query.rb
class ApplicationQuery
  include Dry::Monads[:result]

  def initialize(relation = nil)
    @relation = relation || default_relation
  end

  def call
    raise NotImplementedError
  end

  private

  attr_reader :relation

  def default_relation
    raise NotImplementedError, "Define default_relation in subclass"
  end
end
```

**Example:**

```ruby
# app/queries/events/active_events_query.rb
module Events
  class ActiveEventsQuery < ApplicationQuery
    def initialize(relation = nil, filters: {})
      super(relation)
      @filters = filters
    end

    def call
      result = relation
        .where(status: :active)
        .where("start_date >= ?", Date.current)

      result = result.where(category_id: @filters[:category]) if @filters[:category].present?
      result = result.order(start_date: :asc)

      result
    end

    private

    def default_relation
      Event.all
    end
  end
end

# Usage:
# events = Events::ActiveEventsQuery.new(filters: { category: 5 }).call
# events = Events::ActiveEventsQuery.new(current_user.events, filters: {}).call  # scoped
```

### 4.7 Form Object — Validation & Parameter Handling

**Purpose:** Handle form validation, type coercion, and data transformation. Use for complex forms.

**When to use:**

- Form doesn't map 1-to-1 to a single model
- Complex validation logic
- Multiple models need to be created from one form
- Virtual attributes (not persisted)

**Base class:**

```ruby
# app/forms/application_form.rb
class ApplicationForm
  include ActiveModel::Model
  include ActiveModel::Attributes
  include ActiveModel::Validations
  include Dry::Monads[:result]

  def initialize(attributes = {})
    super(attributes.to_h.symbolize_keys.slice(*self.class.attribute_names.map(&:to_sym)))
  end

  def save
    return false unless valid?
    persist
    true
  rescue StandardError => e
    errors.add(:base, e.message)
    false
  end

  def to_result
    if save
      Success(@persisted_record)
    else
      Failure(errors.full_messages)
    end
  end

  private

  def persist
    raise NotImplementedError
  end
end
```

**Example:**

```ruby
# app/forms/organizer_requests/form.rb
module OrganizerRequests
  class Form < ApplicationForm
    attribute :name, :string
    attribute :email, :string
    attribute :phone, :string
    attribute :description, :string

    validates :name, presence: true, length: { minimum: 3, maximum: 100 }
    validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
    validates :phone, presence: true
    validates :description, presence: true, length: { minimum: 20 }

    private

    def persist
      @persisted_record = Organizer.create!(
        name: name,
        email: email,
        phone: phone,
        description: description
      )
    end
  end
end

# Usage:
# form = OrganizerRequests::Form.new(params[:organizer_request])
# if form.save
#   redirect_to success_path
# else
#   render :new  # form.errors available
# end
```

### 4.8 Decorator — Display Logic for Single Object

**Purpose:** Add display/formatting methods to an object without modifying the original model.

**When to use:**

- Formatting dates, currencies, status labels
- Computing display-only values
- Logic that belongs in the view layer but is too complex for a helper

**Base class:**

```ruby
# app/decorators/application_decorator.rb
class ApplicationDecorator < SimpleDelegator
  def initialize(object)
    super(object)
    @object = object
  end

  def object
    __getobj__
  end

  alias decorated_object object

  def helpers
    ApplicationController.helpers
  end

  alias h helpers
end
```

**Example:**

```ruby
# app/decorators/organizer_decorator.rb
class OrganizerDecorator < ApplicationDecorator
  def display_name
    name.present? ? name : "Unnamed Organizer"
  end

  def formatted_created_at
    object.created_at.strftime("%B %d, %Y")
  end

  def status_badge
    case object.status
    when "approved"
      h.content_tag(:span, "Approved", class: "badge bg-success")
    when "pending"
      h.content_tag(:span, "Pending", class: "badge bg-warning")
    when "rejected"
      h.content_tag(:span, "Rejected", class: "badge bg-danger")
    end
  end

  def avatar_url
    if object.avatar.attached?
      h.url_for(object.avatar)
    else
      "default-avatar.png"
    end
  end
end

# Usage in controller:
# @organizer = OrganizerDecorator.new(@organizer)
#
# Usage in view:
# @organizer.display_name         # Decorator method
# @organizer.email                # Delegates to original object
# @organizer.status_badge         # Returns HTML badge
```

### 4.9 Policy — Authorization

**Purpose:** Determine whether a user is allowed to perform an action. Uses Pundit.

**How it works in this project:**

- Permission code format: `namespace.resource.action`
- Example: `dashboard.events.create`, `admin.users.destroy`
- User has permissions through roles → roles_permissions join table

```ruby
# app/policies/application_policy.rb
class ApplicationPolicy
  attr_reader :user, :record

  def initialize(user, record)
    @user = user
    @record = record
  end

  def index?
    user.has_permission?(build_permission_code("index"))
  end

  def show?
    user.has_permission?(build_permission_code("show"))
  end

  def create?
    user.has_permission?(build_permission_code("create"))
  end

  def update?
    user.has_permission?(build_permission_code("update"))
  end

  def destroy?
    user.has_permission?(build_permission_code("destroy"))
  end

  private

  def build_permission_code(action)
    "#{permission_resource}.#{action}"
  end

  def permission_resource
    raise NotImplementedError, "Subclass must define permission_resource"
  end
end
```

**Example:**

```ruby
# app/policies/organizer_dashboard/payout_policy.rb
module OrganizerDashboard
  class PayoutPolicy < ApplicationPolicy
    def withdraw?
      user.has_permission?("organizer_dashboard.payouts.withdraw")
    end

    private

    def permission_resource
      "organizer_dashboard.payouts"
    end
  end
end

# Usage in controller:
# authorize @payout          # checks the action matching the controller action
# authorize @payout, :withdraw?  # checks a specific action
```

### 4.10 File Naming & Directory Convention

```
app/
├── services/
│   ├── application_service.rb                    # Base class
│   └── organizer_requests/                       # Namespace = domain
│       └── creation_service.rb                   # Descriptive action name
│
├── interactors/
│   ├── application_interactor.rb
│   └── organizer_requests/
│       └── create_interactor.rb
│
├── queries/
│   ├── application_query.rb
│   └── events/
│       └── active_events_query.rb
│
├── forms/
│   ├── application_form.rb
│   └── organizer_requests/
│       └── form.rb
│
├── decorators/
│   ├── application_decorator.rb
│   └── organizer_decorator.rb
│
├── presenters/
│   └── application_presenter.rb
│
└── policies/
    ├── application_policy.rb
    ├── admin/
    │   └── user_policy.rb
    └── organizer_dashboard/
        └── payout_policy.rb
```

**Naming rules:**

- File names: `snake_case` (e.g., `creation_service.rb`)
- Class names: `CamelCase` (e.g., `CreationService`)
- Directories: `snake_case` matching the Ruby module namespace
- Services end with `Service`, Queries end with `Query`, etc.

---

## Chapter 5: Code Quality Standards

### 5.1 RuboCop — Your First Line of Defense

RuboCop is a Ruby linter that enforces coding style. It runs automatically:

- **On save** (VS Code auto-fix)
- **On commit** (pre-commit hook)
- **On push** (pre-push hook)
- **On CI** (GitHub Actions)

Most issues are auto-fixed. For issues that can't be auto-fixed, RuboCop tells you what to change.

```bash
# Run RuboCop manually
rubocop                    # check all files
rubocop -a                 # auto-fix what it can
rubocop app/services/      # check specific directory
rubocop app/models/user.rb # check specific file
```

### 5.2 Naming Conventions

| Type              | Convention                         | Example                                    |
| ----------------- | ---------------------------------- | ------------------------------------------ |
| Variables         | `snake_case`                       | `user_name`, `total_amount`                |
| Methods           | `snake_case`                       | `calculate_total`, `find_by_email`         |
| Classes           | `CamelCase`                        | `PayoutService`, `UserDecorator`           |
| Modules           | `CamelCase`                        | `OrganizerRequests`, `Admin`               |
| Constants         | `SCREAMING_SNAKE_CASE`             | `MAX_RETRY_COUNT`, `DEFAULT_CURRENCY`      |
| Files             | `snake_case`                       | `payout_service.rb`, `user_decorator.rb`   |
| Database tables   | `snake_case`, plural               | `users`, `payment_methods`, `order_items`  |
| Database columns  | `snake_case`                       | `first_name`, `created_at`, `total_amount` |
| Boolean methods   | End with `?`                       | `active?`, `paid?`, `can_withdraw?`        |
| Dangerous methods | End with `!`                       | `save!`, `delete!`, `process!`             |
| Predicate columns | Start with `is_` or just adjective | `active`, `verified`, `published`          |

### 5.3 Method Length

**Rule: Maximum 10-15 lines per method.** If a method is longer, extract parts into private methods.

```ruby
# ❌ BAD — Method is too long, does too many things
def process_order
  # validate input (5 lines)
  # calculate total (8 lines)
  # apply discount (6 lines)
  # create order (4 lines)
  # send email (3 lines)
  # update inventory (5 lines)
end

# ✅ GOOD — Each method does one thing
def process_order
  validate_input
  total = calculate_total
  total = apply_discount(total)
  order = create_order(total)
  send_confirmation(order)
  update_inventory(order)
end

private

def validate_input
  # 3-5 lines
end

def calculate_total
  # 3-5 lines
end
```

### 5.4 Return Types — dry-monads

**Rule: All Services and Interactors MUST return `Success` or `Failure`.**

```ruby
# ✅ GOOD — Explicit Success/Failure
def call
  if user.save
    Success(user)
  else
    Failure(user.errors.full_messages)
  end
end

# ❌ BAD — Raises exceptions for expected business failures
def call
  raise "User is invalid" unless user.valid?
  user.save!
  user
end

# ❌ BAD — Returns mixed types (sometimes object, sometimes nil, sometimes array)
def call
  return nil if user.nil?
  return user.errors if user.invalid?
  user.save
  user
end
```

**When to raise exceptions vs return Failure:**

- `Failure()` → Expected business failures (validation failed, not authorized, record not found)
- `raise` → Unexpected system errors (database down, file system error, bug)

### 5.5 Controller Pattern

Controllers handle the HTTP layer only. Use this pattern consistently:

```ruby
def create
  result = SomeService.call(params: resource_params)

  case result
  in Success(record)
    redirect_to record_path(record), notice: "Created successfully"
  in Failure(errors)
    @errors = errors
    render :new, status: :unprocessable_entity
  end
end
```

### 5.6 Strong Parameters

**Rule: ALWAYS use strong parameters. Never use `params` directly.**

```ruby
# ✅ GOOD
def user_params
  params.require(:user).permit(:name, :email, :phone)
end

# ❌ BAD — Never do this
User.create(params[:user])
User.create(params.permit!)
```

### 5.7 Database Best Practices

| Rule                                             | Why             | Example                                                    |
| ------------------------------------------------ | --------------- | ---------------------------------------------------------- |
| Always add index on foreign keys                 | Performance     | `add_index :orders, :user_id`                              |
| Migrations must be reversible                    | Rollback safety | Use `add_column`/`remove_column`, not raw SQL              |
| Never modify a merged migration                  | Data integrity  | Create a new migration instead                             |
| Use `null: false` for required columns           | Data integrity  | `add_column :users, :name, :string, null: false`           |
| Use `default:` for columns with obvious defaults | Consistency     | `add_column :orders, :status, :string, default: "pending"` |
| Large data changes go in a separate migration    | Deployability   | Never mix schema + data changes                            |

**Migration example:**

```ruby
class AddWithdrawnAtToPayouts < ActiveRecord::Migration[8.0]
  def change
    add_column :payouts, :withdrawn_at, :datetime
    add_index :payouts, :withdrawn_at
  end
end
```

### 5.8 N+1 Query Detection

The project uses the **Bullet** gem to detect N+1 queries. When you load a page and see a Bullet popup or log warning, FIX IT.

```ruby
# ❌ BAD — N+1 query (1 query for events, then 1 query per event for organizer)
@events = Event.all
# In view: event.organizer.name  # N+1!

# ✅ GOOD — Eager load associations
@events = Event.includes(:organizer).all
# In view: event.organizer.name  # No N+1!

# ✅ GOOD — For multiple associations
@events = Event.includes(:organizer, :category, :event_type).all
```

### 5.9 Things That Must NEVER Be in Committed Code

```ruby
# ❌ NEVER commit these:
binding.pry         # debugger breakpoint
debugger            # debugger breakpoint
byebug             # debugger breakpoint
puts "debug: ..."  # debug output
pp some_variable   # debug output
p some_variable    # debug output
Rails.logger.debug "TODO: remove this"  # temporary logging
sleep 5            # temporary delay
```

> **Tip:** Before committing, always do `git diff` and scan for these. The pre-commit hook catches some of these, but not all.

---

## Chapter 6: Testing Standards

### 6.1 When to Write Tests

| What                                                            | Must Test?  | Priority      |
| --------------------------------------------------------------- | ----------- | ------------- |
| **Models** — validations, associations, scopes, callbacks       | YES         | High          |
| **Services** — success path, failure paths, edge cases          | YES         | High          |
| **Interactors** — full use case flow, failure at each step      | YES         | High          |
| **Query Objects** — returns correct results, handles empty data | YES         | Medium        |
| **Form Objects** — validation, persistence                      | YES         | Medium        |
| **Controllers** — HTTP responses, authorization                 | Recommended | Medium        |
| **System tests** — full user flows in browser                   | Recommended | Low (for now) |

### 6.2 Test Structure

Every test follows the same pattern:

```
Setup →  Exercise →  Verify  →  (Teardown)
  │          │          │            │
  │          │          │            └── Automatic in Minitest
  │          │          └── assert / assert_not / assert_equal
  │          └── Call the method being tested
  └── Prepare data (fixtures, variables)
```

### 6.3 Model Test Template

```ruby
# test/models/payout_test.rb
require "test_helper"

class PayoutTest < ActiveSupport::TestCase
  def setup
    @payout = payouts(:approved_payout)  # fixture reference
  end

  # --- Validations ---

  test "should be valid with valid attributes" do
    assert @payout.valid?
  end

  test "should require amount" do
    @payout.amount = nil
    assert_not @payout.valid?
    assert_includes @payout.errors[:amount], "can't be blank"
  end

  test "should require positive amount" do
    @payout.amount = -100
    assert_not @payout.valid?
    assert_includes @payout.errors[:amount], "must be greater than 0"
  end

  # --- Associations ---

  test "should belong to organizer" do
    assert_respond_to @payout, :organizer
    assert_instance_of Organizer, @payout.organizer
  end

  test "should have many payout_items" do
    assert_respond_to @payout, :payout_items
  end

  # --- Scopes ---

  test "scope: approved returns only approved payouts" do
    approved = Payout.approved
    approved.each do |payout|
      assert_equal "approved", payout.status
    end
  end

  # --- State Machine (AASM) ---

  test "can transition from pending to approved" do
    payout = payouts(:pending_payout)
    assert payout.may_approve?
    payout.approve!
    assert_equal "approved", payout.status
  end

  test "cannot transition from pending to withdrawn directly" do
    payout = payouts(:pending_payout)
    assert_not payout.may_withdraw?
  end
end
```

### 6.4 Service Test Template

```ruby
# test/services/organizer_requests/creation_service_test.rb
require "test_helper"

class OrganizerRequests::CreationServiceTest < ActiveSupport::TestCase
  def setup
    @user = users(:regular_user)
    @valid_attributes = { name: "My Org", description: "Test description" }
  end

  # --- Success Path ---

  test "succeeds with valid user and attributes" do
    result = OrganizerRequests::CreationService.call(
      user: @user,
      attributes: @valid_attributes
    )

    assert result.success?
    assert_instance_of Organizer, result.value!
    assert_equal "My Org", result.value!.name
    assert_equal "pending", result.value!.status
  end

  # --- Failure Paths ---

  test "fails when user is nil" do
    result = OrganizerRequests::CreationService.call(
      user: nil,
      attributes: @valid_attributes
    )

    assert result.failure?
    assert_includes result.failure, "User is required"
  end

  test "fails when organizer attributes are invalid" do
    result = OrganizerRequests::CreationService.call(
      user: @user,
      attributes: { name: "" }  # invalid: blank name
    )

    assert result.failure?
    assert result.failure.any? { |e| e.include?("Name") }
  end

  # --- Edge Cases ---

  test "does not create organizer on failure" do
    assert_no_difference "Organizer.count" do
      OrganizerRequests::CreationService.call(
        user: nil,
        attributes: @valid_attributes
      )
    end
  end

  test "creates exactly one organizer on success" do
    assert_difference "Organizer.count", 1 do
      OrganizerRequests::CreationService.call(
        user: @user,
        attributes: @valid_attributes
      )
    end
  end
end
```

### 6.5 Test Naming Convention

```ruby
# Format: test "<behavior being tested>"

# ✅ GOOD — Descriptive, tells you what's expected
test "should require amount to be positive"
test "succeeds with valid user and attributes"
test "fails when user is nil"
test "scope: approved returns only approved payouts"

# ❌ BAD — Vague, doesn't tell you what's expected
test "test create"
test "validation"
test "it works"
```

### 6.6 Running Tests

```bash
# Run ALL tests
rails test

# Run a specific test file
rails test test/models/user_test.rb

# Run a specific test by line number
rails test test/models/user_test.rb:42

# Run all model tests
rails test test/models/

# Run all service tests
rails test test/services/

# Run tests in Docker
docker compose exec web rails test
```

### 6.7 Fixtures

Fixtures are sample data defined in YAML files. They live in `test/fixtures/`.

```yaml
# test/fixtures/users.yml
admin:
  name: "Admin User"
  email: "admin@example.com"
  encrypted_password: <%= Devise::Encryptor.digest(User, 'password123') %>

regular_user:
  name: "Regular User"
  email: "user@example.com"
  encrypted_password: <%= Devise::Encryptor.digest(User, 'password123') %>
```

```yaml
# test/fixtures/payouts.yml
pending_payout:
  organizer: org_one # references fixtures/organizers.yml
  amount: 500000
  status: pending

approved_payout:
  organizer: org_one
  amount: 750000
  status: approved
```

**Rules:**

- Use descriptive fixture names (not `one`, `two`)
- Keep fixtures minimal — only required attributes
- Reference other fixtures by name (not hardcoded IDs)

---

## Chapter 7: PR Workflow

### 7.1 Step-by-Step: Creating a PR

1. **Push your branch** (see Chapter 2.6)
2. **Go to GitHub** → your branch → click "Create Pull Request"
3. **Base branch:** `develop` (never directly to `main`)
4. **Fill in the PR template** — every checkbox must be answered
5. **Copy the PR link** to Google Sheets (PR Link column)
6. **Post the PR link** in `#code-review` Slack channel
7. **Update Google Sheets** status to "In Review"
8. **Wait for Lead review** — use the waiting time productively (start analysis for next task)

### 7.2 PR Template Checklist

When you create a PR, GitHub will auto-fill this template. Fill in EVERY field:

```markdown
## Description

Briefly describe what this PR does and why.

## Related Task

- Task: [link to Google Sheets row or task reference]
- Technical Analysis: [link to Google Doc]

## Type of Change

- [ ] Feature / Bug Fix / Refactor / Chore / Hotfix

## Screenshots / Demo

[If UI changes, add before/after screenshots]

## Checklist

- [ ] Technical Analysis was approved by Lead
- [ ] Branch follows naming convention
- [ ] Commits follow conventional format
- [ ] RuboCop passes with no new violations
- [ ] No binding.pry / debugger / puts left
- [ ] No N+1 queries (Bullet clean)
- [ ] Migrations are reversible
- [ ] Tests written and passing
- [ ] Manually tested on local
- [ ] Self-reviewed my own code
- [ ] Google Sheets status updated to "In Review"
```

### 7.3 Self-Review Before Requesting Lead Review

Before submitting your PR for review, do this self-review:

```
□ Read your own diff on GitHub from top to bottom
□ Check: is there any debug code left? (binding.pry, puts, pp)
□ Check: did I follow the architecture rules? (code in the right layer?)
□ Check: are there any hardcoded values that should be constants?
□ Check: did I add tests for the new/changed code?
□ Check: are my commit messages clean and descriptive?
□ Run: rubocop -a (should pass clean)
□ Run: rails test (should all pass)
□ Manually test the feature in the browser
```

### 7.4 Responding to Review Feedback

When the Lead leaves comments on your PR:

1. **Read all comments** before starting to fix anything
2. **Ask questions** if you don't understand the feedback — never guess
3. **Make the fixes** in new commits (don't force-push during review)
4. **Reply to each comment** explaining what you changed, or ask for clarification
5. **Request re-review** when all feedback is addressed

```
Lead: "This should be in a Service, not the controller"
You: "Moved to app/services/payouts/withdrawal_service.rb in commit abc123. Let me know if the approach looks correct."
```

### 7.5 Definition of Done

A task is DONE when ALL of these are true:

- [ ] Code is merged to `develop`
- [ ] Reviewed and approved by Lead
- [ ] All tests pass (CI green)
- [ ] RuboCop clean (CI green)
- [ ] Manually tested
- [ ] Google Sheets updated: status = "Done", actual days filled in
- [ ] PR link saved in Google Sheets

---

## Chapter 8: Anti-Patterns (Things You Must NEVER Do)

### 8.1 Business Logic in Controllers

```ruby
# ❌ NEVER — Fat controller with business logic
class OrdersController < ApplicationController
  def create
    @order = Order.new(order_params)
    @order.user = current_user
    @order.total = calculate_total(order_params)
    @order.tax = @order.total * 0.11
    @order.status = "pending"

    if @order.total > 1_000_000
      @order.discount = @order.total * 0.1
      @order.total -= @order.discount
    end

    if @order.save
      OrderMailer.confirmation(@order).deliver_later
      InventoryService.deduct(@order)
      redirect_to @order
    else
      render :new
    end
  end
end

# ✅ CORRECT — Thin controller, delegates to interactor
class OrdersController < ApplicationController
  def create
    result = Orders::CreateInteractor.call(
      user: current_user,
      attributes: order_params
    )

    case result
    in Success(order)
      redirect_to order, notice: "Order placed!"
    in Failure(errors)
      @errors = errors
      render :new, status: :unprocessable_entity
    end
  end
end
```

### 8.2 Skipping Validations

```ruby
# ❌ NEVER — Bypasses all validations
user.save(validate: false)
User.insert_all(records)  # skips validations AND callbacks

# ✅ CORRECT — Let validations run
user.save    # returns false on failure
user.save!   # raises ActiveRecord::RecordInvalid on failure
```

### 8.3 Raw SQL Without Query Object

```ruby
# ❌ NEVER — Raw SQL inline in controller or model
User.where("created_at > ? AND status = ? AND role_id IN (?)", 1.week.ago, "active", [1, 2, 3])

# ✅ CORRECT — Use a Query Object
class Users::RecentActiveQuery < ApplicationQuery
  def call
    relation
      .where(status: :active)
      .where("created_at > ?", 1.week.ago)
      .joins(:roles)
      .where(roles: { id: [1, 2, 3] })
  end

  private

  def default_relation
    User.all
  end
end
```

### 8.4 Pushing Directly to Main/Develop

```bash
# ❌ NEVER
git push origin main
git push origin develop

# ✅ CORRECT
git push origin feature/CA-012-my-feature  # then create PR
```

### 8.5 Modifying Merged Migrations

```ruby
# ❌ NEVER — Editing a migration that's already been merged and run
# If you realize add_column was wrong, DON'T change the old migration

# ✅ CORRECT — Create a NEW migration to fix it
rails generate migration RemoveWrongColumnFromUsers wrong_column:string
rails generate migration AddCorrectColumnToUsers correct_column:integer
```

### 8.6 Hardcoded Values

```ruby
# ❌ BAD — Magic numbers and hardcoded strings
def calculate_tax(amount)
  amount * 0.11
end

def max_tickets
  100
end

# ✅ GOOD — Use constants
TAX_RATE = 0.11
MAX_TICKETS_PER_EVENT = 100

def calculate_tax(amount)
  amount * TAX_RATE
end

def max_tickets
  MAX_TICKETS_PER_EVENT
end
```

### 8.7 God Models

```ruby
# ❌ BAD — Model with 500+ lines, does everything
class User < ApplicationRecord
  # validations (30 lines)
  # associations (20 lines)
  # scopes (40 lines)
  # callbacks (30 lines)
  # instance methods (300 lines)
  # class methods (100 lines)

  def calculate_total_revenue
    # 20 lines of business logic
  end

  def generate_report
    # 30 lines of report logic
  end

  def send_monthly_summary
    # 15 lines of email logic
  end
end

# ✅ GOOD — Keep model lean, extract to services
class User < ApplicationRecord
  # validations (30 lines)
  # associations (20 lines)
  # scopes (10 lines)
  # basic instance methods (20 lines)
end

# Business logic in dedicated classes:
# Users::RevenueCalculator.call(user: user)
# Users::ReportGenerator.call(user: user)
# Users::MonthlySummaryMailer.call(user: user)
```

### 8.8 Catching All Exceptions

```ruby
# ❌ NEVER — Too broad, hides real bugs
begin
  process_payment
rescue Exception => e
  # Catches EVERYTHING including syntax errors, out of memory, etc.
  Rails.logger.error(e.message)
end

# ❌ BAD — Still too broad
begin
  process_payment
rescue => e
  # Catches all StandardError subclasses
end

# ✅ GOOD — Catch specific exceptions
begin
  process_payment
rescue PaymentGateway::DeclinedError => e
  Failure(["Payment declined: #{e.message}"])
rescue PaymentGateway::TimeoutError => e
  Failure(["Payment service timed out, please try again"])
end
```

### 8.9 N+1 Queries Left Unfixed

```ruby
# ❌ BAD — Bullet will flag this
@events = Event.all
# view: @events.each { |e| e.organizer.name }  # N+1!

# ✅ GOOD
@events = Event.includes(:organizer).all
```

### 8.10 Summary of "NEVER Do" Rules

| #   | Rule                                                | Consequence if Violated         |
| --- | --------------------------------------------------- | ------------------------------- |
| 1   | Never put business logic in controllers             | PR will be rejected             |
| 2   | Never `save(validate: false)` without Lead approval | PR will be rejected             |
| 3   | Never write raw SQL inline                          | Must use Query Object           |
| 4   | Never push to `main` / `develop` directly           | Branch protection will block it |
| 5   | Never modify merged migrations                      | Create new migration instead    |
| 6   | Never commit debug code (`binding.pry`, `puts`)     | Pre-commit hook catches some    |
| 7   | Never hardcode values                               | Use constants or config         |
| 8   | Never rescue `Exception`                            | Rescue specific errors only     |
| 9   | Never ignore N+1 queries                            | Fix what Bullet flags           |
| 10  | Never skip writing tests                            | PR will be rejected             |
| 11  | Never bypass git hooks (`--no-verify`)              | Ask Lead first                  |
| 12  | Never force push to shared branches                 | Can lose others' work           |

---

## Chapter 9: Daily Workflow Checklist

### Morning Routine

```
08:30  □ Answer Geekbot standup questions on Slack
         - What did you do yesterday?
         - What will you do today?
         - Any blockers?

09:00  □ Join daily standup meeting (Google Meet)
         - Screen share your latest code
         - Demo what you built
         - Discuss blockers with Lead
         - Receive feedback

09:30+ □ Check Google Sheets for your assigned tasks
         - Update status if needed
         - Pick a task if you finished the previous one
```

### During the Day

```
□ Make sure your branch is up-to-date with develop
  git fetch origin && git rebase origin/develop

□ Follow the architecture rules for every piece of code you write
  (refer to Chapter 4 decision flowchart)

□ Run tests frequently while coding
  rails test test/models/my_model_test.rb  # test what you're working on

□ Run rubocop on files you've changed
  rubocop app/services/my_service.rb

□ If stuck for more than 1 hour → DM the Lead on Slack immediately
  Include: what you're doing, what you tried, the error
```

### Before Pushing

```
□ Search for debug code:
  grep -rn "binding.pry\|debugger\|byebug\|puts \"\|pp " app/

□ Run RuboCop on your changes:
  rubocop -a

□ Run the full test suite:
  rails test

□ Review your own diff:
  git diff develop..HEAD

□ Push:
  git push origin feature/CA-XXX-my-feature
  (pre-push hook will run RuboCop + tests automatically)
```

### End of Day

```
17:00  □ Update Google Sheets task status
       □ If task is done → create PR, post link in #code-review
       □ If task is in progress → note what's left in the Notes column
       □ Prepare a mental summary for tomorrow's standup
       □ Commit any work-in-progress (WIP) to your branch
```

---

## Chapter 10: Useful Commands Reference

### Rails Commands

```bash
# Server
rails server                      # start the server
rails console                     # interactive Ruby console with app loaded
rails routes                      # list all routes
rails routes | grep payout        # find specific routes

# Database
rails db:create                   # create database
rails db:migrate                  # run pending migrations
rails db:rollback                 # undo last migration
rails db:rollback STEP=3          # undo last 3 migrations
rails db:seed                     # run seeds
rails db:setup                    # create + migrate + seed
rails db:reset                    # drop + create + migrate + seed

# Generate
rails generate migration AddStatusToPayouts status:string
rails generate model Ticket event:references user:references price:decimal
rails generate controller Admin::Events index show new create edit update destroy

# Tests
rails test                        # run all tests
rails test test/models/            # run all model tests
rails test test/models/user_test.rb       # run specific file
rails test test/models/user_test.rb:42    # run specific test (line 42)
```

### Git Commands

```bash
# Branching
git checkout develop               # switch to develop
git checkout -b feature/CA-012     # create and switch to new branch
git branch                         # list branches
git branch -d feature/CA-012       # delete local branch (after merge)

# Status & Diff
git status                         # see changed files
git diff                           # see unstaged changes
git diff --staged                  # see staged changes
git diff develop..HEAD             # see all changes vs develop
git log --oneline -10              # last 10 commits

# Committing
git add -A                         # stage all changes
git add <file>                     # stage specific file
git commit -m "feat: add feature"  # commit with message
git commit --amend                 # fix last commit

# Pushing
git push origin <branch>           # push branch to remote
git push --force-with-lease        # force push safely (after rebase)

# Updating
git fetch origin                   # download latest from remote
git rebase origin/develop          # replay your commits on latest develop
git pull origin develop            # fetch + merge (use rebase instead)

# Stashing (save work temporarily)
git stash                          # save current changes
git stash pop                      # restore saved changes
git stash list                     # see all stashes
```

### Docker Commands

```bash
# Container management
docker compose up -d               # start all services (background)
docker compose down                # stop all services
docker compose ps                  # see running containers
docker compose logs web            # see web container logs
docker compose logs -f web         # follow logs in real-time

# Run commands inside container
docker compose exec web rails console
docker compose exec web rails test
docker compose exec web rubocop -a
docker compose exec web rails db:migrate
```

### RuboCop Commands

```bash
rubocop                            # check all files
rubocop -a                         # auto-fix safe corrections
rubocop -A                         # auto-fix ALL corrections (including unsafe)
rubocop app/services/              # check specific directory
rubocop --only Style/StringLiterals # check only one cop
```

### Debugging

```bash
# In Ruby code (temporary, NEVER commit):
binding.pry          # Pry debugger breakpoint
debugger             # Ruby debug gem breakpoint
pp some_variable     # pretty print
Rails.logger.info("Debug: #{variable}")  # log to terminal

# In Rails console:
User.find(1)                        # find by ID
User.where(email: "test@test.com")  # find by attribute
User.last.attributes                # see all attributes
User.count                          # count records
```

---

## Chapter 11: Slack Communication Guidelines

### 11.1 Required Setup

1. Download and install Slack (desktop + mobile)
2. Join the team workspace
3. Join these channels:

| Channel            | Required        | Purpose                           |
| ------------------ | --------------- | --------------------------------- |
| `#team-dev`        | Yes             | Team discussions, standup results |
| `#proj-<name>`     | Yes             | Project-specific discussion       |
| `#proj-<name>-dev` | Yes (read-only) | Automated GitHub/CI notifications |
| `#code-review`     | Yes             | PR links that need review         |
| `#til-learning`    | Encouraged      | Share what you learned            |
| `#random`          | Optional        | Non-work chat, bonding            |

### 11.2 Channel Etiquette

| Channel            | Do                                                        | Don't                                 |
| ------------------ | --------------------------------------------------------- | ------------------------------------- |
| `#proj-<name>`     | Ask questions, discuss technical decisions, share updates | Spam, off-topic chat                  |
| `#proj-<name>-dev` | Read notifications                                        | Post messages (this is for bots only) |
| `#code-review`     | Post PR links with a one-line description                 | Post entire code blocks               |
| `#til-learning`    | Share interesting things you learned, useful links        | Nothing — it's encouraged!            |

### 11.3 Communication Rules

| Rule                                                          | Why                                                                |
| ------------------------------------------------------------- | ------------------------------------------------------------------ |
| **Always reply in threads**                                   | Keeps channels scannable. Click "Reply in thread" not main channel |
| **Paste code in code blocks**                                 | Triple backticks. Never screenshot code.                           |
| **Set Slack status**                                          | `🔨 Working on CA-123 - Payout feature` → team visibility          |
| **Respond within 30 min** during core hours (09:00-12:00 WIB) | Maintain team flow                                                 |
| **Use `@here` sparingly**                                     | Only for urgent matters during work hours                          |
| **Never `@channel`**                                          | Almost never appropriate in a small team                           |

### 11.4 How to Ask for Help

When you're stuck, DM the Lead with this format:

```
🔴 Stuck on: [task name]

What I'm trying to do:
[Brief description]

What I've tried:
1. [First thing you tried]
2. [Second thing you tried]
3. [Third thing you tried]

The error:
[Paste the error message or describe the unexpected behavior]

Code: (if relevant)
[Paste the relevant code block]
```

**Example:**

````
🔴 Stuck on: CA-012 Payout Withdrawal

What I'm trying to do:
Transition payout status from "approved" to "withdrawn" using AASM

What I've tried:
1. Added `event :withdraw` to AASM block
2. Called `payout.withdraw!` in the service
3. Checked that payout status is "approved" before calling

The error:
AASM::InvalidTransition: Event 'withdraw' cannot transition from 'approved'

Code:
```ruby
aasm column: :status do
  state :pending, initial: true
  state :approved
  state :withdrawn

  event :withdraw do
    transitions from: :approved, to: :withdrawn
  end
end
````

```

### 11.5 Escalation Timeline

```

0-30 min → Search docs, Google, Stack Overflow yourself
30-60 min → Ask in #proj-<name> channel (someone else might know)
60 min → DM the Lead with the structured format above
2+ hours → Lead schedules a pair programming session (screen share)

```

> **The worst thing you can do is stay stuck silently for hours.**
> Asking for help is NOT a sign of weakness — it's a sign of efficiency.

### 11.6 Geekbot Async Standup

Every morning at 08:30 WIB, Geekbot will ask you 3 questions:

```

1. What did you do yesterday?
2. What will you do today?
3. Any blockers?

```

**Answer format:**

```

1. Yesterday:
   - Completed Technical Analysis for CA-012 Payout Withdrawal
   - Created migration and model changes
   - Started implementing WithdrawalService

2. Today:
   - Finish WithdrawalService implementation
   - Write tests for the service
   - Start on controller and views

3. Blockers:
   - None
     (or)
   - Waiting for Lead to clarify minimum withdrawal amount

```

**Rules:**
- Answer **before** the daily standup meeting (before 09:00)
- Be specific — mention task IDs and actual work done
- Don't just say "working on the task" — say what specifically

### 11.7 Weekly Post: What I Learned

Every Friday, post one thing you learned this week in `#til-learning`:

```

📚 TIL: How dry-monads Do notation works

I was confused about `yield` in interactors. Turns out `yield` unwraps
a Success value or short-circuits to Failure. It's like an early return
for errors.

Instead of:
result = some_service.call
return result if result.failure?
value = result.value!

You can just:
value = yield some_service.call

Documented in: docs/ENTERPRISE_ARCHITECTURE_GUIDE.md

```

This helps:
- Reinforce your own learning
- Help the other junior learn without making the same mistakes
- Build a searchable knowledge base in Slack

---

## Appendix A: Quick Reference Card

Print this or keep it open on your second monitor.

```

=== BRANCH NAMING ===
feature/CA-<id>-<description>
fix/CA-<id>-<description>
hotfix/CA-<id>-<description>

=== COMMIT FORMAT ===
feat: <description>
fix: <description>
refactor: <description>
test: <description>
docs: <description>
chore: <description>

=== BEFORE PUSHING ===

1. grep -rn "binding.pry\|debugger\|puts" app/
2. rubocop -a
3. rails test
4. git diff develop..HEAD (self-review)

=== WHERE DOES CODE GO? ===
Controller → HTTP handling only (5-7 lines max)
Service → Single business operation
Interactor → Orchestrate multiple services
Query → Database queries
Form → Input validation
Decorator → Display formatting
Presenter → Complex view logic
Policy → Authorization
Concern → Shared behavior

=== ESCALATION ===
0-30 min → Search yourself
30-60 min → Ask in Slack channel
60+ min → DM Lead with structured format

=== DEFINITION OF DONE ===
□ Code merged to develop
□ Lead approved PR
□ Tests pass
□ RuboCop clean
□ Manually tested
□ Google Sheets updated

```

---

## Appendix B: Recommended Learning Resources

### Ruby & Rails

| Resource | Type | Level |
| -------- | ---- | ----- |
| [Rails Guides](https://guides.rubyonrails.org/) | Official docs | Beginner-Intermediate |
| [Ruby Style Guide](https://rubystyle.guide/) | Style reference | All levels |
| [GoRails](https://gorails.com/) | Video tutorials | Beginner-Intermediate |
| [Agile Web Development with Rails 7](https://pragprog.com/titles/rails7/agile-web-development-with-rails-7/) | Book | Beginner |

### Architecture & Design Patterns

| Resource | Type | Level |
| -------- | ---- | ----- |
| [dry-monads Documentation](https://dry-rb.org/gems/dry-monads/) | Official docs | Intermediate |
| [AASM Documentation](https://github.com/aasm/aasm) | Official docs | Beginner |
| [Pundit Documentation](https://github.com/varvet/pundit) | Official docs | Beginner |
| [Fearless Refactoring — Rails Controllers](https://www.goodreads.com/book/show/23256937-fearless-refactoring) | Book | Intermediate |

### Testing

| Resource | Type | Level |
| -------- | ---- | ----- |
| [Rails Testing Guide](https://guides.rubyonrails.org/testing.html) | Official docs | Beginner |
| [Minitest Documentation](https://docs.seattlerb.org/minitest/) | Official docs | Beginner |

### Git

| Resource | Type | Level |
| -------- | ---- | ----- |
| [Oh My Git!](https://ohmygit.org/) | Interactive game | Beginner |
| [Learn Git Branching](https://learngitbranching.js.org/) | Interactive tutorial | Beginner |
| [Pro Git Book](https://git-scm.com/book/en/v2) | Free book | All levels |

---

## Document Changelog

| Date | Version | Author | Changes |
| ---- | ------- | ------ | ------- |
| 2026-02 | 1.0 | Team Lead | Initial version |
```
