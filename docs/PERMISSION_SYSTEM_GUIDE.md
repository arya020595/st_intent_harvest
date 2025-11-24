# Permission System Guide

## Table of Contents

1. [Overview](#overview)
2. [Architecture](#architecture)
3. [Permission Format](#permission-format)
4. [Core Components](#core-components)
5. [How It Works](#how-it-works)
6. [Usage Examples](#usage-examples)
7. [Adding New Modules](#adding-new-modules)
8. [Best Practices](#best-practices)
9. [Testing](#testing)
10. [Troubleshooting](#troubleshooting)

---

## Overview

This permission system implements a **convention-based, self-maintaining authorization** framework for Rails applications. It follows SOLID principles and automatically handles user redirects without manual configuration.

### Key Features

- ✅ **Convention over Configuration**: Permission codes automatically map to route helpers
- ✅ **SOLID Principles**: Clean separation of concerns, easy to test and extend
- ✅ **Self-Maintaining**: 78% reduction in manual mappings (3 special cases vs 14 full mappings)
- ✅ **Automatic Redirects**: Users automatically redirected to their first accessible resource
- ✅ **Zero Configuration**: New modules work automatically without code changes

### Benefits

- **Developer Efficiency**: Add new modules without touching redirect logic
- **Maintainability**: Clear, predictable permission structure
- **Type Safety**: Validation ensures permission codes follow conventions
- **Performance**: Caching prevents N+1 queries

---

## Architecture

### SOLID Principles Applied

```
┌─────────────────────────────────────────────────────────────┐
│                    Single Responsibility                     │
├─────────────────────────────────────────────────────────────┤
│ User Model          → User data & authentication            │
│ Permission Model    → Permission validation & data          │
│ UserRedirectService → Redirect path determination           │
│ Policies            → Resource-level authorization          │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│                    Open/Closed Principle                     │
├─────────────────────────────────────────────────────────────┤
│ Open for Extension:  Add new resources without modifying    │
│                      existing code                           │
│ Closed for Mod:      Core logic stays unchanged when adding │
│                      new modules                             │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│                 Dependency Inversion Principle               │
├─────────────────────────────────────────────────────────────┤
│ User → UserRedirectService (abstraction)                    │
│ Controllers → Policies (abstraction)                        │
└─────────────────────────────────────────────────────────────┘
```

---

## Permission Format

### Structure: `namespace.resource.action`

```ruby
# Single-level resources
"dashboard.index"           # Dashboard access
"workers.index"             # List workers
"workers.create"            # Create worker
"inventory.update"          # Update inventory item

# Namespaced resources (dot-separated)
"work_orders.details.index"         # List work order details
"work_orders.approvals.approve"     # Approve work orders
"work_orders.pay_calculations.show" # View pay calculation
"master_data.blocks.create"         # Create block
"master_data.vehicles.destroy"      # Delete vehicle
"admin.users.index"                 # List users
```

### Validation Rules

```ruby
# Permission Code Format
/\A[a-z][a-z0-9_]*(\.[a-z][a-z0-9_]*)+\z/
# Valid:   "workers.index", "work_orders.details.create"
# Invalid: "Workers.index", "workers", "workers-index"

# Resource Format (allows optional namespaces)
/\A[a-z][a-z0-9_]*(\.[a-z][a-z0-9_]*)*\z/
# Valid:   "workers", "work_orders.details", "master_data.blocks"
# Invalid: "Workers", "work-orders.details", ".workers"
```

---

## Core Components

### 1. Permission Model

**Location**: `app/models/permission.rb`

```ruby
# Responsibilities:
# - Validate permission code format
# - Validate resource format
# - Extract namespace and action from code

# Key Methods:
permission.namespace  # => "work_orders.details"
permission.action     # => "index"
```

### 2. User Model

**Location**: `app/models/user.rb`

```ruby
# Responsibilities:
# - Check user permissions (lean interface)
# - Cache permission codes for performance
# - Delegate complex logic to services

# Key Methods:
user.has_permission?("workers.index")           # Check specific permission
user.has_resource_permission?("workers")        # Check any workers.* permission
user.superadmin?                                # Bypass all checks
user.first_accessible_path                      # Get redirect path (delegates to service)
user.clear_permission_cache!                    # Clear cache after role change
```

### 3. UserRedirectService

**Location**: `app/services/user_redirect_service.rb`

```ruby
# Responsibilities:
# - Determine user's first accessible path after login
# - Convert permission codes to route helpers automatically
# - Handle special cases for non-standard routes

# Key Constants:
SPECIAL_CASES = {
  'dashboard.index' => :root_path,
  'admin.users.index' => :user_management_users_path,
  'admin.roles.index' => :user_management_roles_path
}

PERMISSION_PRIORITY = %w[
  dashboard
  work_orders
  payslip
  inventory
  workers
  master_data
  admin
]

# Usage:
UserRedirectService.first_accessible_path_for(user)
# => :work_orders_details_path
```

### 4. Policies (Pundit)

**Location**: `app/policies/**/*_policy.rb`

```ruby
# Example: app/policies/worker_policy.rb
class WorkerPolicy < ApplicationPolicy
  def self.permission_resource
    'workers'
  end

  def index?
    user.has_permission?('workers.index')
  end

  def create?
    user.has_permission?('workers.create')
  end
end

# Namespaced example: app/policies/work_orders/detail_policy.rb
class WorkOrders::DetailPolicy < ApplicationPolicy
  def self.permission_resource
    'work_orders.details'
  end
end
```

---

## How It Works

### 1. Convention-Based Path Resolution

The system automatically converts permission codes to Rails route helpers:

```ruby
# Automatic Conversion Algorithm:
# 1. Get permission code: "workers.index"
# 2. Remove .index suffix: "workers"
# 3. Convert dots to underscores: "workers" (no change)
# 4. Append _path: "workers_path"
# 5. Verify route exists: Rails.application.routes.url_helpers.respond_to?(:workers_path)
# 6. Return symbol: :workers_path

# More complex example:
# 1. "work_orders.details.index"
# 2. "work_orders.details"
# 3. "work_orders_details"
# 4. "work_orders_details_path"
# 5. Check if route exists ✓
# 6. :work_orders_details_path
```

### 2. User Login Redirect Flow

```
┌─────────────────────────────────────────────────────────────┐
│ 1. User logs in                                              │
│    ↓                                                          │
│ 2. Devise triggers after_sign_in_path_for(user)             │
│    ↓                                                          │
│ 3. ApplicationController calls user.first_accessible_path    │
│    ↓                                                          │
│ 4. User delegates to UserRedirectService                     │
│    ↓                                                          │
│ 5. Service checks if superadmin → return :root_path         │
│    ↓                                                          │
│ 6. Get all user's *.index permissions                        │
│    ↓                                                          │
│ 7. Sort by PERMISSION_PRIORITY                               │
│    ↓                                                          │
│ 8. For each permission:                                      │
│    a. Check SPECIAL_CASES                                    │
│    b. Convert code to path symbol                            │
│    c. Verify route exists                                    │
│    d. Return first valid path                                │
│    ↓                                                          │
│ 9. Fallback to :root_path if no valid path found            │
│    ↓                                                          │
│ 10. Controller calls send(path_symbol) → redirect           │
└─────────────────────────────────────────────────────────────┘
```

### 3. Permission Check Flow

```
┌─────────────────────────────────────────────────────────────┐
│ Controller Action Executed                                   │
│    ↓                                                          │
│ Pundit authorize @resource, :action?                         │
│    ↓                                                          │
│ Policy checks user.has_permission?('resource.action')        │
│    ↓                                                          │
│ User Model:                                                  │
│  - Return true if superadmin                                 │
│  - Check cached @permission_codes                            │
│  - Return true/false                                         │
│    ↓                                                          │
│ If authorized: Execute action                                │
│ If not: Raise Pundit::NotAuthorizedError → redirect         │
└─────────────────────────────────────────────────────────────┘
```

---

## Usage Examples

### Controller Authorization

```ruby
class WorkersController < ApplicationController
  def index
    authorize Worker, :index?
    @workers = Worker.all
  end

  def create
    authorize Worker, :create?
    @worker = Worker.new(worker_params)
    # ...
  end
end
```

### View Permission Checks

```erb
<!-- Sidebar Menu -->
<% if can_view_menu?('workers.index') %>
  <%= link_to "Workers", workers_path %>
<% end %>

<!-- Action Buttons -->
<% if current_user.has_permission?('workers.create') %>
  <%= link_to "New Worker", new_worker_path, class: "btn" %>
<% end %>

<% if current_user.has_permission?('workers.destroy') %>
  <%= link_to "Delete", worker_path(@worker), method: :delete %>
<% end %>
```

### Helper Methods

```ruby
# app/helpers/application_helper.rb
def can_view_menu?(permission_code)
  return true if current_user.superadmin?
  current_user.has_permission?(permission_code)
end
```

### Service Usage

```ruby
# Get user's first accessible path
path_symbol = UserRedirectService.first_accessible_path_for(user)
# => :workers_path

# Execute redirect
redirect_to send(path_symbol)
# => redirect_to workers_path
```

---

## Adding New Modules

### Step 1: Add Route

```ruby
# config/routes.rb
resources :projects  # Creates projects_path, new_project_path, etc.
```

### Step 2: Add Permissions to Seed

```ruby
# db/seeds/permissions.rb
resources = {
  # ... existing resources ...

  # New module
  'projects' => %w[index show new create edit update destroy],
}

# Add action name if custom
action_names = {
  # ... existing actions ...
  'archive' => 'Archive',  # If you have custom action
}
```

### Step 3: Create Policy

```ruby
# app/policies/project_policy.rb
class ProjectPolicy < ApplicationPolicy
  def self.permission_resource
    'projects'
  end

  def index?
    user.has_permission?('projects.index')
  end

  def create?
    user.has_permission?('projects.create')
  end

  # ... other actions ...
end
```

### Step 4: Run Seeds

```bash
docker compose exec web rails db:seed
```

### Step 5: Assign to Roles

```ruby
# db/seeds/development.rb or production.rb
clerk_permissions = Permission.where(code: [
  # ... existing permissions ...
  'projects.index',
  'projects.create',
  'projects.show'
]).pluck(:id)

clerk_role.update(permission_ids: clerk_permissions)
```

### Step 6: Update Sidebar (Optional)

```erb
<!-- app/views/layouts/dashboard/_sidebar.html.erb -->
<% if can_view_menu?('projects.index') %>
  <li>
    <%= link_to projects_path do %>
      <i class="fas fa-project-diagram"></i>
      <span>Projects</span>
    <% end %>
  </li>
<% end %>
```

### That's It! 🎉

The system automatically:

- ✅ Converts `projects.index` → `projects_path`
- ✅ Redirects users to projects if it's their first accessible resource
- ✅ Shows/hides menu items based on permissions
- ✅ No changes needed to `UserRedirectService` or other core files

---

## Best Practices

### 1. Permission Naming Convention

```ruby
# ✅ GOOD - Follows convention
'workers.index'              # Auto-maps to workers_path
'inventory.create'           # Auto-maps to inventory_index_path (via new/create)
'master_data.blocks.show'    # Auto-maps to master_data_blocks_path

# ❌ BAD - Requires manual mapping
'worker_list'                # Doesn't follow namespace.resource.action
'view_workers'               # Use .index instead of custom names
'workers-management.list'    # Use underscores, not dashes
```

### 2. Resource Organization

```ruby
# Single-level for simple resources
'workers'       # app/controllers/workers_controller.rb
'inventory'     # app/controllers/inventory_controller.rb

# Namespaced for grouped features
'work_orders.details'         # app/controllers/work_orders/details_controller.rb
'work_orders.approvals'       # app/controllers/work_orders/approvals_controller.rb
'master_data.blocks'          # app/controllers/master_data/blocks_controller.rb
```

### 3. Policy Structure

```ruby
# Single-level policy
class WorkerPolicy < ApplicationPolicy
  def self.permission_resource
    'workers'  # matches route: resources :workers
  end
end

# Namespaced policy
module WorkOrders
  class DetailPolicy < ApplicationPolicy
    def self.permission_resource
      'work_orders.details'  # matches route: namespace :work_orders { resources :details }
    end
  end
end
```

### 4. Performance Optimization

```ruby
# Cache permissions in User model
user.has_permission?('workers.index')  # First call: DB query
user.has_permission?('workers.create') # Cached: No DB query
user.has_permission?('inventory.show') # Cached: No DB query

# Clear cache when role changes
user.update(role: new_role)
user.clear_permission_cache!  # Important!
```

### 5. Superadmin Handling

```ruby
# Superadmin bypasses ALL permission checks
if user.superadmin?
  # Has access to everything
  # Always redirects to root_path (dashboard)
end

# In policies
def index?
  user.has_permission?('workers.index')  # Returns true for superadmin automatically
end
```

---

## Testing

### Model Tests

```ruby
# test/models/user_test.rb
test "user with permission can access resource" do
  permission = permissions(:workers_index)
  role = roles(:clerk)
  role.permissions << permission
  user = User.create!(name: "Test", email: "test@example.com", role: role)

  assert user.has_permission?('workers.index')
  assert_not user.has_permission?('workers.create')
end

test "superadmin bypasses all permission checks" do
  user = users(:superadmin)
  assert user.has_permission?('any.permission.here')
end
```

### Service Tests

```ruby
# test/services/user_redirect_service_test.rb
test "redirects to first accessible resource" do
  user = users(:field_conductor)
  service = UserRedirectService.new(user)

  assert_equal :work_orders_details_path, service.first_accessible_path
end

test "superadmin always redirects to root" do
  user = users(:superadmin)
  service = UserRedirectService.new(user)

  assert_equal :root_path, service.first_accessible_path
end

test "automatic path conversion works" do
  user = users(:clerk_with_workers_access)
  service = UserRedirectService.new(user)

  # Should convert workers.index → workers_path
  assert_equal :workers_path, service.first_accessible_path
end
```

### Integration Tests

```ruby
# test/integration/user_login_redirect_test.rb
test "user redirects to first accessible resource after login" do
  user = users(:field_conductor)

  post user_session_path, params: {
    user: { email: user.email, password: 'password' }
  }

  assert_redirected_to work_orders_details_path
end
```

### System Tests

```ruby
# test/system/permissions_test.rb
test "user cannot access unauthorized resources" do
  user = users(:clerk)
  sign_in user

  visit admin_users_path
  assert_text "You are not authorized"
end

test "sidebar only shows accessible menus" do
  user = users(:field_conductor)
  sign_in user

  visit root_path
  assert_selector "a[href='#{work_orders_details_path}']"
  assert_no_selector "a[href='#{admin_users_path}']"
end
```

---

## Troubleshooting

### Issue: User redirects to root_path instead of expected resource

**Diagnosis:**

```ruby
# Run in rails console
user = User.find_by(email: 'user@example.com')
service = UserRedirectService.new(user)

# Check permissions
puts user.role.permissions.where("code LIKE '%.index'").pluck(:code)
# => ["work_orders.details.index"]

# Check path resolution
service.send(:permission_to_path_symbol, 'work_orders.details.index')
# => :work_orders_details_path

# Check if route exists
Rails.application.routes.url_helpers.respond_to?(:work_orders_details_path)
# => true or false
```

**Solutions:**

1. Verify route exists: `docker compose exec web rails routes | grep work_orders_details`
2. Check permission code format: Must be `namespace.resource.action`
3. Verify permission is assigned to user's role

---

### Issue: New module doesn't auto-redirect

**Diagnosis:**

```ruby
# Check permission exists and follows convention
permission = Permission.find_by(code: 'projects.index')
permission.code  # Should be "projects.index"

# Check route matches convention
Rails.application.routes.url_helpers.respond_to?(:projects_path)
# Should return true

# Test path conversion
service = UserRedirectService.new(user)
service.send(:permission_to_path_symbol, 'projects.index')
# Should return :projects_path
```

**Solutions:**

1. Ensure route name matches converted permission code
2. If custom route, add to `SPECIAL_CASES` in `UserRedirectService`
3. Verify permission code follows format: `resource.action` or `namespace.resource.action`

---

### Issue: Permission validation fails

**Diagnosis:**

```ruby
# Check permission format
permission = Permission.new(code: 'Invalid.Code', resource: 'invalid', name: 'Test')
permission.valid?
permission.errors.full_messages
```

**Solutions:**

```ruby
# ✅ Correct formats:
'workers.index'              # lowercase, dots separate parts
'work_orders.details.show'   # multiple namespaces OK
'master_data.blocks.create'  # underscores in words OK

# ❌ Invalid formats:
'Workers.Index'              # No uppercase
'workers'                    # Must have at least one dot
'workers-index'              # No dashes, use dots
'workers..index'             # No double dots
```

---

### Issue: Redirect loop when accessing unauthorized pages

**Symptoms:**

- User tries to access a page without permission
- Gets redirected to the same page repeatedly
- Browser shows "Too many redirects" error

**Diagnosis:**

```ruby
# Check in logs:
rescue_from handled Pundit::NotAuthorizedError
Redirected to http://localhost:3000/work_orders/details
# ... then again to same URL (loop!)
```

**Root Cause:**
The `user_not_authorized` method was trying to redirect to the current controller's index action, which could be the same page the user just tried to access.

**Solution (Already Fixed):**

```ruby
# app/controllers/application_controller.rb
def user_not_authorized
  flash[:alert] = 'You are not authorized to perform this action.'

  # Prevent redirect loops by checking referrer
  redirect_path = if request.referrer.present? && request.referrer != request.url
                    # Redirect to previous page if it exists and is different
                    request.referrer
                  else
                    # Redirect to user's first accessible resource
                    send(current_user.first_accessible_path)
                  end

  redirect_to redirect_path, allow_other_host: true
end
```

**How it works:**

1. User tries to access unauthorized page (e.g., `/inventory`)
2. Pundit raises `NotAuthorizedError`
3. Check if referrer exists and is different from current URL
4. If yes: redirect back to previous page (safe)
5. If no: redirect to user's first accessible resource (e.g., `/work_orders/details`)
6. No infinite loops! ✅

---

### Issue: Cache not clearing after role change

**Solution:**

```ruby
# Always clear cache when changing user role
user.update(role: new_role)
user.clear_permission_cache!

# Or in controller:
if @user.update(user_params)
  @user.clear_permission_cache!
  redirect_to @user, notice: 'Updated successfully'
end
```

---

### Issue: Path doesn't match convention

**Example:** Route is `/user_management/users` but permission is `admin.users.index`

**Solution:** Add to `SPECIAL_CASES`

```ruby
# app/services/user_redirect_service.rb
SPECIAL_CASES = {
  'dashboard.index' => :root_path,
  'admin.users.index' => :user_management_users_path,  # Special mapping
  'admin.roles.index' => :user_management_roles_path,   # Special mapping
  'projects.index' => :custom_projects_path             # Add your special case
}.freeze
```

---

## Quick Reference

### Permission Code Format

```
namespace.resource.action
   ↓        ↓        ↓
workers.index        → workers_path
work_orders.details.index → work_orders_details_path
master_data.blocks.create → master_data_blocks_path
```

### Standard Actions

```ruby
index   # List resources     → resource_path
show    # View one resource  → resource_path(id)
new     # New form           → new_resource_path
create  # Create resource    → resources_path (POST)
edit    # Edit form          → edit_resource_path(id)
update  # Update resource    → resource_path(id) (PATCH)
destroy # Delete resource    → resource_path(id) (DELETE)
```

### Common Patterns

```ruby
# Check permission
current_user.has_permission?('workers.index')

# Authorize in controller
authorize Worker, :index?

# View helper
can_view_menu?('workers.index')

# Get redirect path
UserRedirectService.first_accessible_path_for(user)
```

---

## Summary

This permission system provides a **self-maintaining, convention-based authorization** framework that:

1. **Reduces maintenance** by 78% (3 special cases vs 14 full mappings)
2. **Follows SOLID principles** for clean, testable code
3. **Automatically handles new modules** without code changes
4. **Provides clear conventions** for predictable behavior
5. **Optimizes performance** with intelligent caching

**Key Takeaway:** Add new modules by following the naming convention, and everything else works automatically! 🚀
