# 🌿 Git Branching Strategy for ST Intent Harvest

## Overview

This document defines the Git branching strategy for the ST Intent Harvest project. Based on industry best practices and research from GitFlow, GitHub Flow, and GitLab Flow, we use a **modified GitFlow strategy** tailored for our team size and deployment needs.

---

## 📋 Table of Contents

1. [Branch Structure](#branch-structure)
2. [Branch Types](#branch-types)
3. [Workflow Diagrams](#workflow-diagrams)
4. [Naming Conventions](#naming-conventions)
5. [Development Workflow](#development-workflow)
6. [Release Process](#release-process)
7. [Hotfix Process](#hotfix-process)
8. [Pull Request Guidelines](#pull-request-guidelines)
9. [Best Practices](#best-practices)
10. [Common Commands](#common-commands)

---

## Branch Structure

### 🏗️ Core Branches (Long-lived)

```
┌─────────────────────────────────────────────────────────────┐
│                    BRANCH HIERARCHY                         │
└─────────────────────────────────────────────────────────────┘

main (production)
  │
  ├──► Production-ready code
  ├──► Tagged releases (v1.0.0, v1.1.0, etc.)
  ├──► Protected branch (requires PR approval)
  └──► Deployed to production server
       │
       │
develop (staging/pre-production)
  │
  ├──► Integration branch for features
  ├──► Pre-production testing
  ├──► Protected branch (requires PR approval)
  └──► Deployed to staging server
       │
       │
       ├──► feature/* (short-lived)
       │    └── New features and enhancements
       │
       ├──► bugfix/* (short-lived)
       │    └── Bug fixes for develop branch
       │
       ├──► release/* (short-lived)
       │    └── Release preparation
       │
       └──► hotfix/* (short-lived)
            └── Emergency fixes for production
```

### 📊 Branch Comparison

| Branch Type | Base Branch | Merge Into | Lifespan | Purpose |
|-------------|-------------|------------|----------|---------|
| `main` | - | - | Permanent | Production code |
| `develop` | `main` | `main` | Permanent | Integration & staging |
| `feature/*` | `develop` | `develop` | Days-weeks | New features |
| `bugfix/*` | `develop` | `develop` | Hours-days | Bug fixes |
| `release/*` | `develop` | `main` + `develop` | Days | Release prep |
| `hotfix/*` | `main` | `main` + `develop` | Hours | Critical fixes |

---

## Branch Types

### 1️⃣ Main Branch

**Purpose:** Contains production-ready, stable code that is deployed to live servers.

**Characteristics:**
- Always deployable
- Tagged with version numbers (semantic versioning)
- Protected branch (no direct commits)
- All changes via Pull Requests from `release/*` or `hotfix/*`

**Protection Rules:**
```
✅ Require pull request reviews (2 approvers)
✅ Require status checks to pass
✅ Require branches to be up to date
✅ Include administrators
✅ Restrict who can push
```

### 2️⃣ Develop Branch

**Purpose:** Integration branch where features are merged and tested before release.

**Characteristics:**
- Contains latest development changes
- Deployed to staging environment
- Protected branch (no direct commits)
- Base for all feature/bugfix branches

**Protection Rules:**
```
✅ Require pull request reviews (1 approver)
✅ Require status checks to pass
✅ Require branches to be up to date
```

### 3️⃣ Feature Branches

**Purpose:** Develop new features or enhancements.

**Format:** `feature/<issue-number>-<short-description>`

**Examples:**
```bash
feature/123-add-payslip-export
feature/124-implement-work-order-approval
feature/125-create-inventory-management
```

**Lifecycle:**
```
1. Create from develop
2. Develop feature
3. Create Pull Request to develop
4. Code review & approval
5. Merge to develop
6. Delete branch
```

**Commands:**
```bash
# Create feature branch
git checkout develop
git pull origin develop
git checkout -b feature/123-add-payslip-export

# Work on feature (commit regularly)
git add .
git commit -m "feat: implement payslip export logic"

# Push to remote
git push -u origin feature/123-add-payslip-export

# When ready, create PR to develop
# After merge, delete branch
git checkout develop
git pull origin develop
git branch -d feature/123-add-payslip-export
```

### 4️⃣ Bugfix Branches

**Purpose:** Fix bugs found in develop/staging environment.

**Format:** `bugfix/<issue-number>-<short-description>`

**Examples:**
```bash
bugfix/126-fix-payslip-calculation
bugfix/127-correct-work-order-validation
bugfix/128-resolve-inventory-update-error
```

**Lifecycle:**
```
1. Create from develop
2. Fix bug
3. Test fix
4. Create Pull Request to develop
5. Code review & approval
6. Merge to develop
7. Delete branch
```

### 5️⃣ Release Branches

**Purpose:** Prepare code for production release (final testing, version bumping, documentation).

**Format:** `release/v<version>`

**Examples:**
```bash
release/v1.0.0
release/v1.1.0
release/v2.0.0
```

**Lifecycle:**
```
1. Create from develop when ready for release
2. Final testing & bug fixes
3. Update version numbers
4. Update CHANGELOG.md
5. Create PR to main
6. After approval, merge to main
7. Tag main with version
8. Merge back to develop
9. Delete branch
```

**Commands:**
```bash
# Create release branch
git checkout develop
git pull origin develop
git checkout -b release/v1.0.0

# Update version in files
# Example: config/application.rb, package.json, etc.

# Commit version bump
git commit -am "chore: bump version to v1.0.0"

# Push release branch
git push -u origin release/v1.0.0

# Create PR to main
# After merge to main, tag the release
git checkout main
git pull origin main
git tag -a v1.0.0 -m "Release version 1.0.0"
git push origin v1.0.0

# Merge back to develop
git checkout develop
git merge release/v1.0.0
git push origin develop

# Delete release branch
git branch -d release/v1.0.0
git push origin --delete release/v1.0.0
```

### 6️⃣ Hotfix Branches

**Purpose:** Emergency fixes for critical bugs in production.

**Format:** `hotfix/<issue-number>-<short-description>`

**Examples:**
```bash
hotfix/129-fix-critical-login-bug
hotfix/130-resolve-payment-error
hotfix/131-patch-security-vulnerability
```

**Lifecycle:**
```
1. Create from main (production code)
2. Fix critical bug
3. Test fix thoroughly
4. Create PR to main
5. Emergency approval & merge
6. Tag new patch version
7. Merge back to develop
8. Delete branch
```

**Commands:**
```bash
# Create hotfix branch
git checkout main
git pull origin main
git checkout -b hotfix/129-fix-critical-login-bug

# Fix the bug
git add .
git commit -m "fix: resolve critical login authentication issue"

# Push hotfix
git push -u origin hotfix/129-fix-critical-login-bug

# Create urgent PR to main
# After merge to main, tag patch version
git checkout main
git pull origin main
git tag -a v1.0.1 -m "Hotfix: critical login bug"
git push origin v1.0.1

# Merge to develop
git checkout develop
git merge hotfix/129-fix-critical-login-bug
git push origin develop

# Delete hotfix branch
git branch -d hotfix/129-fix-critical-login-bug
git push origin --delete hotfix/129-fix-critical-login-bug
```

---

## Workflow Diagrams

### 🔄 Feature Development Flow

```
DEVELOPER WORKFLOW
═══════════════════════════════════════════════════════════

1️⃣  Create Feature Branch
    develop
      │
      └──► feature/123-new-feature
           
2️⃣  Develop & Commit
    feature/123-new-feature
      ├── commit: "feat: add feature skeleton"
      ├── commit: "feat: implement business logic"
      ├── commit: "test: add unit tests"
      └── commit: "docs: update README"

3️⃣  Push & Create Pull Request
    feature/123-new-feature ──PR──► develop
    
4️⃣  Code Review
    ├── Reviewer 1: Approve ✅
    └── CI/CD: Tests pass ✅
    
5️⃣  Merge to Develop
    develop ◄── feature/123-new-feature (merged)
    
6️⃣  Delete Feature Branch
    feature/123-new-feature (deleted)
    
7️⃣  Deploy to Staging
    develop ──deploy──► Staging Server
```

### 🚀 Release Flow

```
RELEASE WORKFLOW
═══════════════════════════════════════════════════════════

1️⃣  Create Release Branch
    develop
      │
      └──► release/v1.0.0
      
2️⃣  Final Testing & Fixes
    release/v1.0.0
      ├── commit: "chore: bump version to v1.0.0"
      ├── commit: "docs: update CHANGELOG"
      └── commit: "fix: minor UI adjustment"
      
3️⃣  Merge to Main
    release/v1.0.0 ──PR──► main
    
4️⃣  Tag Release
    main (v1.0.0)
    
5️⃣  Deploy to Production
    main ──deploy──► Production Server
    
6️⃣  Merge Back to Develop
    release/v1.0.0 ──merge──► develop
    
7️⃣  Delete Release Branch
    release/v1.0.0 (deleted)
```

### 🚨 Hotfix Flow

```
HOTFIX WORKFLOW (Emergency)
═══════════════════════════════════════════════════════════

1️⃣  Critical Bug Detected in Production
    main (v1.0.0) ⚠️  Bug detected!
      │
      └──► hotfix/129-critical-bug
      
2️⃣  Fix Bug
    hotfix/129-critical-bug
      └── commit: "fix: resolve critical authentication bug"
      
3️⃣  Test Thoroughly
    hotfix/129-critical-bug
      └── Manual & automated testing
      
4️⃣  Emergency Merge to Main
    hotfix/129-critical-bug ──PR──► main (v1.0.1)
    
5️⃣  Deploy to Production Immediately
    main ──deploy──► Production Server
    
6️⃣  Merge to Develop
    hotfix/129-critical-bug ──merge──► develop
    
7️⃣  Delete Hotfix Branch
    hotfix/129-critical-bug (deleted)
```

### 🌊 Complete Flow Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                   COMPLETE GIT FLOW                         │
└─────────────────────────────────────────────────────────────┘

main (Production)
  │  v1.0.0        v1.0.1        v1.1.0        v2.0.0
  ●────────────────●─────────────●─────────────●────────►
  │                │             │             │
  │                │             │             │
  │           ┌────hotfix/129    │             │
  │           │    (emergency)   │             │
  │           │         │        │             │
develop      │         ↓        │             │
  ●──────────┼─────────●────────┼─────────────●────────►
  │          │                  │             │
  │          │             release/v1.1.0     │
  │          │                  │             │
  ├──feature/123                │        release/v2.0.0
  │      │                      │             │
  │      └──► ●─────► merge     │             │
  │                              │             │
  ├──feature/124                │             │
  │      │                      │             │
  │      └──► ●─────► merge     │             │
  │                              │             │
  ├──bugfix/126                 │             │
  │      │                      │             │
  │      └──► ●─────► merge     │             │
  │                              ↓             │
  │                         merge to main     │
  │                              │             │
  │                              ↓             ↓
  │                         Deploy to      Deploy to
  │                         Production     Production

Legend:
  ● = Commit/Tag
  ► = Forward in time
  └──► = Branch created
  ─────► merge = Branch merged
```

---

## Naming Conventions

### Branch Names

**Format:** `<type>/<issue-number>-<description>`

**Rules:**
- Use lowercase
- Use hyphens (-) to separate words
- Keep description short and descriptive
- Always include issue/ticket number

**Examples:**
```bash
✅ feature/123-add-user-authentication
✅ bugfix/124-fix-payment-validation
✅ release/v1.2.0
✅ hotfix/125-patch-security-vuln

❌ Feature/AddAuth (wrong case, no issue number)
❌ fix_bug_123 (use hyphens, not underscores)
❌ my-branch (no type, no issue number)
```

### Commit Messages

**Format:** `<type>: <description>`

**Types:**
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `style`: Code style changes (formatting, no logic change)
- `refactor`: Code refactoring
- `test`: Adding or updating tests
- `chore`: Maintenance tasks (deps, config, etc.)
- `perf`: Performance improvements
- `ci`: CI/CD changes

**Examples:**
```bash
✅ feat: add payslip export functionality
✅ fix: resolve work order calculation error
✅ docs: update API documentation
✅ refactor: extract permission checker to service
✅ test: add unit tests for inventory model
✅ chore: bump Rails version to 8.0.1

❌ Added new feature (no type prefix)
❌ fixed bug (not capitalized, vague)
❌ WIP (not descriptive)
```

### Tags

**Format:** `v<major>.<minor>.<patch>`

**Semantic Versioning:**
- **Major (v2.0.0)**: Breaking changes, incompatible API changes
- **Minor (v1.3.0)**: New features, backward compatible
- **Patch (v1.2.4)**: Bug fixes, backward compatible

**Examples:**
```bash
v1.0.0  # Initial release
v1.1.0  # Added new features
v1.1.1  # Bug fix
v2.0.0  # Major update with breaking changes
```

---

## Development Workflow

### Daily Developer Workflow

```bash
# 🌅 Start of Day
# ─────────────────────────────────────────────────────────

# 1. Update develop branch
git checkout develop
git pull origin develop

# 2. Create feature branch
git checkout -b feature/123-new-feature

# 3. Make changes
# ... code, code, code ...

# 4. Stage and commit
git add .
git commit -m "feat: implement new feature logic"

# 5. Push to remote regularly
git push -u origin feature/123-new-feature

# 6. Continue working
git add .
git commit -m "test: add unit tests"
git push

# 🌙 End of Day / Ready for Review
# ─────────────────────────────────────────────────────────

# 7. Update from develop (in case others merged)
git checkout develop
git pull origin develop
git checkout feature/123-new-feature
git merge develop

# 8. Resolve any conflicts
# ... fix conflicts if any ...

# 9. Push final changes
git push

# 10. Create Pull Request on GitHub/GitLab
# Title: feat: New Feature (#123)
# Description: Implements new feature as per requirements

# 11. Request code review
# Tag reviewers, wait for approval

# 📋 After Merge
# ─────────────────────────────────────────────────────────

# 12. Update local develop
git checkout develop
git pull origin develop

# 13. Delete feature branch
git branch -d feature/123-new-feature
git push origin --delete feature/123-new-feature
```

### Team Collaboration Workflow

```bash
# Scenario: Multiple developers working on different features
# ═══════════════════════════════════════════════════════════

# Developer A (feature/123-auth)
git checkout develop
git pull origin develop
git checkout -b feature/123-add-authentication
# ... work on auth ...
git push -u origin feature/123-add-authentication
# Create PR → Code Review → Merge to develop

# Developer B (feature/124-payment)
git checkout develop
git pull origin develop
git checkout -b feature/124-add-payment-system
# ... work on payment ...
git push -u origin feature/124-add-payment-system
# Create PR → Code Review → Merge to develop

# Developer C (bugfix/125-fix)
git checkout develop
git pull origin develop
git checkout -b bugfix/125-fix-calculation
# ... fix bug ...
git push -u origin bugfix/125-fix-calculation
# Create PR → Code Review → Merge to develop

# Integration on develop branch
# All features merged and tested on staging
```

---

## Release Process

### Step-by-Step Release Workflow

```bash
# 📦 RELEASE PREPARATION
# ═══════════════════════════════════════════════════════════

# 1. Ensure develop is stable
git checkout develop
git pull origin develop
# Run all tests, verify staging is working

# 2. Create release branch
git checkout -b release/v1.2.0

# 3. Update version numbers
# Edit config/application.rb, package.json, etc.
VERSION = "1.2.0"

# 4. Update CHANGELOG.md
# Document all changes in this release
## [1.2.0] - 2025-10-28
### Added
- Payslip export functionality
- Work order approval workflow
### Fixed
- Calculation errors in pay rates
### Changed
- Updated UI for inventory management

# 5. Commit version changes
git add .
git commit -m "chore: bump version to v1.2.0"

# 6. Push release branch
git push -u origin release/v1.2.0

# 7. Final testing on release branch
# If bugs found, fix on release branch:
git commit -m "fix: minor UI adjustment for release"
git push

# 8. Create Pull Request to main
# Title: Release v1.2.0
# Description: Release notes and changelog

# 9. Code review and approval (requires 2 approvers)

# 10. Merge to main
# Via GitHub/GitLab UI or command line
git checkout main
git pull origin main
git merge release/v1.2.0
git push origin main

# 11. Tag the release
git tag -a v1.2.0 -m "Release version 1.2.0"
git push origin v1.2.0

# 12. Deploy to production
# Trigger production deployment pipeline

# 13. Merge back to develop
git checkout develop
git merge release/v1.2.0
git push origin develop

# 14. Clean up release branch
git branch -d release/v1.2.0
git push origin --delete release/v1.2.0

# ✅ Release Complete!
```

### Release Checklist

Before creating a release branch:

- [ ] All features for this release are merged to develop
- [ ] Staging environment is stable and tested
- [ ] All tests are passing
- [ ] Documentation is updated
- [ ] Database migrations tested
- [ ] Security scan completed
- [ ] Performance testing done

During release:

- [ ] Version numbers updated
- [ ] CHANGELOG.md updated
- [ ] Release notes prepared
- [ ] Final testing completed
- [ ] PR approved by 2+ reviewers

After release:

- [ ] Production deployment successful
- [ ] Smoke tests on production passed
- [ ] Release announcement sent
- [ ] Monitor for errors/issues
- [ ] Release branch deleted

---

## Hotfix Process

### Emergency Hotfix Workflow

```bash
# 🚨 CRITICAL BUG DETECTED IN PRODUCTION
# ═══════════════════════════════════════════════════════════

# 1. Create hotfix branch from main
git checkout main
git pull origin main
git checkout -b hotfix/129-fix-critical-auth-bug

# 2. Fix the bug
# ... implement fix ...

# 3. Test thoroughly
# Local testing
docker compose exec web rails test
# Manual verification

# 4. Commit the fix
git add .
git commit -m "fix: resolve critical authentication vulnerability"

# 5. Push hotfix branch
git push -u origin hotfix/129-fix-critical-auth-bug

# 6. Create URGENT Pull Request to main
# Title: 🚨 HOTFIX: Critical Auth Bug (#129)
# Label: priority:critical, type:hotfix

# 7. Emergency review and approval
# Get immediate approval from tech lead

# 8. Merge to main
git checkout main
git pull origin main
git merge hotfix/129-fix-critical-auth-bug
git push origin main

# 9. Tag patch version
git tag -a v1.2.1 -m "Hotfix: critical authentication bug"
git push origin v1.2.1

# 10. Deploy to production IMMEDIATELY
# Trigger emergency production deployment

# 11. Merge to develop
git checkout develop
git pull origin develop
git merge hotfix/129-fix-critical-auth-bug
git push origin develop

# 12. Clean up
git branch -d hotfix/129-fix-critical-auth-bug
git push origin --delete hotfix/129-fix-critical-auth-bug

# 13. Monitor production
# Watch logs, verify fix is working

# 14. Post-mortem
# Document incident, root cause, prevention steps
```

### Hotfix Criteria

When to use hotfix branch:

✅ **Use Hotfix:**
- Security vulnerabilities
- Data loss or corruption
- Payment system failures
- Authentication/authorization bugs
- Complete system downtime
- Critical user-facing errors

❌ **Don't Use Hotfix:**
- Minor UI bugs
- Non-critical feature requests
- Performance optimizations (unless severe)
- Documentation updates
- Spelling errors

---

## Pull Request Guidelines

### PR Template

```markdown
## Description
Brief description of changes

Fixes #123

## Type of Change
- [ ] Bug fix (non-breaking change which fixes an issue)
- [ ] New feature (non-breaking change which adds functionality)
- [ ] Breaking change (fix or feature that would cause existing functionality to not work as expected)
- [ ] Documentation update

## How Has This Been Tested?
- [ ] Unit tests
- [ ] Integration tests
- [ ] Manual testing

## Checklist
- [ ] My code follows the style guidelines of this project
- [ ] I have performed a self-review of my own code
- [ ] I have commented my code, particularly in hard-to-understand areas
- [ ] I have made corresponding changes to the documentation
- [ ] My changes generate no new warnings
- [ ] I have added tests that prove my fix is effective or that my feature works
- [ ] New and existing unit tests pass locally with my changes
- [ ] Any dependent changes have been merged and published

## Screenshots (if applicable)
```

### Code Review Process

**For Reviewers:**

1. **Code Quality**
   - [ ] Code is readable and maintainable
   - [ ] No commented-out code
   - [ ] No debug statements (puts, console.log)
   - [ ] Follows Ruby/Rails conventions

2. **Functionality**
   - [ ] Meets requirements
   - [ ] Edge cases handled
   - [ ] Error handling implemented

3. **Testing**
   - [ ] Tests added/updated
   - [ ] Tests are meaningful
   - [ ] All tests pass

4. **Security**
   - [ ] No sensitive data exposed
   - [ ] Input validation present
   - [ ] SQL injection prevention
   - [ ] Authentication/authorization checked

5. **Performance**
   - [ ] No N+1 queries
   - [ ] Database indexes added if needed
   - [ ] Efficient algorithms used

**Review Timeline:**
- Feature PR: within 24 hours
- Bugfix PR: within 4 hours
- Hotfix PR: immediate (within 1 hour)

---

## Best Practices

### ✅ Do's

1. **Commit Often**
   ```bash
   # Good: Small, focused commits
   git commit -m "feat: add user validation"
   git commit -m "test: add user validation tests"
   git commit -m "docs: update user model documentation"
   ```

2. **Pull Before Push**
   ```bash
   git pull origin develop
   git push origin feature/123-my-feature
   ```

3. **Keep Branches Updated**
   ```bash
   # Regularly merge develop into your feature branch
   git checkout develop
   git pull origin develop
   git checkout feature/123-my-feature
   git merge develop
   ```

4. **Write Descriptive Commit Messages**
   ```bash
   ✅ "feat: implement payslip export with PDF generation"
   ❌ "update files"
   ```

5. **Delete Merged Branches**
   ```bash
   git branch -d feature/123-my-feature
   git push origin --delete feature/123-my-feature
   ```

6. **Use Pull Requests**
   - Never push directly to main or develop
   - Always create PR for code review
   - Address review comments

7. **Test Before Pushing**
   ```bash
   docker compose exec web rails test
   docker compose exec web rubocop
   ```

### ❌ Don'ts

1. **Don't Commit to Main/Develop Directly**
   ```bash
   ❌ git checkout main
   ❌ git commit -m "quick fix"
   ❌ git push
   ```

2. **Don't Push Broken Code**
   ```bash
   # Always ensure tests pass
   ❌ git push  # without running tests
   ```

3. **Don't Rebase Shared Branches**
   ```bash
   ❌ git checkout develop
   ❌ git rebase feature/123
   ```

4. **Don't Force Push to Shared Branches**
   ```bash
   ❌ git push --force origin develop
   ```

5. **Don't Leave Branches Stale**
   ```bash
   # Delete after merge, don't accumulate branches
   ❌ Leaving 50+ old feature branches
   ```

6. **Don't Commit Secrets**
   ```bash
   ❌ config/master.key
   ❌ .env
   ❌ config/credentials/*.key
   ```

7. **Don't Mix Multiple Features in One Branch**
   ```bash
   ❌ feature/123-add-auth-and-payment-and-reports
   ✅ feature/123-add-authentication
   ✅ feature/124-add-payment-system
   ✅ feature/125-add-reports
   ```

---

## Common Commands

### Branch Management

```bash
# List all branches
git branch -a

# Create new branch
git checkout -b feature/123-new-feature

# Switch branches
git checkout develop

# Delete local branch
git branch -d feature/123-new-feature

# Delete remote branch
git push origin --delete feature/123-new-feature

# Rename branch
git branch -m old-name new-name

# Track remote branch
git branch --set-upstream-to=origin/feature/123 feature/123
```

### Synchronization

```bash
# Update current branch from remote
git pull origin develop

# Fetch all branches
git fetch --all

# Update develop and merge into feature
git checkout develop
git pull origin develop
git checkout feature/123-my-feature
git merge develop

# Push current branch
git push

# Push new branch
git push -u origin feature/123-new-feature
```

### Merging

```bash
# Merge feature into develop
git checkout develop
git merge feature/123-new-feature
git push origin develop

# Merge with no fast-forward (preserves history)
git merge --no-ff feature/123-new-feature

# Abort merge
git merge --abort
```

### Tagging

```bash
# Create annotated tag
git tag -a v1.0.0 -m "Release version 1.0.0"

# Push tag to remote
git push origin v1.0.0

# Push all tags
git push origin --tags

# List tags
git tag

# Delete local tag
git tag -d v1.0.0

# Delete remote tag
git push origin --delete v1.0.0
```

### Stashing

```bash
# Stash current changes
git stash

# Stash with message
git stash save "work in progress on feature"

# List stashes
git stash list

# Apply latest stash
git stash pop

# Apply specific stash
git stash apply stash@{0}

# Delete stash
git stash drop stash@{0}
```

### Undoing Changes

```bash
# Undo last commit (keep changes)
git reset --soft HEAD~1

# Undo last commit (discard changes)
git reset --hard HEAD~1

# Undo changes to file
git checkout -- file.rb

# Revert commit (creates new commit)
git revert <commit-hash>

# Amend last commit message
git commit --amend -m "new message"
```

### Viewing History

```bash
# View commit history
git log

# View compact history
git log --oneline

# View graphical history
git log --graph --oneline --all

# View changes in commit
git show <commit-hash>

# View file history
git log -- path/to/file.rb
```

---

## Git Hooks (Optional)

### Pre-commit Hook

Create `.git/hooks/pre-commit`:

```bash
#!/bin/bash

echo "Running pre-commit checks..."

# Run RuboCop
echo "Running RuboCop..."
docker compose exec -T web rubocop
if [ $? -ne 0 ]; then
  echo "❌ RuboCop failed. Please fix errors before committing."
  exit 1
fi

# Run tests
echo "Running tests..."
docker compose exec -T web rails test
if [ $? -ne 0 ]; then
  echo "❌ Tests failed. Please fix before committing."
  exit 1
fi

echo "✅ Pre-commit checks passed!"
exit 0
```

Make it executable:
```bash
chmod +x .git/hooks/pre-commit
```

---

## Summary

### 🎯 Quick Reference

| Action | Branch | Command |
|--------|--------|---------|
| New feature | `feature/*` from `develop` | `git checkout -b feature/123-desc` |
| Bug fix | `bugfix/*` from `develop` | `git checkout -b bugfix/123-desc` |
| Release | `release/*` from `develop` | `git checkout -b release/v1.0.0` |
| Hotfix | `hotfix/*` from `main` | `git checkout -b hotfix/123-desc` |
| Update branch | Any | `git pull origin develop` |
| Merge feature | `develop` | `git merge feature/123-desc` |
| Tag release | `main` | `git tag -a v1.0.0 -m "message"` |

### 📊 Branch Lifespan

```
main     ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━►  (permanent)
develop  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━►  (permanent)
release  ━━━━━━━━━━►                           (days)
feature  ━━━━━━━━━━━━━━►                       (days-weeks)
bugfix   ━━━►                                  (hours-days)
hotfix   ━━►                                   (hours)
```

### 🔄 Typical Week

```
Monday:
- Create feature/123-new-feature from develop
- Work on feature, commit regularly

Tuesday-Thursday:
- Continue development
- Keep branch updated with develop
- Push changes to remote

Friday:
- Create Pull Request
- Code review
- Address review comments
- Merge to develop
- Delete feature branch

Next Monday:
- develop deployed to staging
- QA testing throughout week

Following Friday:
- Create release/v1.x.0
- Final testing
- Merge to main
- Tag and deploy to production
```

---

**References:**
- [GitFlow Workflow](https://nvie.com/posts/a-successful-git-branching-model/)
- [GitHub Flow](https://githubflow.github.io/)
- [GitLab Flow](https://about.gitlab.com/topics/version-control/what-is-gitlab-flow/)
- [Semantic Versioning](https://semver.org/)

**Last Updated:** October 28, 2025  
**Project:** ST Intent Harvest  
**Team:** Development Team
