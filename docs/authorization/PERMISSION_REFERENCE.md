# Permission System - Technical Reference

Quick reference for developers working with the permission system.

---

## Permission Format

```
namespace.resource.action
   ↓        ↓        ↓
Simple:    workers.index
Namespaced: work_orders.details.index
```

**Rules:**

- All lowercase
- Dots separate parts
- Underscores within words
- Must have at least one dot
- Regex: `/\A[a-z][a-z0-9_]*(\.[a-z][a-z0-9_]*)+\z/`

---

## Automatic Path Conversion

```ruby
# Algorithm
'workers.index'
  → remove '.index'
  → 'workers'
  → add '_path'
  → :workers_path

'work_orders.details.index'
  → remove '.index'
  → 'work_orders.details'
  → replace '.' with '_'
  → 'work_orders_details'
  → add '_path'
  → :work_orders_details_path
```

---

## API Reference

### User Model

```ruby
# Permission checks
user.has_permission?('workers.index')           # Check specific permission
user.has_resource_permission?('workers')        # Check any workers.* permission
user.superadmin?                                # True if superadmin (bypasses all checks)

# Redirect
user.first_accessible_path                      # Get first accessible path symbol

# Cache management
user.clear_permission_cache!                    # Clear after role change
```

### UserRedirectService

```ruby
# Class method
UserRedirectService.first_accessible_path_for(user)
# => :workers_path

# Instance usage
service = UserRedirectService.new(user)
service.first_accessible_path
# => :workers_path

# Constants
UserRedirectService::SPECIAL_CASES              # Hash of special mappings
UserRedirectService::PERMISSION_PRIORITY        # Array of namespace priority
```

### Permission Model

```ruby
# Instance methods
permission.namespace    # Extract namespace from code
permission.action       # Extract action from code

# Validations
validates :code, format: /\A[a-z][a-z0-9_]*(\.[a-z][a-z0-9_]*)+\z/
validates :resource, format: /\A[a-z][a-z0-9_]*(\.[a-z][a-z0-9_]*)*\z/
```

### Policy Base

```ruby
class SomePolicy < ApplicationPolicy
  def self.permission_resource
    'resource_name'  # Must match route name or be in SPECIAL_CASES
  end

  def index?
    user.has_permission?('resource_name.index')
  end
end
```

---

## Controller Patterns

### Standard CRUD

```ruby
class ResourcesController < ApplicationController
  def index
    authorize Resource, :index?
    @resources = Resource.all
  end

  def show
    @resource = Resource.find(params[:id])
    authorize @resource, :show?
  end

  def new
    @resource = Resource.new
    authorize @resource, :new?
  end

  def create
    @resource = Resource.new(resource_params)
    authorize @resource, :create?

    if @resource.save
      redirect_to @resource
    else
      render :new
    end
  end

  def edit
    @resource = Resource.find(params[:id])
    authorize @resource, :edit?
  end

  def update
    @resource = Resource.find(params[:id])
    authorize @resource, :update?

    if @resource.update(resource_params)
      redirect_to @resource
    else
      render :edit
    end
  end

  def destroy
    @resource = Resource.find(params[:id])
    authorize @resource, :destroy?
    @resource.destroy
    redirect_to resources_path
  end
end
```

---

## View Patterns

### Menu Visibility

```erb
<!-- Single menu item -->
<% if can_view_menu?('workers.index') %>
  <%= link_to "Workers", workers_path %>
<% end %>

<!-- Dropdown menu -->
<% has_access = can_view_menu?('resource.sub1.index') ||
                can_view_menu?('resource.sub2.index') %>
<% if has_access %>
  <li class="dropdown">
    <a href="#">Resource</a>
    <ul>
      <% if can_view_menu?('resource.sub1.index') %>
        <li><%= link_to "Sub 1", resource_sub1_path %></li>
      <% end %>
      <% if can_view_menu?('resource.sub2.index') %>
        <li><%= link_to "Sub 2", resource_sub2_path %></li>
      <% end %>
    </ul>
  </li>
<% end %>
```

### Action Buttons

```erb
<!-- Create button -->
<% if current_user.has_permission?('workers.create') %>
  <%= link_to "New Worker", new_worker_path, class: "btn btn-primary" %>
<% end %>

<!-- Edit button -->
<% if current_user.has_permission?('workers.update') %>
  <%= link_to "Edit", edit_worker_path(@worker), class: "btn btn-secondary" %>
<% end %>

<!-- Delete button -->
<% if current_user.has_permission?('workers.destroy') %>
  <%= link_to "Delete",
      worker_path(@worker),
      method: :delete,
      data: { confirm: 'Are you sure?' },
      class: "btn btn-danger" %>
<% end %>

<!-- Bulk actions -->
<div class="actions">
  <% if current_user.has_permission?('workers.create') %>
    <%= link_to "New", new_worker_path %>
  <% end %>
  <% if current_user.has_permission?('workers.export') %>
    <%= link_to "Export", export_workers_path %>
  <% end %>
  <% if current_user.has_permission?('workers.import') %>
    <%= link_to "Import", import_workers_path %>
  <% end %>
</div>
```

### Conditional Rendering

```erb
<!-- Show entire section -->
<% if current_user.has_resource_permission?('workers') %>
  <section class="workers-section">
    <h2>Workers Management</h2>
    <!-- Content -->
  </section>
<% end %>

<!-- Show based on multiple permissions -->
<% if current_user.has_permission?('reports.view') || current_user.superadmin? %>
  <div class="reports">
    <!-- Reports content -->
  </div>
<% end %>
```

---

## Route Patterns

### Simple Resource

```ruby
# config/routes.rb
resources :workers

# Creates:
workers_path            # GET    /workers
new_worker_path         # GET    /workers/new
worker_path(id)         # GET    /workers/:id
edit_worker_path(id)    # GET    /workers/:id/edit
                        # POST   /workers
                        # PATCH  /workers/:id
                        # DELETE /workers/:id

# Permissions:
workers.index
workers.show
workers.new
workers.create
workers.edit
workers.update
workers.destroy
```

### Namespaced Resource

```ruby
# config/routes.rb
namespace :work_orders do
  resources :details
end

# Creates:
work_orders_details_path            # GET    /work_orders/details
new_work_orders_detail_path         # GET    /work_orders/details/new
work_orders_detail_path(id)         # GET    /work_orders/details/:id
edit_work_orders_detail_path(id)    # GET    /work_orders/details/:id/edit
                                    # POST   /work_orders/details
                                    # PATCH  /work_orders/details/:id
                                    # DELETE /work_orders/details/:id

# Permissions:
work_orders.details.index
work_orders.details.show
work_orders.details.new
work_orders.details.create
work_orders.details.edit
work_orders.details.update
work_orders.details.destroy
```

### Custom Actions (Member)

```ruby
# config/routes.rb
resources :workers do
  member do
    patch :activate    # PATCH /workers/:id/activate
    patch :deactivate  # PATCH /workers/:id/deactivate
  end
end

# Creates additional routes:
activate_worker_path(id)
deactivate_worker_path(id)

# Add permissions:
workers.activate
workers.deactivate
```

### Custom Actions (Collection)

```ruby
# config/routes.rb
resources :workers do
  collection do
    get :export        # GET /workers/export
    post :import       # POST /workers/import
  end
end

# Creates additional routes:
export_workers_path
import_workers_path

# Add permissions:
workers.export
workers.import
```

---

## Seed Patterns

### Simple Resource

```ruby
# db/seeds/permissions.rb
resources = {
  'workers' => %w[index show new create edit update destroy]
}
```

### Namespaced Resource

```ruby
# db/seeds/permissions.rb
resources = {
  'work_orders.details' => %w[index show new create edit update destroy]
}
```

### With Custom Actions

```ruby
# db/seeds/permissions.rb
resources = {
  'workers' => %w[index show new create edit update destroy activate deactivate export import]
}

action_names = {
  'index' => 'List',
  'show' => 'View',
  'new' => 'New',
  'create' => 'Create',
  'edit' => 'Edit',
  'update' => 'Update',
  'destroy' => 'Delete',
  'activate' => 'Activate',
  'deactivate' => 'Deactivate',
  'export' => 'Export',
  'import' => 'Import'
}
```

### Role Assignment

```ruby
# db/seeds/development.rb or production.rb

# Method 1: Explicit permission codes
clerk_permissions = Permission.where(code: [
  'workers.index',
  'workers.show',
  'workers.create'
]).pluck(:id)

clerk_role.update(permission_ids: clerk_permissions)

# Method 2: Pattern matching (use carefully)
all_worker_perms = Permission.where("code LIKE 'workers.%'").pluck(:id)
clerk_role.update(permission_ids: all_worker_perms)

# Method 3: Multiple resources
permissions = Permission.where(code: [
  # Workers
  'workers.index', 'workers.show', 'workers.create',
  # Inventory
  'inventory.index', 'inventory.show',
  # Dashboard
  'dashboard.index'
]).pluck(:id)

clerk_role.update(permission_ids: permissions)
```

---

## Testing Patterns

### Model Tests

```ruby
# test/models/user_test.rb
test "has_permission? returns true when user has permission" do
  user = users(:clerk)
  assert user.has_permission?('workers.index')
end

test "has_permission? returns false when user lacks permission" do
  user = users(:clerk)
  assert_not user.has_permission?('user_management.users.index')
end

test "superadmin bypasses all permission checks" do
  user = users(:superadmin)
  assert user.has_permission?('any.random.permission')
end

test "clear_permission_cache! clears cached permissions" do
  user = users(:clerk)
  user.has_permission?('workers.index')  # Cache permissions

  # Change role
  user.update(role: roles(:manager))
  user.clear_permission_cache!

  # Should reflect new role permissions
  assert user.has_permission?('work_orders.approvals.approve')
end
```

### Service Tests

```ruby
# test/services/user_redirect_service_test.rb
test "first_accessible_path returns root for superadmin" do
  user = users(:superadmin)
  assert_equal :root_path, UserRedirectService.first_accessible_path_for(user)
end

test "first_accessible_path returns first accessible resource" do
  user = users(:field_conductor)
  assert_equal :work_orders_details_path, UserRedirectService.first_accessible_path_for(user)
end

test "permission_to_path_symbol converts correctly" do
  user = users(:clerk)
  service = UserRedirectService.new(user)

  assert_equal :workers_path,
               service.send(:permission_to_path_symbol, 'workers.index')

  assert_equal :work_orders_details_path,
               service.send(:permission_to_path_symbol, 'work_orders.details.index')
end
```

### Controller Tests

```ruby
# test/controllers/workers_controller_test.rb
test "index requires permission" do
  sign_in users(:user_without_workers_access)
  get workers_url
  assert_redirected_to root_path
  assert_equal 'You are not authorized to perform this action.', flash[:alert]
end

test "index works with permission" do
  sign_in users(:clerk)
  get workers_url
  assert_response :success
end

test "create requires permission" do
  sign_in users(:user_without_create_access)
  post workers_url, params: { worker: { name: 'Test' } }
  assert_redirected_to root_path
end
```

### Integration Tests

```ruby
# test/integration/user_redirect_flow_test.rb
test "user redirects to first accessible path after login" do
  user = users(:field_conductor)

  post user_session_url, params: {
    user: { email: user.email, password: 'password' }
  }

  assert_redirected_to work_orders_details_path
  follow_redirect!
  assert_response :success
end

test "user with dashboard access redirects to root" do
  user = users(:manager)

  post user_session_url, params: {
    user: { email: user.email, password: 'password' }
  }

  assert_redirected_to root_path
end
```

---

## Console Commands

### Check Permissions

```ruby
# Get all permissions
Permission.pluck(:code, :name)

# Get permissions for specific resource
Permission.where("code LIKE 'workers.%'").pluck(:code, :name)

# Check if permission exists
Permission.exists?(code: 'workers.index')

# Find permission
Permission.find_by(code: 'workers.index')
```

### Check User Permissions

```ruby
# Get user
user = User.find_by(email: 'clerk@example.com')

# Check permission
user.has_permission?('workers.index')

# Get all user's permissions
user.role.permissions.pluck(:code)

# Get user's redirect path
UserRedirectService.first_accessible_path_for(user)

# Check if superadmin
user.superadmin?
```

### Check Routes

```ruby
# Check if route exists
Rails.application.routes.url_helpers.respond_to?(:workers_path)

# Get path
Rails.application.routes.url_helpers.workers_path

# List all routes
Rails.application.routes.routes.map(&:name).compact.sort

# Search for routes
Rails.application.routes.routes
  .map(&:name)
  .compact
  .select { |name| name.include?('workers') }
```

### Debug Path Conversion

```ruby
user = User.first
service = UserRedirectService.new(user)

# Test conversion
service.send(:permission_to_path_symbol, 'workers.index')
# => :workers_path

service.send(:permission_to_path_symbol, 'work_orders.details.index')
# => :work_orders_details_path

# Check if path exists
service.send(:path_helper_exists?, :workers_path)
# => true
```

### Seed Operations

```bash
# Run all seeds
docker compose exec web rails db:seed

# Reset and seed
docker compose exec web rails db:reset

# Drop, create, migrate, seed
docker compose exec web rails db:drop db:create db:migrate db:seed

# Seed specific environment
docker compose exec web rails db:seed RAILS_ENV=production
```

---

## Constants Reference

### SPECIAL_CASES (UserRedirectService)

```ruby
{
  'dashboard.index' => :root_path,
  'user_management.users.index' => :user_management_users_path,
  'user_management.roles.index' => :user_management_roles_path
}
```

**When to add:**

- Route name doesn't match convention
- Multiple resources map to same path
- Legacy route names

### PERMISSION_PRIORITY (UserRedirectService)

```ruby
%w[
  dashboard
  work_orders
  payslip
  inventory
  workers
  master_data
  user_management
]
```

**Purpose:** Determines redirect order when user has multiple permissions

---

## Standard Actions

```ruby
# RESTful actions
index    # List all resources
show     # View single resource
new      # New form
create   # Create resource
edit     # Edit form
update   # Update resource
destroy  # Delete resource

# Common custom actions
approve       # Approve item
export        # Export data
import        # Import data
archive       # Archive item
activate      # Activate item
deactivate    # Deactivate item
duplicate     # Duplicate item
publish       # Publish item
```

---

## Error Messages

### Permission Validation Errors

```
Code can't be blank
Code is invalid (must be lowercase, dot-separated)
Resource can't be blank
Resource is invalid (must be lowercase, dot or underscore separated)
Name can't be blank
```

### Authorization Errors

```
You are not authorized to perform this action.
```

**Triggered by:** `Pundit::NotAuthorizedError`
**Handling:** `ApplicationController#user_not_authorized`

---

## File Locations

```
app/
  controllers/
    application_controller.rb          # after_sign_in_path_for override
  helpers/
    application_helper.rb              # can_view_menu? helper
  models/
    permission.rb                      # Permission model
    user.rb                           # User model with permission methods
  policies/
    application_policy.rb             # Base policy
    resource_policy.rb                # Resource-specific policies
  services/
    user_redirect_service.rb          # Redirect logic
  views/
    layouts/dashboard/
      _sidebar.html.erb               # Menu with permission checks

config/
  routes.rb                           # Route definitions

db/
  seeds/
    permissions.rb                    # Permission definitions
    development.rb                    # Development role assignments
    production.rb                     # Production role assignments

docs/
  PERMISSION_SYSTEM_GUIDE.md          # Full guide
  PERMISSION_QUICK_START.md           # Quick start
  PERMISSION_REFERENCE.md             # This file

test/
  models/
    user_test.rb                      # User model tests
    permission_test.rb                # Permission model tests
  services/
    user_redirect_service_test.rb    # Service tests
```

---

## Cheat Sheet

```ruby
# Check permission
user.has_permission?('resource.action')

# Check any permission for resource
user.has_resource_permission?('resource')

# Is superadmin?
user.superadmin?

# Get redirect path
user.first_accessible_path

# Clear cache
user.clear_permission_cache!

# Authorize in controller
authorize Resource, :action?

# View helper
can_view_menu?('resource.action')

# Service
UserRedirectService.first_accessible_path_for(user)
```

---

## Convention Summary

```
Permission Code:  namespace.resource.action
Route Helper:     namespace_resource_path
Policy Resource:  'namespace.resource'
Controller:       Namespace::ResourceController
Policy:           Namespace::ResourcePolicy

Example:
Code:       work_orders.details.index
Path:       work_orders_details_path
Resource:   'work_orders.details'
Controller: WorkOrders::DetailsController
Policy:     WorkOrders::DetailPolicy
```

**Remember:** Everything must match or be in SPECIAL_CASES!

---

## Quick Troubleshooting

```ruby
# Permission not working?
1. Permission.exists?(code: 'resource.action')  # Exists in DB?
2. user.role.permissions.pluck(:code)           # Assigned to role?
3. user.clear_permission_cache!                 # Cache stale?

# Redirect not working?
1. Rails.application.routes.url_helpers.respond_to?(:path_name)  # Route exists?
2. UserRedirectService.first_accessible_path_for(user)           # What path returns?
3. Check SPECIAL_CASES if route name doesn't match convention

# Authorization failing?
1. user.has_permission?('resource.action')      # Has permission?
2. Check policy permission_resource matches route
3. Check authorize call in controller

# Redirect loop?
1. Check ApplicationController#user_not_authorized
2. Ensure referrer != current_url check is present
3. Verify redirects to first_accessible_path, not controller index
```

### Preventing Redirect Loops

**Issue:** User gets redirected infinitely when accessing unauthorized pages

**Solution (Already Implemented):**

```ruby
# app/controllers/application_controller.rb
def user_not_authorized
  flash[:alert] = 'You are not authorized to perform this action.'

  redirect_path = if request.referrer.present? && request.referrer != request.url
                    request.referrer  # Safe: go back
                  else
                    send(current_user.first_accessible_path)  # Safe: different page
                  end

  redirect_to redirect_path, allow_other_host: true
end
```

**Key Points:**

- ✅ Checks `referrer != request.url` to prevent loops
- ✅ Falls back to `first_accessible_path` if no valid referrer
- ✅ Never redirects to same page user just tried

---

**Full Documentation:** [PERMISSION_SYSTEM_GUIDE.md](./PERMISSION_SYSTEM_GUIDE.md)
**Quick Start:** [PERMISSION_QUICK_START.md](./PERMISSION_QUICK_START.md)
