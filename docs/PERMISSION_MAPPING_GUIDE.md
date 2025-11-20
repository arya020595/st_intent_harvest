# Permission System Mapping Guide

## Overview

This guide helps you map your existing Pundit policies to the new permission code system.

## Permission Code Format

```
namespace.resource.action
```

**Examples:**

- `admin.users.index` - List users in admin panel
- `workorders.orders.create` - Create work orders
- `hr.employees.destroy` - Delete employees

## Standard Rails Actions Mapping

| Rails Action | Permission Action | Description                               |
| ------------ | ----------------- | ----------------------------------------- |
| `index`      | `index`           | List/view all records                     |
| `show`       | `show`            | View single record                        |
| `new`        | `create`          | Show create form (uses create permission) |
| `create`     | `create`          | Create new record                         |
| `edit`       | `update`          | Show edit form (uses update permission)   |
| `update`     | `update`          | Update existing record                    |
| `destroy`    | `destroy`         | Delete record                             |

## Custom Actions

For custom actions, use descriptive names:

| Custom Action | Permission Code Example      | Description         |
| ------------- | ---------------------------- | ------------------- |
| `approve`     | `workorders.orders.approve`  | Approve work orders |
| `complete`    | `workorders.orders.complete` | Mark as complete    |
| `export`      | `reports.sales.export`       | Export data         |
| `process`     | `hr.payroll.process`         | Process payroll     |
| `adjust`      | `inventory.stock.adjust`     | Adjust stock levels |

## Policy Implementation

### Basic Policy (Inherits all defaults)

```ruby
# frozen_string_literal: true

class WorkerPolicy < ApplicationPolicy
  private

  def permission_resource
    'hr.employees'
  end

  class Scope < ApplicationPolicy::Scope
    private

    def permission_resource
      'hr.employees'
    end
  end
end
```

### Policy with Custom Actions

```ruby
# frozen_string_literal: true

module WorkOrders
  class DetailPolicy < ApplicationPolicy
    # Custom action
    def mark_complete?
      user.has_permission?(build_permission_code('complete')) && editable?
    end

    # Can add additional business logic
    def edit?
      editable?
    end

    private

    def permission_resource
      'workorders.orders'
    end

    def editable?
      record.work_order_status.in?(%w[ongoing amendment_required])
    end

    class Scope < ApplicationPolicy::Scope
      private

      def permission_resource
        'workorders.orders'
      end
    end
  end
end
```

### Headless Resource Policy (Dashboard, Settings, etc.)

```ruby
# frozen_string_literal: true

class DashboardPolicy < ApplicationPolicy
  private

  def permission_resource
    'admin.dashboard'
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      scope # Return scope as-is for headless resources
    end
  end
end
```

## Resource Namespace Mapping

Map your models/controllers to appropriate namespaces:

| Model/Controller | Namespace    | Resource           | Full Code                 |
| ---------------- | ------------ | ------------------ | ------------------------- |
| `User`           | `admin`      | `users`            | `admin.users.index`       |
| `Role`           | `admin`      | `roles`            | `admin.roles.index`       |
| `Worker`         | `hr`         | `employees`        | `hr.employees.index`      |
| `Inventory`      | `inventory`  | `items`            | `inventory.items.index`   |
| `WorkOrder`      | `workorders` | `orders`           | `workorders.orders.index` |
| `PayCalculation` | `hr`         | `payroll`          | `hr.payroll.index`        |
| `Vehicle`        | `inventory`  | `items` or `admin` | `inventory.items.index`   |
| `Block`          | `admin`      | `blocks`           | `admin.blocks.index`      |
| `Category`       | `admin`      | `categories`       | `admin.categories.index`  |
| `Unit`           | `admin`      | `units`            | `admin.units.index`       |

## View Usage

In your views, use the permission code directly:

```erb
<%# Check if user can create users %>
<% if current_user.has_permission?("admin.users.create") %>
  <%= link_to "New User", new_admin_user_path, class: "btn btn-primary" %>
<% end %>

<%# Check if user can export reports %>
<% if current_user.has_permission?("reports.sales.export") %>
  <%= link_to "Export", export_sales_reports_path, class: "btn btn-success" %>
<% end %>

<%# Check if user can approve work orders %>
<% if current_user.has_permission?("workorders.orders.approve") %>
  <%= button_to "Approve", approve_work_order_path(@work_order), method: :patch %>
<% end %>
```

## Controller Usage

In controllers, use Pundit as normal - policies handle permission checking:

```ruby
class WorkersController < ApplicationController
  def index
    @workers = policy_scope(Worker) # Uses WorkerPolicy::Scope
    authorize Worker # Uses WorkerPolicy#index?
  end

  def create
    @worker = Worker.new(worker_params)
    authorize @worker # Uses WorkerPolicy#create?

    if @worker.save
      redirect_to @worker
    else
      render :new
    end
  end
end
```

## Seeding Permissions

Update `db/seeds/permissions.rb` when adding new resources:

```ruby
resources = {
  "admin.users" => %w[index show create update destroy],
  "workorders.orders" => %w[index show create update destroy complete approve],
  # Add your new resources here
}
```

## Migration Checklist

When adding a new policy:

1. ✅ Create policy file inheriting from `ApplicationPolicy`
2. ✅ Override `permission_resource` method (both in policy and scope)
3. ✅ Add custom actions if needed (call `user.has_permission?` with full code)
4. ✅ Add permissions to seed file (`db/seeds/permissions.rb`)
5. ✅ Run seeds: `rails db:seed`
6. ✅ Assign permissions to appropriate roles
7. ✅ Test in views with `current_user.has_permission?("namespace.resource.action")`

## Common Patterns

### Superadmin Bypass

Superadmin automatically bypasses all permission checks - no need to check role in policies.

### Permission Caching

User model caches permission codes in `@permission_codes`. Clear cache when role changes:

```ruby
user.update!(role: new_role)
user.clear_permission_cache!
```

### Scope Filtering

For custom scope logic:

```ruby
class Scope < ApplicationPolicy::Scope
  def resolve
    if user.has_permission?(build_permission_code('index'))
      if user.role.name == 'Manager'
        scope.where(department: user.department)
      else
        scope.all
      end
    else
      scope.none
    end
  end

  private

  def permission_resource
    'admin.users'
  end
end
```

## Troubleshooting

### NotImplementedError: must implement #permission_resource

**Problem:** Policy doesn't define `permission_resource`  
**Solution:** Add the method to both policy and scope:

```ruby
private

def permission_resource
  'namespace.resource'
end
```

### Permission always returns false

**Problem:** Permission code not in database or not assigned to role  
**Solutions:**

1. Check permission exists: `Permission.find_by(code: 'namespace.resource.action')`
2. Check role has permission: `user.role.permissions.pluck(:code)`
3. Re-run seeds: `rails db:seed`
4. Clear permission cache: `user.clear_permission_cache!`

### Policy not using correct resource

**Problem:** Using wrong namespace or resource name  
**Solution:** Check mapping table above and update `permission_resource` method

## Best Practices

1. **Keep namespaces consistent** - Use the same namespace for related resources
2. **Use Rails action names** - Stick to `index`, `show`, `create`, `update`, `destroy` when possible
3. **Document custom actions** - Add comments for non-standard actions
4. **Group related permissions** - Use same namespace for related functionality
5. **Test permission checks** - Verify both positive and negative cases
6. **Cache wisely** - Remember to clear cache when roles change

## Complete Example

See these files for complete examples:

- `app/policies/application_policy.rb` - Base policy
- `app/policies/worker_policy.rb` - Simple policy
- `app/policies/work_orders/detail_policy.rb` - Policy with custom actions
- `app/models/user.rb` - has_permission? implementation
- `db/seeds/permissions.rb` - Permission seeding

---

**Last Updated:** November 20, 2025  
**System Version:** Permission Refactoring v2.0
