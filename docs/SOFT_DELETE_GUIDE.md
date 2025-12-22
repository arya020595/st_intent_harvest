# Soft Delete Implementation Guide

## Overview

This application uses the [Discard gem](https://github.com/jhawthorn/discard) for soft delete functionality, wrapped in SOLID-compliant concerns and services.

## Architecture (SOLID Principles)

```
┌─────────────────────────────────────────────────────────────────┐
│                        Controller Layer                          │
│  SoftDeletableController (concerns/soft_deletable_controller.rb) │
│  - Handles HTTP requests for delete/restore                      │
│  - Uses SoftDelete::Service                                      │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                        Service Layer                             │
│  SoftDelete::Service      - Single record operations             │
│  SoftDelete::BatchService - Batch operations                     │
│  - Business logic, validation                                    │
│  - Returns Dry::Monads Result                                    │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                        Model Layer                               │
│  SoftDeletable (concerns/soft_deletable.rb)                      │
│  - Wraps Discard::Model                                          │
│  - Provides callbacks and hooks                                  │
│                                                                   │
│  CascadingSoftDelete (concerns/cascading_soft_delete.rb)         │
│  - Handles cascade delete to associations                        │
└─────────────────────────────────────────────────────────────────┘
```

## Quick Start

### 1. Run Migration

```bash
rails db:migrate
```

This adds `discarded_at` column to all models.

### 2. Models Already Have Soft Delete

All models inherit from `ApplicationRecord` which includes `SoftDeletable`:

```ruby
class ApplicationRecord < ActiveRecord::Base
  include SoftDeletable
end
```

### 3. Use in Controllers

All controllers are already updated to use soft delete. The `SoftDeletableController` concern is included in:

- `WorkersController`
- `InventoriesController`
- `InventoryOrdersController`
- `MasterData::BlocksController`
- `MasterData::UnitsController`
- `MasterData::VehiclesController`
- `MasterData::CategoriesController`
- `MasterData::WorkOrderRatesController`
- `UserManagement::UsersController`
- `UserManagement::RolesController`
- `WorkOrders::DetailsController`
- `WorkOrders::MandaysController`

**How it works:**

```ruby
class WorkersController < ApplicationController
  include RansackMultiSort
  include SoftDeletableController  # Adds soft delete behavior

  # Note: :restore is NOT included here - it finds the record itself
  before_action :set_worker, only: %i[show edit update destroy]

  def destroy
    authorize @worker
    super  # Calls SoftDeletableController#destroy (soft delete)
  end

  def restore
    # Must use with_discarded to find soft-deleted records
    @worker = Worker.with_discarded.find(params[:id])
    authorize @worker
    super  # Calls SoftDeletableController#restore
  end
end
```

**To add soft delete to a new controller:**

```ruby
class MyController < ApplicationController
  include SoftDeletableController

  before_action :set_my_record, only: %i[show edit update destroy]

  def destroy
    authorize @my_record  # Optional: if using Pundit
    super
  end

  def restore
    @my_record = MyModel.with_discarded.find(params[:id])
    authorize @my_record  # Optional: if using Pundit
    super
  end
end
```

**For controllers where the resource name differs from controller name:**

```ruby
# When controller_name is 'details' but resource is 'work_order'
module WorkOrders
  class DetailsController < ApplicationController
    include SoftDeletableController

    # Specify the resource name explicitly
    self.soft_deletable_resource_name = :work_order

    before_action :set_work_order, only: %i[show edit update destroy]

    def destroy
      authorize @work_order
      super
    end

    def restore
      @work_order = WorkOrder.with_discarded.find(params[:id])
      authorize @work_order
      super
    end
  end
end
```

### 4. Routes

All routes already include the `:restorable` concern:

```ruby
# config/routes.rb
Rails.application.routes.draw do
  # Soft delete restore route concern
  concern :restorable do
    member do
      patch :restore
    end
  end

  # Applied to all resources:
  resources :workers, concerns: :restorable
  resources :inventories, concerns: :restorable
  # ... etc
end
```

**Available restore routes:**

- `PATCH /workers/:id/restore`
- `PATCH /inventories/:id/restore`
- `PATCH /master_data/blocks/:id/restore`
- `PATCH /user_management/users/:id/restore`
- ... and all other resources

## Model Usage

### Basic Operations

```ruby
# Soft delete
user.discard          # Sets discarded_at to current time
user.soft_delete      # Alias with callback support
user.archive          # Semantic alias

# Check status
user.discarded?       # true if soft deleted
user.soft_deleted?    # Alias
user.archived?        # Alias
user.kept?            # true if NOT soft deleted

# Restore
user.undiscard        # Clears discarded_at
user.restore          # Alias with callback support
user.unarchive        # Semantic alias
```

### Scopes

```ruby
# Default scope excludes soft-deleted records
User.all              # Only non-deleted users

# Include soft-deleted
User.with_discarded   # All users including deleted

# Only soft-deleted
User.discarded        # Only deleted users

# Only non-deleted (explicit)
User.kept             # Same as default scope
```

### Batch Operations

```ruby
# Via class methods
User.soft_delete_all([1, 2, 3])  # Soft delete multiple
User.restore_all([1, 2, 3])      # Restore multiple

# Via service
SoftDelete::BatchService.call(User, ids: [1, 2, 3], action: :delete)
SoftDelete::BatchService.call(User, ids: [1, 2, 3], action: :restore)
```

### Cascading Soft Delete

For parent-child relationships:

```ruby
class WorkOrder < ApplicationRecord
  include CascadingSoftDelete

  has_many :work_order_items, dependent: :destroy
  has_many :work_order_workers, dependent: :destroy

  # Define associations to cascade soft delete
  cascade_soft_delete :work_order_items, :work_order_workers
end

# Now when work_order is soft deleted, items and workers are also soft deleted
work_order.soft_delete
```

## Customizing Behavior

### Custom Callbacks

```ruby
class User < ApplicationRecord
  private

  def after_discard
    # Called after soft delete
    UserMailer.account_deleted_email(self).deliver_later
  end

  def after_undiscard
    # Called after restore
    UserMailer.account_restored_email(self).deliver_later
  end
end
```

### Disabling Default Scope

If you don't want soft-deleted records automatically excluded:

```ruby
class AuditLog < ApplicationRecord
  include Discard::Model  # Use directly instead of SoftDeletable

  # No default_scope, soft-deleted records are included by default
end
```

## Querying with Associations

```ruby
# Find records with discarded associations
users_with_deleted_orders = User.joins(
  "INNER JOIN work_orders ON work_orders.field_conductor_id = users.id"
).merge(WorkOrder.with_discarded.discarded)

# Find active records with active associations only
User.joins(:work_orders)  # Only non-deleted work orders (default scope)
```

## Testing

```ruby
# In RSpec
RSpec.describe User do
  describe 'soft delete' do
    let(:user) { create(:user) }

    it 'soft deletes the record' do
      expect { user.discard }.to change { user.discarded? }.from(false).to(true)
      expect(User.count).to eq(0)
      expect(User.with_discarded.count).to eq(1)
    end

    it 'restores the record' do
      user.discard
      expect { user.undiscard }.to change { user.discarded? }.from(true).to(false)
      expect(User.count).to eq(1)
    end
  end
end
```

## Files Reference

| File                                                          | Purpose                                    |
| ------------------------------------------------------------- | ------------------------------------------ |
| `app/models/concerns/soft_deletable.rb`                       | Core soft delete concern for models        |
| `app/models/concerns/cascading_soft_delete.rb`                | Cascade soft delete to associations        |
| `app/controllers/concerns/soft_deletable_controller.rb`       | Controller actions for soft delete         |
| `app/services/soft_delete/service.rb`                         | Single record operations with Result monad |
| `app/services/soft_delete/batch_service.rb`                   | Batch operations with Result monad         |
| `config/initializers/soft_delete_routes.rb`                   | Route helper for soft delete routes        |
| `db/migrate/20251222030000_add_discarded_at_to_all_models.rb` | Migration to add columns                   |
