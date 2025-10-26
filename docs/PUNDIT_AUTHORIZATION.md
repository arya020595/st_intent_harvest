# Pundit Authorization with Role & Permission System

## Table of Contents

- [Overview](#overview)
- [Architecture](#architecture)
- [Database Structure](#database-structure)
- [Core Components](#core-components)
- [How to Use](#how-to-use)
- [How to Extend](#how-to-extend)
- [Common Patterns](#common-patterns)
- [Testing](#testing)
- [Troubleshooting](#troubleshooting)

---

## Overview

This application uses **Pundit** for authorization with a **Role-Based Access Control (RBAC)** system. Each user has a role, and each role has specific permissions that determine what actions they can perform on which resources.

### Key Principles

- **SOLID Design**: Each component has a single responsibility
- **Convention over Configuration**: Automatic mapping between controller actions and permissions
- **DRY**: No code duplication across policies
- **Simple & Maintainable**: Easy to understand and extend

---

## Architecture

```
┌─────────────────┐
│   Controller    │
│  authorize()    │
│ policy_scope()  │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│     Policy      │
│  index?/show?   │
│  create?/etc.   │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ PermissionChecker│
│  allowed?(action,│
│          subject)│
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ User → Role →   │
│   Permissions   │
└─────────────────┘
```

---

## Database Structure

### Required Tables

#### `roles`

```ruby
create_table :roles do |t|
  t.string :name, null: false
  t.text :description
  t.timestamps
end
```

#### `permissions`

```ruby
create_table :permissions do |t|
  # Convention: action matches the policy method name (without the '?')
  # e.g., "index", "show", "create", "update", "destroy", or custom actions like "approve"
  t.string :action, null: false
  t.string :subject, null: false     # "Inventory", "WorkOrder", "Vehicle", etc.
  t.timestamps
end
```

#### `roles_permissions` (join table)

```ruby
create_table :roles_permissions do |t|
  t.references :role, null: false, foreign_key: true
  t.references :permission, null: false, foreign_key: true
  t.timestamps
end
```

#### `users`

```ruby
create_table :users do |t|
  t.references :role, foreign_key: true
  # ... other devise fields
end
```

### Models Setup

```ruby
# app/models/user.rb
class User < ApplicationRecord
  belongs_to :role, optional: true
  # ...
end

# app/models/role.rb
class Role < ApplicationRecord
  has_many :roles_permissions, dependent: :destroy
  has_many :permissions, through: :roles_permissions
  has_many :users, dependent: :nullify
end

# app/models/permission.rb
class Permission < ApplicationRecord
  has_many :roles_permissions, dependent: :destroy
  has_many :roles, through: :roles_permissions

  validates :action, presence: true
  validates :subject, presence: true
  validates :action, uniqueness: { scope: :subject }
end
```

---

## Core Components

### 1. PermissionChecker Service

**Location:** `app/services/permission_checker.rb`

**Purpose:** Centralized permission checking logic

```ruby
class PermissionChecker
  def initialize(user)
    @user = user
  end

  def allowed?(action, subject)
    # Superadmin bypass: allow everything
    return true if superadmin?
    return false unless user_has_role?

    permissions.exists?(action: action.to_s, subject: subject)
  end

  # Public method - can be used in policies for scope filtering
  def superadmin?
    # Case-insensitive match on role name 'Superadmin'
    @user&.role&.name&.downcase == 'superadmin'
  end

  private

  attr_reader :user

  def user_has_role?
    @user&.role.present?
  end

  def permissions
    @permissions ||= @user.role.permissions
  end
end
```

**How it works:**

1. Takes a user object on initialization
2. **Checks if user is superadmin (bypasses all permission checks)**
3. Checks if user has a role
4. Queries the database for matching permission
5. Returns `true` if permission exists, `false` otherwise
6. Provides public `superadmin?` method for use in policy scopes

---

### 2. ApplicationPolicy

**Location:** `app/policies/application_policy.rb`

**Purpose:** Base policy that all other policies inherit from

```ruby
class ApplicationPolicy
  attr_reader :user, :record

  def initialize(user, record)
    @user = user
    @record = record
  end

  # Standard CRUD actions (policy method -> same-named permission)
  def index?
    has_permission?(:index)
  end

  def show?
    has_permission?(:show)
  end

  def create?
    has_permission?(:create)
  end

  def new?
    create?
  end

  def update?
    has_permission?(:update)
  end

  def edit?
    update?
  end

  def destroy?
    has_permission?(:destroy)
  end

  private

  def has_permission?(action)
    permission_checker.allowed?(action, resource_name)
  end

  def permission_checker
    @permission_checker ||= PermissionChecker.new(user)
  end

  def resource_name
    record.class.name
  end

    class Scope
    attr_reader :user, :scope

    def initialize(user, scope)
      @user = user
      @scope = scope
    end

    def resolve
      return scope.none unless permission_checker.allowed?(:index, resource_name)

      # Default: return all records if user has permission
      # Override in subclass for custom filtering
      scope.all
    end

    private

    def permission_checker
      @permission_checker ||= PermissionChecker.new(user)
    end

    def resource_name
      scope.name
    end
  end
end
```

**Action Mapping (one-to-one):**
| Controller Action | Policy Method | Permission Action |
|------------------|---------------|-------------------|
| `index` | `index?` | `index` |
| `show` | `show?` | `show` |
| `new` | `new?` | `create` |
| `create` | `create?` | `create` |
| `edit` | `edit?` | `update` |
| `update` | `update?` | `update` |
| `destroy` | `destroy?` | `destroy` |

---

### 3. ApplicationController

**Location:** `app/controllers/application_controller.rb`

```ruby
class ApplicationController < ActionController::Base
  include Pundit::Authorization

  before_action :authenticate_user!

  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

  private

  def user_not_authorized
    flash[:alert] = "You are not authorized to perform this action."
    redirect_to(request.referrer || root_path)
  end
end
```

---

## How to Use

### Step 1: Create a Policy

For most resources, you don't need any custom code:

```ruby
# app/policies/inventory_policy.rb
class InventoryPolicy < ApplicationPolicy
  # That's it! Inherits all behavior from ApplicationPolicy

  class Scope < ApplicationPolicy::Scope
    def resolve
      return scope.none unless permission_checker.allowed?(:index, resource_name)

      # Superadmin sees all, regular users see filtered records
      permission_checker.superadmin? ? scope.all : scope.where(warehouse_id: user.warehouse_id)
    end
  end
end
```

### Step 2: Use in Controller

```ruby
# app/controllers/inventories_controller.rb
class InventoriesController < ApplicationController
  before_action :set_inventory, only: [:show, :edit, :update, :destroy]

  def index
    @inventories = policy_scope(Inventory)  # Filter records by permission
    authorize Inventory                      # Check index? permission
  end

  def show
    authorize @inventory  # Check show? permission
  end

  def create
    @inventory = Inventory.new(inventory_params)
    authorize @inventory  # Check create? permission

    if @inventory.save
      redirect_to @inventory, notice: 'Success!'
    else
      render :new
    end
  end

  def update
    authorize @inventory  # Check update? permission

    if @inventory.update(inventory_params)
      redirect_to @inventory, notice: 'Updated!'
    else
      render :edit
    end
  end

  def destroy
    authorize @inventory  # Check destroy? permission
    @inventory.destroy
    redirect_to inventories_url, notice: 'Deleted!'
  end

  private

  def set_inventory
    @inventory = Inventory.find(params[:id])
  end

  def inventory_params
    params.require(:inventory).permit(:code, :name, :unit_id, :category_id)
  end
end
```

### Step 3: Seed Permissions

```ruby
# db/seeds.rb

# Create permissions (align with policy methods)
permissions = [
  # Inventory permissions
  { action: 'index', subject: 'Inventory' },
  { action: 'show',  subject: 'Inventory' },
  { action: 'create', subject: 'Inventory' },
  { action: 'update', subject: 'Inventory' },
  { action: 'destroy', subject: 'Inventory' },

  # WorkOrder permissions
  { action: 'index', subject: 'WorkOrder' },
  { action: 'show',  subject: 'WorkOrder' },
  { action: 'create', subject: 'WorkOrder' },
  { action: 'update', subject: 'WorkOrder' },
  { action: 'destroy', subject: 'WorkOrder' },

  # Add more as needed...
]

permissions.each do |perm|
  Permission.find_or_create_by!(perm)
end

# Create roles
admin_role = Role.find_or_create_by!(name: 'Admin') do |role|
  role.description = 'Full access to all resources'
end

manager_role = Role.find_or_create_by!(name: 'Manager') do |role|
  role.description = 'Can read and update most resources'
end

viewer_role = Role.find_or_create_by!(name: 'Viewer') do |role|
  role.description = 'Read-only access'
end

# Assign all permissions to admin
admin_role.permissions = Permission.all

# Assign specific permissions to manager
manager_permissions = Permission.where(
  action: ['index', 'show', 'update'],
  subject: ['Inventory', 'WorkOrder', 'Vehicle']
)
manager_role.permissions = manager_permissions

# Assign read-only permissions to viewer (list + show)
viewer_permissions = Permission.where(action: ['index', 'show'])
viewer_role.permissions = viewer_permissions

puts "Seeded #{Permission.count} permissions"
puts "Seeded #{Role.count} roles"
```

### Step 4: Assign Roles to Users

```ruby
# In console or seed file
user = User.find_by(email: 'admin@example.com')
user.update(role: Role.find_by(name: 'Admin'))

# Or when creating a user
User.create!(
  email: 'manager@example.com',
  password: 'password',
  role: Role.find_by(name: 'Manager')
)
```

---

## Adding Custom Controller Actions

### Important: When you add a new controller action, you MUST add the corresponding policy method!

**Rule of Thumb:** Every controller action that needs authorization requires a matching policy method.

### Step-by-Step Guide

#### 1. Add the Controller Action

```ruby
# app/controllers/work_orders_controller.rb
class WorkOrdersController < ApplicationController

  def approve
    @work_order = WorkOrder.find(params[:id])
    authorize @work_order  # This will call WorkOrderPolicy#approve?

    if @work_order.update(status: 'approved', approved_by: current_user)
      redirect_to @work_order, notice: 'Work order approved!'
    else
      redirect_to @work_order, alert: 'Failed to approve'
    end
  end

  def export
    @work_orders = policy_scope(WorkOrder)
    authorize WorkOrder, :export?  # This will call WorkOrderPolicy#export?

    respond_to do |format|
      format.csv { send_data @work_orders.to_csv }
      format.xlsx { send_data @work_orders.to_xlsx }
    end
  end
end
```

#### 2. Add the Policy Method

```ruby
# app/policies/work_order_policy.rb
class WorkOrderPolicy < ApplicationPolicy

  # Method name MUST match controller action + '?'
  def approve?
    has_permission?(:approve)
  end

  def export?
    has_permission?(:export)
  end

  class Scope < ApplicationPolicy::Scope
  end
end
```

#### 3. Create the Permission (Optional but Recommended)

```ruby
# db/seeds.rb or rails console
Permission.create!(action: 'approve', subject: 'WorkOrder')
Permission.create!(action: 'export', subject: 'WorkOrder')

# Assign to role
admin_role = Role.find_by(name: 'Admin')
approve_permission = Permission.find_by(action: 'approve', subject: 'WorkOrder')
admin_role.permissions << approve_permission
```

#### 4. Add Route

```ruby
# config/routes.rb
resources :work_orders do
  member do
    patch :approve
  end
  collection do
    get :export
  end
end
```

### Quick Checklist for New Actions

When adding a new controller action:

- [ ] Create the controller action
- [ ] Add `authorize @record` or `authorize Record, :action?` in the action
- [ ] Add matching method in policy (e.g., `approve?`)
- [ ] Create permission in database if using role-based check
- [ ] Assign permission to appropriate roles
- [ ] Add route to `routes.rb`
- [ ] Test the authorization

### Common Custom Actions Examples

```ruby
# app/policies/work_order_policy.rb
class WorkOrderPolicy < ApplicationPolicy

  # Approval workflow
  def approve?
    has_permission?(:approve) && record.pending?
  end

  def reject?
    has_permission?(:approve) && record.pending?
  end

  # Assignment actions
  def assign_worker?
    has_permission?(:update) && record.status.in?(['pending', 'in_progress'])
  end

  def unassign_worker?
    has_permission?(:update)
  end

  # Status transitions
  def start?
    has_permission?(:update) && record.can_start?
  end

  def complete?
    has_permission?(:update) && record.can_complete?
  end

  def cancel?
    has_permission?(:destroy) || (record.created_by_id == user.id && record.pending?)
  end

  # Export/Import
  def export?
    has_permission?(:index)
  end

  def import?
    has_permission?(:create)
  end

  # Bulk actions
  def bulk_update?
    has_permission?(:update)
  end

  def bulk_delete?
    has_permission?(:destroy)
  end
end
```

### Using Custom Actions in Controllers

```ruby
# app/controllers/work_orders_controller.rb
class WorkOrdersController < ApplicationController

  # Member actions (operate on single record)
  def approve
    @work_order = WorkOrder.find(params[:id])
    authorize @work_order  # Calls approve?

    @work_order.approve!(current_user)
    redirect_to @work_order, notice: 'Approved!'
  end

  def assign_worker
    @work_order = WorkOrder.find(params[:id])
    authorize @work_order, :assign_worker?  # Explicit action name

    @work_order.assign_to(params[:worker_id])
    redirect_to @work_order, notice: 'Worker assigned!'
  end

  # Collection actions (operate on multiple records or class level)
  def export
    authorize WorkOrder, :export?  # Class-level authorization

    @work_orders = policy_scope(WorkOrder)
    send_data @work_orders.to_csv, filename: 'work_orders.csv'
  end

  def bulk_update
    authorize WorkOrder, :bulk_update?

    @work_orders = WorkOrder.where(id: params[:ids])
    @work_orders.each { |wo| authorize wo, :update? }  # Check each record too

    @work_orders.update_all(status: params[:status])
    redirect_to work_orders_path, notice: 'Updated!'
  end
end
```

### Using in Views

```erb
<!-- app/views/work_orders/show.html.erb -->

<% if policy(@work_order).approve? %>
  <%= button_to 'Approve', approve_work_order_path(@work_order),
                method: :patch, class: 'btn btn-success' %>
<% end %>

<% if policy(@work_order).reject? %>
  <%= button_to 'Reject', reject_work_order_path(@work_order),
                method: :patch, class: 'btn btn-danger' %>
<% end %>

<% if policy(@work_order).assign_worker? %>
  <%= link_to 'Assign Worker', assign_worker_work_order_path(@work_order),
              class: 'btn btn-primary' %>
<% end %>

<!-- In index view -->
<% if policy(WorkOrder).export? %>
  <%= link_to 'Export CSV', export_work_orders_path(format: :csv),
              class: 'btn btn-secondary' %>
<% end %>
```

---

## How to Extend

### Custom Authorization Logic

Sometimes you need more than just role-based permissions:

```ruby
# app/policies/work_order_policy.rb
class WorkOrderPolicy < ApplicationPolicy

  # Override update to add custom logic
  def update?
    # First check permission
    return false unless has_permission?(:update)

    # Then add custom logic: only owner can update
    record.created_by_id == user.id || user.role.name == 'Admin'
  end

  # Custom action not in ApplicationPolicy
  def approve?
    has_permission?(:approve) && user.role.name.in?(['Admin', 'Manager'])
  end

  # Custom action for completing work orders
  def complete?
    has_permission?(:update) && record.status != 'completed'
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      # First check index permission (list visibility)
      return scope.none unless permission_checker.allowed?(:index, resource_name)

      # Then apply custom filtering
      if user.role.name == 'Admin'
        scope.all
      elsif user.role.name == 'Manager'
        scope.where(block_id: user.managed_block_ids)
      else
        scope.where(created_by_id: user.id)
      end
    end
  end
end
```

### Adding Custom Permissions

```ruby
# Create custom permission in seeds or migration
Permission.create!(action: 'approve', subject: 'WorkOrder')
Permission.create!(action: 'export', subject: 'Inventory')
Permission.create!(action: 'assign', subject: 'Worker')

# Use in controller
def approve
  authorize @work_order  # Calls WorkOrderPolicy#approve?
  @work_order.update(status: 'approved')
end
```

### Scopes with Complex Queries

```ruby
class InventoryPolicy < ApplicationPolicy
  class Scope < ApplicationPolicy::Scope
    def resolve
      # Check base permission first
      return scope.none unless permission_checker.allowed?(:read, resource_name)

      case user.role.name
      when 'Admin'
        scope.all
      when 'Manager'
        # Only inventories in blocks the user manages
        scope.joins(:category)
             .where(categories: { block_id: user.block_ids })
      when 'Warehouse Staff'
        # Only active inventories
        scope.where(status: 'active')
      else
        # Limited view for others
        scope.where(is_public: true)
      end
    end
  end
end
```

### Conditional Permissions

```ruby
class VehiclePolicy < ApplicationPolicy

  def destroy?
    # Can only destroy if:
    # 1. Has destroy permission
    # 2. Vehicle is not assigned to any active work order
    has_permission?(:destroy) && !record.has_active_work_orders?
  end

  def assign?
    # Can assign if has update permission and vehicle is available
    has_permission?(:update) && record.available?
  end
end
```

---

## Common Patterns

### 1. Checking Permissions in Views

```erb
<!-- app/views/inventories/index.html.erb -->

<% if policy(Inventory).create? %>
  <%= link_to 'New Inventory', new_inventory_path, class: 'btn btn-primary' %>
<% end %>

<% @inventories.each do |inventory| %>
  <tr>
    <td><%= inventory.code %></td>
    <td><%= inventory.name %></td>
    <td>
      <%= link_to 'Show', inventory if policy(inventory).show? %>
      <%= link_to 'Edit', edit_inventory_path(inventory) if policy(inventory).update? %>
      <%= link_to 'Delete', inventory, method: :delete if policy(inventory).destroy? %>
    </td>
  </tr>
<% end %>
```

### 2. Permitted Attributes

```ruby
class InventoryPolicy < ApplicationPolicy

  def permitted_attributes
    if user.role.name == 'Admin'
      [:code, :name, :unit_id, :category_id, :stock, :price, :is_active]
    elsif user.role.name == 'Manager'
      [:name, :stock, :price]
    else
      [:stock]  # Regular users can only update stock
    end
  end
end

# In controller
def inventory_params
  permitted_attrs = policy(@inventory || Inventory).permitted_attributes
  params.require(:inventory).permit(*permitted_attrs)
end
```

### 3. Headless Policies (No Record)

```ruby
class DashboardPolicy < ApplicationPolicy
  def initialize(user, _record)
    @user = user
    @record = :dashboard  # Symbol, not a model
  end

  def show?
    user.present?
  end

  def admin_view?
    user&.role&.name == 'Admin'
  end
end

# In controller
class DashboardController < ApplicationController
  def index
    authorize :dashboard

    if policy(:dashboard).admin_view?
      @data = AdminDashboard.generate
    else
      @data = UserDashboard.generate(current_user)
    end
  end
end
```

### 4. Bulk Authorization

```ruby
# Check if user can perform action on any record
def can_create_any?
  Pundit.policy!(current_user, Resource).create?
end

# Authorize multiple records
def bulk_update
  @records = Resource.where(id: params[:ids])
  @records.each { |record| authorize record, :update? }
  # ... perform bulk update
end
```

---

## Testing

### RSpec Example

```ruby
# spec/policies/inventory_policy_spec.rb
require 'rails_helper'

RSpec.describe InventoryPolicy do
  subject { described_class.new(user, inventory) }

  let(:inventory) { create(:inventory) }

  context 'for an admin user' do
    let(:user) { create(:user, :admin) }

    it { is_expected.to permit_action(:index) }
    it { is_expected.to permit_action(:show) }
    it { is_expected.to permit_action(:create) }
    it { is_expected.to permit_action(:update) }
    it { is_expected.to permit_action(:destroy) }
  end

  context 'for a manager user' do
    let(:user) { create(:user, :manager) }

    it { is_expected.to permit_action(:index) }
    it { is_expected.to permit_action(:show) }
    it { is_expected.to permit_action(:update) }
    it { is_expected.not_to permit_action(:destroy) }
  end

  context 'for a viewer user' do
    let(:user) { create(:user, :viewer) }

    it { is_expected.to permit_action(:index) }
    it { is_expected.to permit_action(:show) }
    it { is_expected.not_to permit_action(:create) }
    it { is_expected.not_to permit_action(:update) }
    it { is_expected.not_to permit_action(:destroy) }
  end

  context 'for a user without a role' do
    let(:user) { create(:user, role: nil) }

    it { is_expected.not_to permit_action(:index) }
    it { is_expected.not_to permit_action(:show) }
    it { is_expected.not_to permit_action(:create) }
  end
end

# spec/policies/inventory_policy/scope_spec.rb
RSpec.describe InventoryPolicy::Scope do
  subject { described_class.new(user, Inventory).resolve }

  let!(:inventory1) { create(:inventory) }
  let!(:inventory2) { create(:inventory) }

  context 'for admin user' do
    let(:user) { create(:user, :admin) }

    it 'returns all inventories' do
      expect(subject).to match_array([inventory1, inventory2])
    end
  end

  context 'for user without index permission' do
    let(:user) { create(:user, role: nil) }

    it 'returns no inventories' do
      expect(subject).to be_empty
    end
  end
end
```

### Factory Setup

```ruby
# spec/factories/users.rb
FactoryBot.define do
  factory :user do
    email { Faker::Internet.email }
    password { 'password123' }

    trait :admin do
      association :role, factory: :admin_role
    end

    trait :manager do
      association :role, factory: :manager_role
    end

    trait :viewer do
      association :role, factory: :viewer_role
    end
  end
end

# spec/factories/roles.rb
FactoryBot.define do
  factory :role do
    name { 'Basic User' }

    factory :admin_role do
      name { 'Admin' }

      after(:create) do |role|
        role.permissions = Permission.all
      end
    end

    factory :manager_role do
      name { 'Manager' }

      after(:create) do |role|
        read_update = Permission.where(action: ['read', 'update'])
        role.permissions = read_update
      end
    end

    factory :viewer_role do
      name { 'Viewer' }

      after(:create) do |role|
        role.permissions = Permission.where(action: 'read')
      end
    end
  end
end
```

---

## Troubleshooting

### Common Issues

#### 1. `Pundit::NotAuthorizedError`

**Problem:** User tries to access a resource they don't have permission for.

**Solution:**

- Check that user has a role assigned
- Verify the role has the required permission
- Check permission's `action` and `subject` match exactly

```ruby
# In rails console
user = User.find(1)
user.role                           # Should not be nil
user.role.permissions               # Should include the needed permission
user.role.permissions.where(
  action: 'read',
  subject: 'Inventory'
).exists?                           # Should be true
```

#### 2. Policy Not Found

**Problem:** `Pundit::PolicyNotFoundError`

**Solution:** Create the policy file

```ruby
# app/policies/your_resource_policy.rb
class YourResourcePolicy < ApplicationPolicy
  class Scope < ApplicationPolicy::Scope
  end
end
```

#### 3. `policy_scope` Returns Empty

**Problem:** `policy_scope(Resource)` returns no records even though they exist

**Solution:**

- Check that user has 'read' permission for that resource
- Verify the Scope's `resolve` method logic
- Check the `resource_name` matches the permission's `subject`

```ruby
# Debug in rails console
user = current_user
scope = Pundit.policy_scope(user, Inventory)
# Compare with:
Inventory.all
```

#### 4. Permissions Not Working After Seed

**Problem:** Seeded permissions but authorization still failing

**Solution:** Reload associations in console or restart server

```bash
rails db:seed
rails db:reset  # If issues persist
```

#### 5. Custom Actions Not Authorized

**Problem:** Custom action like `approve?` always fails

**Solution:**

- Create custom permission in database
- Add custom method in policy
- Use `authorize @record, :approve?` in controller

```ruby
# Create permission
Permission.create!(action: 'approve', subject: 'WorkOrder')

# Add to policy
def approve?
  has_permission?(:approve)
end

# Use in controller
def approve
  authorize @work_order, :approve?
  # ...
end
```

---

## Best Practices

### ✅ DO

- Always call `authorize` or `policy_scope` in controller actions
- Keep policies simple and focused
- Use inheritance to avoid duplication
- Test your policies thoroughly
- Document custom permissions
- Use meaningful permission names

### ❌ DON'T

- Don't skip authorization checks
- Don't put business logic in policies (use service objects)
- Don't use `method_missing` for dynamic permissions
- Don't bypass Pundit with manual permission checks
- Don't forget to authorize in API controllers
- Don't hardcode role names everywhere

---

## Superadmin Pattern

### Centralized Superadmin Logic

Superadmin checks are centralized in `PermissionChecker` to maintain a **single source of truth**:

```ruby
# app/services/permission_checker.rb
class PermissionChecker
  def allowed?(action, subject)
    return true if superadmin?  # Bypass all permission checks
    # ... normal permission logic
  end

  # Public method - can be used in policies
  def superadmin?
    @user&.role&.name&.downcase == 'superadmin'
  end
end
```

### Benefits

- **Automatic Bypass**: Superadmin automatically passes all `authorize` checks
- **DRY**: Superadmin logic defined in one place only
- **Consistent**: All policies use the same superadmin check
- **Maintainable**: Easy to change superadmin logic across the entire app

### Usage in Policy Scopes

For filtering records in scopes, use `permission_checker.superadmin?`:

```ruby
class InventoryPolicy < ApplicationPolicy
  class Scope < ApplicationPolicy::Scope
    def resolve
      return scope.none unless permission_checker.allowed?(:index, resource_name)

      # Superadmin sees all, regular users see filtered records
      permission_checker.superadmin? ? scope.all : scope.where(warehouse_id: user.warehouse_id)
    end
  end
end
```

### Setting Up Superadmin

1. **Create the role:**

   ```ruby
   superadmin = Role.create!(name: 'Superadmin', description: 'Full system access')
   ```

2. **No permissions needed:**

   - Superadmin bypasses permission checks
   - No need to assign specific permissions
   - Can still assign permissions if you want to track them

3. **Assign to user:**
   ```ruby
   user.update(role: Role.find_by(name: 'Superadmin'))
   ```

For more details on namespaced policies and advanced patterns, see [POLICY_CONVENTION.md](POLICY_CONVENTION.md).

---

## Quick Reference

### Controller Methods

```ruby
authorize @record              # Check if action is authorized
authorize @record, :custom?    # Check custom action
policy_scope(Model)            # Get filtered records
policy(@record).show?          # Check permission in controller
```

### View Helpers

```ruby
policy(@record).update?        # Check if user can update
policy(Model).create?          # Check if user can create
```

### Permission Structure

```ruby
Permission.create!(
  action: 'index',             # index, show, create, update, destroy, or custom
  subject: 'Inventory'         # Model class name
)
```

---

## Summary

This authorization system provides:

- **Flexible** role-based permissions
- **Simple** to use and extend
- **Maintainable** with clear separation of concerns
- **Testable** with comprehensive test coverage
- **Scalable** for growing applications

For questions or issues, refer to:

- [Pundit Documentation](https://github.com/varvet/pundit)
- This documentation
- Your team's senior developers
