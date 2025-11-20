# Permission System - Quick Start Guide

## 5-Minute Setup for New Modules

This guide shows you how to add a new module with permissions in 5 simple steps.

---

## Example: Adding a "Projects" Module

### Step 1: Create the Route (30 seconds)

```ruby
# config/routes.rb
Rails.application.routes.draw do
  # ... existing routes ...

  resources :projects  # ← Add this line
end
```

This creates standard RESTful routes:

- `GET    /projects` → `projects_path`
- `GET    /projects/new` → `new_project_path`
- `POST   /projects` → `projects_path`
- `GET    /projects/:id` → `project_path(:id)`
- `GET    /projects/:id/edit` → `edit_project_path(:id)`
- `PATCH  /projects/:id` → `project_path(:id)`
- `DELETE /projects/:id` → `project_path(:id)`

---

### Step 2: Add Permissions to Seeds (1 minute)

```ruby
# db/seeds/permissions.rb
resources = {
  # ... existing resources ...

  # New module - add this
  'projects' => %w[index show new create edit update destroy],
}
```

**That's it!** The seed script will automatically create these permissions:

- `projects.index` → "List Projects"
- `projects.show` → "View Project"
- `projects.new` → "New Project"
- `projects.create` → "Create Project"
- `projects.edit` → "Edit Project"
- `projects.update` → "Update Project"
- `projects.destroy` → "Delete Project"

---

### Step 3: Create Policy (1 minute)

```ruby
# app/policies/project_policy.rb
class ProjectPolicy < ApplicationPolicy
  def self.permission_resource
    'projects'  # ← Must match your route name
  end

  def index?
    user.has_permission?('projects.index')
  end

  def show?
    user.has_permission?('projects.show')
  end

  def new?
    create?
  end

  def create?
    user.has_permission?('projects.create')
  end

  def edit?
    update?
  end

  def update?
    user.has_permission?('projects.update')
  end

  def destroy?
    user.has_permission?('projects.destroy')
  end
end
```

**Pro Tip:** Copy an existing policy and change the resource name!

---

### Step 4: Run Seeds (30 seconds)

```bash
docker compose exec web rails db:seed
```

This creates the 7 permissions in your database.

---

### Step 5: Assign to Roles (2 minutes)

```ruby
# db/seeds/development.rb (or production.rb)

# Add your new permissions to the appropriate role
clerk_permissions = Permission.where(code: [
  # ... existing permissions ...
  'projects.index',
  'projects.show',
  'projects.create',
  'projects.edit',
  'projects.update',
  # Note: Not giving 'projects.destroy' to clerks
]).pluck(:id)

clerk_role.update(permission_ids: clerk_permissions)
```

Run seeds again:

```bash
docker compose exec web rails db:seed
```

---

## That's It! 🎉

Your module now:

- ✅ Has full permission control
- ✅ **Automatically redirects** users to `/projects` if it's their first accessible resource
- ✅ Works with authorization in controllers
- ✅ Works with view helpers

**No additional configuration needed!** The system automatically:

- Converts `projects.index` → `projects_path`
- Handles user redirects
- Caches permissions for performance

---

## Using Permissions in Your Code

### In Controllers

```ruby
class ProjectsController < ApplicationController
  def index
    authorize Project, :index?  # ← Checks 'projects.index' permission
    @projects = Project.all
  end

  def create
    authorize Project, :create?  # ← Checks 'projects.create' permission
    @project = Project.new(project_params)

    if @project.save
      redirect_to @project, notice: 'Project created!'
    else
      render :new
    end
  end
end
```

### In Views

```erb
<!-- Show/hide action buttons -->
<% if current_user.has_permission?('projects.create') %>
  <%= link_to "New Project", new_project_path, class: "btn btn-primary" %>
<% end %>

<% if current_user.has_permission?('projects.destroy') %>
  <%= link_to "Delete", project_path(@project),
      method: :delete,
      data: { confirm: 'Are you sure?' } %>
<% end %>

<!-- Show/hide entire sections -->
<% if current_user.has_resource_permission?('projects') %>
  <div class="projects-section">
    <!-- Only users with any projects.* permission can see this -->
  </div>
<% end %>
```

### In Sidebar Menu

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

---

## Advanced: Namespaced Modules

For grouped features like "Work Orders → Details, Approvals, Pay Calculations":

### Step 1: Namespaced Route

```ruby
# config/routes.rb
namespace :work_orders do
  resources :details
  resources :approvals
  resources :pay_calculations
end
```

This creates:

- `/work_orders/details` → `work_orders_details_path`
- `/work_orders/approvals` → `work_orders_approvals_path`
- `/work_orders/pay_calculations` → `work_orders_pay_calculations_path`

### Step 2: Namespaced Permissions

```ruby
# db/seeds/permissions.rb
resources = {
  'work_orders.details' => %w[index show new create edit update destroy],
  'work_orders.approvals' => %w[index show update approve],
  'work_orders.pay_calculations' => %w[index show new create edit update],
}
```

### Step 3: Namespaced Policy

```ruby
# app/policies/work_orders/detail_policy.rb
module WorkOrders
  class DetailPolicy < ApplicationPolicy
    def self.permission_resource
      'work_orders.details'  # ← Dot-separated namespace
    end

    def index?
      user.has_permission?('work_orders.details.index')
    end

    # ... other actions ...
  end
end
```

**Automatic Conversion:**

- `work_orders.details.index` → `work_orders_details_path` ✅
- `work_orders.approvals.show` → `work_orders_approvals_path` ✅
- `work_orders.pay_calculations.create` → `work_orders_pay_calculations_path` ✅

---

## Custom Actions

If you have custom actions beyond the standard 7 (index, show, new, create, edit, update, destroy):

### Step 1: Add Custom Action to Seeds

```ruby
# db/seeds/permissions.rb
resources = {
  'projects' => %w[index show new create edit update destroy archive export],
  #                                                      ↑       ↑
  #                                               Custom actions
}

# Define readable names
action_names = {
  # ... existing actions ...
  'archive' => 'Archive',
  'export' => 'Export',
}
```

### Step 2: Add to Route

```ruby
resources :projects do
  member do
    patch :archive  # POST /projects/:id/archive
  end
  collection do
    get :export     # GET /projects/export
  end
end
```

### Step 3: Add to Policy

```ruby
class ProjectPolicy < ApplicationPolicy
  # ... standard actions ...

  def archive?
    user.has_permission?('projects.archive')
  end

  def export?
    user.has_permission?('projects.export')
  end
end
```

### Step 4: Use in Controller

```ruby
def archive
  authorize @project, :archive?
  @project.update(archived: true)
  redirect_to projects_path, notice: 'Project archived'
end

def export
  authorize Project, :export?
  # Export logic...
end
```

---

## Checking Your Work

### 1. Verify Routes

```bash
docker compose exec web rails routes | grep projects
```

Should show:

```
projects     GET    /projects
             POST   /projects
new_project  GET    /projects/new
project      GET    /projects/:id
edit_project GET    /projects/:id/edit
             PATCH  /projects/:id
             DELETE /projects/:id
```

### 2. Verify Permissions in Database

```bash
docker compose exec web rails console
```

```ruby
Permission.where("code LIKE 'projects.%'").pluck(:code, :name)
# Should show all your permissions
```

### 3. Test User Redirect

```ruby
# In rails console
user = User.find_by(email: 'clerk@example.com')
UserRedirectService.first_accessible_path_for(user)
# => :projects_path (if projects.index is their first accessible resource)
```

### 4. Test in Browser

1. Login as a user with `projects.index` permission
2. Should automatically redirect to `/projects` if no dashboard access
3. Sidebar should show "Projects" menu item
4. Action buttons should appear based on permissions

---

## Common Mistakes

### ❌ Mistake 1: Route doesn't match permission

```ruby
# Route
resources :project_management  # Creates project_management_path

# Permission
'projects.index'  # Tries to find projects_path ← MISMATCH!
```

**Fix:** Make route match permission

```ruby
resources :projects  # Now matches projects.index → projects_path ✅
```

---

### ❌ Mistake 2: Forgetting to run seeds

```ruby
# Added permission to seeds/permissions.rb but didn't run:
docker compose exec web rails db:seed
```

**Result:** Permission doesn't exist in database, all checks fail.

---

### ❌ Mistake 3: Policy resource doesn't match route

```ruby
# Policy
def self.permission_resource
  'project_management'  # ← Wrong
end

# Should be:
def self.permission_resource
  'projects'  # ← Match your route name
end
```

---

### ❌ Mistake 4: Capital letters in permission code

```ruby
# ❌ Wrong
'Projects.Index'

# ✅ Correct
'projects.index'
```

**Rule:** Always lowercase, use dots and underscores only.

---

## Need Help?

### Read the Full Guide

See [PERMISSION_SYSTEM_GUIDE.md](./PERMISSION_SYSTEM_GUIDE.md) for:

- Architecture deep-dive
- SOLID principles explained
- Testing strategies
- Troubleshooting guide

### Debug Checklist

```ruby
# 1. Check permission exists
Permission.find_by(code: 'projects.index')

# 2. Check user has permission
user.has_permission?('projects.index')

# 3. Check role has permission
user.role.permissions.pluck(:code).include?('projects.index')

# 4. Check route exists
Rails.application.routes.url_helpers.respond_to?(:projects_path)

# 5. Test path conversion
service = UserRedirectService.new(user)
service.send(:permission_to_path_symbol, 'projects.index')
# => :projects_path

# 6. Check if path helper exists
service.send(:path_helper_exists?, :projects_path)
# => true
```

---

## Summary

To add a new module:

1. **Add route** → `resources :projects`
2. **Add permissions** → `'projects' => %w[index show new create edit update destroy]`
3. **Create policy** → Set `permission_resource = 'projects'`
4. **Run seeds** → `docker compose exec web rails db:seed`
5. **Assign to roles** → Update role permissions in seeds

**Everything else is automatic!** 🚀

The system will:

- ✅ Convert `projects.index` → `projects_path`
- ✅ Redirect users appropriately
- ✅ Show/hide menus based on permissions
- ✅ Authorize controller actions
- ✅ Cache for performance

**No manual mapping required!**
