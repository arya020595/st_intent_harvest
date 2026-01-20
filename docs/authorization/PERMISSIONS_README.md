# Permission System Documentation

Complete documentation for the convention-based, self-maintaining permission system.

---

## 📚 Documentation Index

### 🚀 For Getting Started

**[Quick Start Guide](./PERMISSION_QUICK_START.md)** - 5 minutes to add a new module

- Step-by-step instructions
- Code examples
- Common patterns
- Best for: New developers, adding simple modules

### 📖 For Deep Understanding

**[Complete System Guide](./PERMISSION_SYSTEM_GUIDE.md)** - Everything you need to know

- Architecture and SOLID principles
- How the system works internally
- Comprehensive examples
- Testing strategies
- Troubleshooting
- Best for: Understanding the system, complex scenarios

### 🔍 For Daily Reference

**[Technical Reference](./PERMISSION_REFERENCE.md)** - Quick lookup

- API reference
- Code patterns
- Console commands
- Cheat sheets
- Best for: Quick lookups while coding

---

## 🎯 Quick Links

### I want to...

| Task                           | Go to                                                                                       | Time   |
| ------------------------------ | ------------------------------------------------------------------------------------------- | ------ |
| Add a new module               | [Quick Start](./PERMISSION_QUICK_START.md#example-adding-a-projects-module)                 | 5 min  |
| Understand the architecture    | [System Guide - Architecture](./PERMISSION_SYSTEM_GUIDE.md#architecture)                    | 15 min |
| Check permission in controller | [Reference - Controller Patterns](./PERMISSION_REFERENCE.md#controller-patterns)            | 30 sec |
| Add custom actions             | [Quick Start - Custom Actions](./PERMISSION_QUICK_START.md#custom-actions)                  | 3 min  |
| Troubleshoot redirect          | [System Guide - Troubleshooting](./PERMISSION_SYSTEM_GUIDE.md#troubleshooting)              | 5 min  |
| Write tests                    | [Reference - Testing Patterns](./PERMISSION_REFERENCE.md#testing-patterns)                  | 5 min  |
| Add namespaced module          | [Quick Start - Namespaced Modules](./PERMISSION_QUICK_START.md#advanced-namespaced-modules) | 7 min  |
| Look up API method             | [Reference - API Reference](./PERMISSION_REFERENCE.md#api-reference)                        | 10 sec |

---

## 🌟 System Overview

### What is this?

A **convention-based, self-maintaining authorization system** for Rails applications that:

- ✅ **Automatically redirects** users to their first accessible resource
- ✅ **Converts permission codes to routes** without manual mapping (78% reduction in maintenance)
- ✅ **Follows SOLID principles** for clean, testable code
- ✅ **Works with new modules** automatically - no configuration needed

### Key Concepts

```ruby
# Permission Format: namespace.resource.action
'workers.index'                    # Simple resource
'work_orders.details.index'        # Namespaced resource
'master_data.blocks.create'        # Multi-level namespace

# Automatic Conversion: permission → route helper
'workers.index'                    → workers_path
'work_orders.details.index'        → work_orders_details_path
'master_data.blocks.create'        → master_data_blocks_path

# Convention over Configuration
# Add new module → system automatically works!
```

### Why Use This System?

**Before:**

```ruby
# Manual mapping required for every resource
REDIRECT_PATHS = {
  'workers.index' => :workers_path,
  'inventory.index' => :inventory_path,
  'work_orders.details.index' => :work_orders_details_path,
  # ... 14+ manual entries
}
```

**After:**

```ruby
# Only 3 special cases needed
SPECIAL_CASES = {
  'dashboard.index' => :root_path,
  'user_management.users.index' => :user_management_users_path,
  'user_management.roles.index' => :user_management_roles_path
}
# Everything else: automatic!
```

---

## 🚀 30-Second Example

### Adding a "Projects" Module

```ruby
# 1. Add route
resources :projects

# 2. Add to seeds
'projects' => %w[index show new create edit update destroy]

# 3. Create policy
class ProjectPolicy < ApplicationPolicy
  def self.permission_resource
    'projects'
  end
end

# 4. Run seeds
docker compose exec web rails db:seed

# ✅ Done! System automatically:
# - Redirects users to /projects if accessible
# - Shows/hides menu items
# - Authorizes controller actions
```

---

## 📊 System Architecture

```
┌─────────────────────────────────────────────────────────┐
│                      User Login                          │
│                          ↓                               │
│              ApplicationController                       │
│         after_sign_in_path_for(user)                     │
│                          ↓                               │
│                    User Model                            │
│              first_accessible_path                       │
│                          ↓                               │
│              UserRedirectService                         │
│        Convention-based path resolution                  │
│                          ↓                               │
│  1. Check superadmin → :root_path                        │
│  2. Get user's *.index permissions                       │
│  3. Sort by priority                                     │
│  4. Convert code → path symbol                           │
│  5. Verify route exists                                  │
│  6. Return first valid path                              │
│                          ↓                               │
│              Controller redirects user                   │
└─────────────────────────────────────────────────────────┘
```

---

## 🔑 Core Components

### User Model

```ruby
user.has_permission?('workers.index')       # Check permission
user.superadmin?                            # Bypass all checks
user.first_accessible_path                  # Get redirect path
```

### UserRedirectService

```ruby
UserRedirectService.first_accessible_path_for(user)
# => :workers_path (automatically resolved)
```

### Policies

```ruby
class WorkerPolicy < ApplicationPolicy
  def self.permission_resource
    'workers'
  end

  def index?
    user.has_permission?('workers.index')
  end
end
```

---

## 📖 Usage Examples

### In Controllers

```ruby
def index
  authorize Worker, :index?  # Checks 'workers.index' permission
  @workers = Worker.all
end
```

### In Views

```erb
<!-- Menu visibility -->
<% if can_view_menu?('workers.index') %>
  <%= link_to "Workers", workers_path %>
<% end %>

<!-- Action buttons -->
<% if current_user.has_permission?('workers.create') %>
  <%= link_to "New Worker", new_worker_path %>
<% end %>
```

---

## 🎓 Learning Path

### New to the System?

1. Start with **[Quick Start](./PERMISSION_QUICK_START.md)** (5 min)
2. Add a test module to understand the flow
3. Read **[System Guide - Overview](./PERMISSION_SYSTEM_GUIDE.md#overview)** (10 min)
4. Bookmark **[Reference](./PERMISSION_REFERENCE.md)** for daily use

### Want Deep Understanding?

1. Read **[System Guide - Architecture](./PERMISSION_SYSTEM_GUIDE.md#architecture)** (15 min)
2. Study **[System Guide - How It Works](./PERMISSION_SYSTEM_GUIDE.md#how-it-works)** (20 min)
3. Review **[System Guide - Best Practices](./PERMISSION_SYSTEM_GUIDE.md#best-practices)** (10 min)
4. Set up tests using **[Reference - Testing Patterns](./PERMISSION_REFERENCE.md#testing-patterns)**

### Need to Debug?

1. Check **[System Guide - Troubleshooting](./PERMISSION_SYSTEM_GUIDE.md#troubleshooting)**
2. Use **[Reference - Console Commands](./PERMISSION_REFERENCE.md#console-commands)**
3. Review **[Quick Start - Common Mistakes](./PERMISSION_QUICK_START.md#common-mistakes)**

---

## 🛠️ Common Tasks

### Check User's Permissions

```ruby
# Rails console
user = User.find_by(email: 'user@example.com')
user.role.permissions.pluck(:code, :name)
```

### Test Path Conversion

```ruby
service = UserRedirectService.new(user)
service.send(:permission_to_path_symbol, 'workers.index')
# => :workers_path
```

### Verify Route Exists

```ruby
Rails.application.routes.url_helpers.respond_to?(:workers_path)
# => true
```

### Add Permission to Role

```ruby
role = Role.find_by(name: 'Clerk')
permission = Permission.find_by(code: 'projects.index')
role.permissions << permission
```

### Clear User Cache After Role Change

```ruby
user.update(role: new_role)
user.clear_permission_cache!
```

---

## 📝 Key Files

```
app/
  models/
    user.rb                          # Permission interface
    permission.rb                    # Validation & helpers
  services/
    user_redirect_service.rb         # Redirect logic ⭐
  policies/
    application_policy.rb            # Base policy
    *_policy.rb                      # Resource policies
  controllers/
    application_controller.rb        # Login redirect
  views/
    layouts/dashboard/
      _sidebar.html.erb              # Menu permissions

db/seeds/
  permissions.rb                     # Permission definitions ⭐
  development.rb                     # Dev role assignments
  production.rb                      # Prod role assignments

docs/
  PERMISSION_SYSTEM_GUIDE.md         # Complete guide
  PERMISSION_QUICK_START.md          # Quick start
  PERMISSION_REFERENCE.md            # Technical reference
```

---

## 🔥 Pro Tips

1. **Follow the Convention**

   - Permission: `workers.index`
   - Route: `workers_path`
   - = No manual mapping needed! ✨

2. **Only Add Special Cases When Necessary**

   - Dashboard uses `root_path` not `dashboard_path` → Special case
   - Standard routes → Automatic!

3. **Clear Cache After Role Changes**

   ```ruby
   user.update(role: new_role)
   user.clear_permission_cache!
   ```

4. **Use Semantic Search**

   - All permissions: `Permission.pluck(:code)`
   - By resource: `Permission.where("code LIKE 'workers.%'")`
   - By action: `Permission.where("code LIKE '%.index'")`

5. **Test in Console First**
   ```ruby
   user = User.first
   UserRedirectService.first_accessible_path_for(user)
   ```

---

## 🐛 Quick Debug

```ruby
# 1. Does permission exist?
Permission.exists?(code: 'workers.index')

# 2. Does user have it?
user.has_permission?('workers.index')

# 3. Does route exist?
Rails.application.routes.url_helpers.respond_to?(:workers_path)

# 4. What path will user get?
UserRedirectService.first_accessible_path_for(user)

# 5. Is cache stale?
user.clear_permission_cache!
```

---

## 📊 System Statistics

- **74 Permissions** across 12+ resources
- **3 Special Cases** (was 14 manual mappings)
- **78% Reduction** in manual maintenance
- **100% Automatic** for new standard modules
- **4 Roles**: Superadmin, Manager, Field Conductor, Clerk

---

## 🎯 Quick Reference Card

```ruby
# Permission Format
namespace.resource.action

# Check Permission
user.has_permission?('resource.action')

# Authorize
authorize Resource, :action?

# View Helper
can_view_menu?('resource.action')

# Redirect Service
UserRedirectService.first_accessible_path_for(user)

# Clear Cache
user.clear_permission_cache!

# Add Module
1. Route → resources :name
2. Seed → 'name' => %w[actions]
3. Policy → permission_resource = 'name'
4. Run → rails db:seed
```

---

## 💡 Next Steps

1. **Read**: [Quick Start Guide](./PERMISSION_QUICK_START.md)
2. **Practice**: Add a test module
3. **Deep Dive**: [Complete System Guide](./PERMISSION_SYSTEM_GUIDE.md)
4. **Reference**: Bookmark [Technical Reference](./PERMISSION_REFERENCE.md)

---

## 🤝 Contributing

When adding documentation:

- Update relevant sections in all 3 docs
- Include code examples
- Test all code snippets
- Keep examples consistent

---

## 📞 Support

**Issues:**

1. Check [Troubleshooting](./PERMISSION_SYSTEM_GUIDE.md#troubleshooting)
2. Review [Common Mistakes](./PERMISSION_QUICK_START.md#common-mistakes)
3. Use [Debug Checklist](./PERMISSION_QUICK_START.md#debug-checklist)

**Questions:**

- Architecture → [System Guide](./PERMISSION_SYSTEM_GUIDE.md)
- How-to → [Quick Start](./PERMISSION_QUICK_START.md)
- API/Syntax → [Reference](./PERMISSION_REFERENCE.md)

---

**Version:** 1.0
**Last Updated:** November 20, 2024
**Rails Version:** 8.1+
