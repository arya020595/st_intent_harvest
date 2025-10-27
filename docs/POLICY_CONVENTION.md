# Policy Convention

## Overview

This document defines the standard convention for implementing Pundit policies in this application, covering both namespaced and standard (non-namespaced) approaches.

## When to Use Namespaced Policies

Use namespaced policies when you need granular permission control for different contexts of the same model:

- **WorkOrder::Detail** - Managing work order CRUD operations
- **WorkOrder::Approval** - Approving/rejecting work orders
- **WorkOrder::PayCalculation** - Calculating and managing pay

## Standard Pattern

### 1. File Structure

```
app/
  policies/
    work_order/
      detail_policy.rb
      approval_policy.rb
      pay_calculation_policy.rb
```

### 2. Policy Class Definition

```ruby
# frozen_string_literal: true

module WorkOrder
  class DetailPolicy < ApplicationPolicy
    # Custom actions specific to this context
    def mark_complete?
      has_permission?(:mark_complete)
    end

    class Scope < ApplicationPolicy::Scope
      def resolve
        return scope.none unless permission_checker.allowed?(:index, resource_name)

        # Superadmin sees all, regular users see filtered records
        permission_checker.superadmin? ? scope.all : scope.where(field_conductor_id: user.id)
      end
    end

    private

    def resource_name
      # IMPORTANT: Return the full namespaced name without "Policy" suffix
      "WorkOrder::Detail"
    end
  end
end
```

### 3. Controller Authorization

```ruby
class WorkOrder::DetailsController < ApplicationController
  def index
    # Use array notation: [:namespace, :context]
    authorize [:work_order, :detail]
    @work_orders = policy_scope([:work_order, :detail])
  end

  def show
    @work_order = WorkOrder.find(params[:id])
    authorize [:work_order, :detail], @work_order
  end

  def mark_complete
    @work_order = WorkOrder.find(params[:id])
    authorize [:work_order, :detail], @work_order
    # Use AASM transition
    @work_order.mark_complete!
  end
end
```

### 4. Permission Seeding

```ruby
# db/seeds.rb

# Create permissions for WorkOrder::Detail context
detail_permissions = [
  { subject: 'WorkOrder::Detail', action: 'index', description: 'View work orders list' },
  { subject: 'WorkOrder::Detail', action: 'show', description: 'View work order details' },
  { subject: 'WorkOrder::Detail', action: 'create', description: 'Create new work orders' },
  { subject: 'WorkOrder::Detail', action: 'update', description: 'Edit work orders' },
  { subject: 'WorkOrder::Detail', action: 'destroy', description: 'Delete work orders' },
  { subject: 'WorkOrder::Detail', action: 'mark_complete', description: 'Mark work order as complete' }
]

# Create permissions for WorkOrder::Approval context
approval_permissions = [
  { subject: 'WorkOrder::Approval', action: 'index', description: 'View work orders for approval' },
  { subject: 'WorkOrder::Approval', action: 'show', description: 'View approval details' },
  { subject: 'WorkOrder::Approval', action: 'approve', description: 'Approve work orders' },
  { subject: 'WorkOrder::Approval', action: 'reject', description: 'Reject work orders' }
]

# Create permissions for WorkOrder::PayCalculation context
pay_calc_permissions = [
  { subject: 'WorkOrder::PayCalculation', action: 'index', description: 'View pay calculations list' },
  { subject: 'WorkOrder::PayCalculation', action: 'show', description: 'View pay calculation details' },
  { subject: 'WorkOrder::PayCalculation', action: 'create', description: 'Create pay calculations' },
  { subject: 'WorkOrder::PayCalculation', action: 'update', description: 'Update pay calculations' },
  { subject: 'WorkOrder::PayCalculation', action: 'destroy', description: 'Delete pay calculations' },
  { subject: 'WorkOrder::PayCalculation', action: 'calculate', description: 'Calculate payments' }
]

(detail_permissions + approval_permissions + pay_calc_permissions).each do |perm|
  Permission.find_or_create_by!(subject: perm[:subject], action: perm[:action]) do |p|
    p.description = perm[:description]
  end
end

# Assign to roles
clerk_role = Role.find_by(name: 'Clerk')
approver_role = Role.find_by(name: 'Approver')

# Clerk can manage work order details
Permission.where(subject: 'WorkOrder::Detail').each do |permission|
  RolesPermission.find_or_create_by!(role: clerk_role, permission: permission)
end

# Approver can approve/reject
Permission.where(subject: 'WorkOrder::Approval').each do |permission|
  RolesPermission.find_or_create_by!(role: approver_role, permission: permission)
end
```

## Naming Convention Reference

| Component                | Format                            | Example                                    |
| ------------------------ | --------------------------------- | ------------------------------------------ |
| **Module**               | PascalCase                        | `WorkOrder`                                |
| **Context**              | PascalCase                        | `Detail`, `Approval`, `PayCalculation`     |
| **Policy Class**         | `Module::ContextPolicy`           | `WorkOrder::DetailPolicy`                  |
| **File Path**            | `snake_case`                      | `app/policies/work_order/detail_policy.rb` |
| **resource_name**        | `"Module::Context"`               | `"WorkOrder::Detail"`                      |
| **Permission subject**   | `"Module::Context"`               | `"WorkOrder::Detail"`                      |
| **Controller namespace** | `Module::ContextsController`      | `WorkOrder::DetailsController`             |
| **Route namespace**      | `snake_case`                      | `namespace :work_order do ... end`         |
| **Authorize array**      | `[:module_snake, :context_snake]` | `[:work_order, :detail]`                   |

## Key Points

1. **resource_name method**: Always return the full namespace without "Policy" suffix

   ```ruby
   def resource_name
     "WorkOrder::Detail"  # ✅ Correct
     # "WorkOrderDetail"  # ❌ Wrong - loses namespace structure
     # "WorkOrder::DetailPolicy"  # ❌ Wrong - includes "Policy" suffix
   end
   ```

2. **Permission subject**: Must match exactly with resource_name

   ```ruby
   Permission.create!(
     subject: "WorkOrder::Detail",  # ✅ Must match resource_name
     action: "index"
   )
   ```

3. **Authorization**: Use array notation for clarity

   ```ruby
   authorize [:work_order, :detail]  # ✅ Clear and explicit
   # authorize @work_order  # ❌ Would use WorkOrderPolicy (doesn't exist)
   ```

4. **Scope**: Same array notation
   ```ruby
   policy_scope([:work_order, :detail])  # ✅ Uses WorkOrder::DetailPolicy::Scope
   ```

## Benefits of This Pattern

1. **Separation of Concerns**: Different contexts have different policies
2. **Granular Permissions**: User can have approval rights without edit rights
3. **Clear Intent**: Code clearly shows which context is being authorized
4. **Easier Testing**: Each policy can be tested independently
5. **Better Organization**: Related policies grouped by namespace

## Example Use Case

A user with the "Approver" role might have:

- ✅ `WorkOrder::Approval` permissions (can approve/reject)
- ❌ `WorkOrder::Detail` permissions (cannot edit work orders)
- ❌ `WorkOrder::PayCalculation` permissions (cannot calculate payments)

This separation ensures proper role-based access control where approval and editing are separate business functions.

---

## Non-Namespaced (Standard) Policies

For simple resources that don't require multiple contexts, use standard non-namespaced policies.

### When to Use Standard Policies

Use standard policies when:

- The resource has straightforward CRUD operations
- No need for different permission contexts
- Examples: Inventories, Workers, Vehicles, Blocks, Users, Roles

### Standard Pattern

#### 1. File Structure

```
app/
  policies/
    inventory_policy.rb
    worker_policy.rb
    vehicle_policy.rb
    user_policy.rb
```

#### 2. Policy Class Definition

```ruby
# frozen_string_literal: true

class InventoryPolicy < ApplicationPolicy
  # Inherits all standard CRUD methods from ApplicationPolicy:
  # - index?, show?, create?, update?, destroy?

  # Add custom actions if needed
  def export?
    has_permission?(:export)
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      return scope.none unless permission_checker.allowed?(:index, resource_name)

      # Superadmin sees all, regular users see filtered records
      permission_checker.superadmin? ? scope.all : scope.where(warehouse_id: user.warehouse_id)
    end
  end

  # Note: resource_name is automatically handled by ApplicationPolicy
  # It will return "Inventory" (demodulized class name)
end
```

#### 3. Controller Authorization

```ruby
class InventoriesController < ApplicationController
  def index
    # Direct authorization - Pundit automatically finds InventoryPolicy
    authorize Inventory
    @inventories = policy_scope(Inventory)
  end

  def show
    @inventory = Inventory.find(params[:id])
    authorize @inventory
  end

  def create
    @inventory = Inventory.new(inventory_params)
    authorize @inventory

    if @inventory.save
      redirect_to @inventory
    else
      render :new
    end
  end

  def export
    authorize Inventory
    # Export logic
  end
end
```

#### 4. Permission Seeding

```ruby
# db/seeds.rb

# Create permissions for standard resources
inventory_permissions = [
  { subject: 'Inventory', action: 'index', description: 'View inventories list' },
  { subject: 'Inventory', action: 'show', description: 'View inventory details' },
  { subject: 'Inventory', action: 'create', description: 'Create new inventories' },
  { subject: 'Inventory', action: 'update', description: 'Edit inventories' },
  { subject: 'Inventory', action: 'destroy', description: 'Delete inventories' },
  { subject: 'Inventory', action: 'export', description: 'Export inventory data' }
]

worker_permissions = [
  { subject: 'Worker', action: 'index', description: 'View workers list' },
  { subject: 'Worker', action: 'show', description: 'View worker details' },
  { subject: 'Worker', action: 'create', description: 'Add new workers' },
  { subject: 'Worker', action: 'update', description: 'Edit worker information' },
  { subject: 'Worker', action: 'destroy', description: 'Remove workers' }
]

vehicle_permissions = [
  { subject: 'Vehicle', action: 'index', description: 'View vehicles list' },
  { subject: 'Vehicle', action: 'show', description: 'View vehicle details' },
  { subject: 'Vehicle', action: 'create', description: 'Register new vehicles' },
  { subject: 'Vehicle', action: 'update', description: 'Update vehicle information' },
  { subject: 'Vehicle', action: 'destroy', description: 'Deactivate vehicles' }
]

(inventory_permissions + worker_permissions + vehicle_permissions).each do |perm|
  Permission.find_or_create_by!(subject: perm[:subject], action: perm[:action]) do |p|
    p.description = perm[:description]
  end
end

# Assign to roles
warehouse_manager_role = Role.find_by(name: 'Warehouse Manager')

# Warehouse manager can manage inventories
Permission.where(subject: 'Inventory').each do |permission|
  RolesPermission.find_or_create_by!(role: warehouse_manager_role, permission: permission)
end
```

### Standard Naming Convention Reference

| Component              | Format                  | Example                                         |
| ---------------------- | ----------------------- | ----------------------------------------------- |
| **Model**              | PascalCase              | `Inventory`, `Worker`, `Vehicle`                |
| **Policy Class**       | `ModelPolicy`           | `InventoryPolicy`                               |
| **File Path**          | `snake_case`            | `app/policies/inventory_policy.rb`              |
| **resource_name**      | `"Model"`               | `"Inventory"`                                   |
| **Permission subject** | `"Model"`               | `"Inventory"`                                   |
| **Controller**         | `ModelsController`      | `InventoriesController`                         |
| **Authorize**          | Model class or instance | `authorize Inventory` or `authorize @inventory` |

### Key Points for Standard Policies

1. **No need to override resource_name**: ApplicationPolicy handles it automatically

   ```ruby
   class InventoryPolicy < ApplicationPolicy
     # resource_name automatically returns "Inventory"
     # No need to define it unless you need custom behavior
   end
   ```

2. **Permission subject**: Use simple model name

   ```ruby
   Permission.create!(
     subject: "Inventory",  # ✅ Simple model name
     action: "index"
   )
   ```

3. **Authorization**: Direct model or instance

   ```ruby
   authorize Inventory          # ✅ For class-level actions (index, create form)
   authorize @inventory         # ✅ For instance-level actions (show, edit, delete)
   ```

4. **Scope**: Direct model class
   ```ruby
   policy_scope(Inventory)      # ✅ Uses InventoryPolicy::Scope
   ```

### Comparison: Namespaced vs Standard

| Aspect                 | Namespaced                             | Standard                     |
| ---------------------- | -------------------------------------- | ---------------------------- |
| **Use Case**           | Multiple contexts for same model       | Simple CRUD operations       |
| **Example**            | WorkOrder (Detail/Approval/PayCalc)    | Inventory, Worker, Vehicle   |
| **Policy File**        | `work_order/detail_policy.rb`          | `inventory_policy.rb`        |
| **Policy Class**       | `WorkOrder::DetailPolicy`              | `InventoryPolicy`            |
| **resource_name**      | `"WorkOrder::Detail"` (must override)  | `"Inventory"` (auto-handled) |
| **Permission subject** | `"WorkOrder::Detail"`                  | `"Inventory"`                |
| **Authorize**          | `authorize [:work_order, :detail]`     | `authorize Inventory`        |
| **Scope**              | `policy_scope([:work_order, :detail])` | `policy_scope(Inventory)`    |

### Decision Tree

```
Do you need different permission sets for different operations on the same model?
│
├─ YES → Use Namespaced Policy
│   Example: WorkOrder needs separate permissions for:
│   - Managing details (edit, create)
│   - Approving (approve, reject)
│   - Pay calculations (calculate, finalize)
│
└─ NO → Use Standard Policy
    Example: Inventory just needs:
    - Basic CRUD (create, read, update, delete)
    - Maybe some extras (export, import)
```

### Complete Example: Standard Policy

```ruby
# app/models/inventory.rb
class Inventory < ApplicationRecord
  belongs_to :warehouse
  belongs_to :category
end

# app/policies/inventory_policy.rb
class InventoryPolicy < ApplicationPolicy
  def export?
    has_permission?(:export)
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      return scope.none unless permission_checker.allowed?(:index, resource_name)

      # Superadmin sees all, regular users see filtered records
      permission_checker.superadmin? ? scope.all : scope.where(warehouse_id: user.warehouse_id)
    end
  end
end

# app/controllers/inventories_controller.rb
class InventoriesController < ApplicationController
  def index
    authorize Inventory
    @inventories = policy_scope(Inventory)
  end

  def show
    @inventory = Inventory.find(params[:id])
    authorize @inventory
  end

  def export
    authorize Inventory
    # Export logic
  end
end

# db/seeds.rb
Permission.create!([
  { subject: 'Inventory', action: 'index', description: 'View inventories' },
  { subject: 'Inventory', action: 'create', description: 'Create inventories' },
  { subject: 'Inventory', action: 'export', description: 'Export inventories' }
])
```

## Superadmin Pattern

### Single Source of Truth

The superadmin check is centralized in `PermissionChecker` to maintain consistency:

```ruby
# app/services/permission_checker.rb
class PermissionChecker
  def allowed?(action, subject)
    return true if superadmin?  # Bypass all permission checks
    # ... normal permission check
  end

  # Public method - can be used in policies
  def superadmin?
    return false unless @user && @user.role && @user.role.name
    @user.role.name.downcase == 'superadmin'
  end
end
```

### Usage in Policy Scopes

Always use `permission_checker.superadmin?` instead of checking user role directly:

```ruby
# ✅ Correct - Single source of truth
class Scope < ApplicationPolicy::Scope
  def resolve
    return scope.none unless permission_checker.allowed?(:index, resource_name)

    permission_checker.superadmin? ? scope.all : scope.where(field_conductor_id: user.id)
  end
end

# ❌ Wrong - Duplicates superadmin logic
class Scope < ApplicationPolicy::Scope
  def resolve
    return scope.none unless permission_checker.allowed?(:index, resource_name)

    user.role&.name == 'Superadmin' ? scope.all : scope.where(field_conductor_id: user.id)
  end
end
```

### Benefits

- **DRY**: Superadmin logic defined in one place
- **Testable**: Easy to mock `permission_checker.superadmin?`
- **Maintainable**: Changing superadmin logic only requires updating `PermissionChecker`
- **Consistent**: All policies use the same superadmin check

## Summary

- **Use Namespaced Policies** when you need granular control over different business contexts
- **Use Standard Policies** for straightforward CRUD operations
- **Always match** `resource_name` with `Permission.subject`
- **Use `permission_checker.superadmin?`** for scope filtering (single source of truth)
- **Follow naming conventions** consistently for maintainability
