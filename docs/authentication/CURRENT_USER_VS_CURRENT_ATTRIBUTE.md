# Current User vs Current Attribute Pattern

## Overview

This application uses **both** `current_user` (from Devise) and `Current.user` (Rails Current Attributes) for different purposes. Understanding when to use each is important for proper authorization, audit trails, and service object integration.

## Quick Comparison

| Feature                          | `current_user` | `Current.user`           |
| -------------------------------- | -------------- | ------------------------ |
| **Source**                       | Devise gem     | Rails Current Attributes |
| **Available in Controllers**     | ✅ Yes         | ✅ Yes                   |
| **Available in Views**           | ✅ Yes         | ✅ Yes                   |
| **Available in Models**          | ❌ No          | ✅ Yes                   |
| **Available in Services**        | ❌ No          | ✅ Yes                   |
| **Available in Background Jobs** | ❌ No          | ✅ Yes                   |
| **Works with Audited Gem**       | ❌ No          | ✅ Yes                   |
| **Thread-safe**                  | ✅ Yes         | ✅ Yes                   |

## What is `current_user`?

`current_user` is a helper method provided by Devise that returns the currently logged-in user.

### Scope

- **Available:** Controllers and Views only
- **Not Available:** Models, Services, Background Jobs, Libraries

### Example Usage

```ruby
# ✅ In Controllers
class WorkOrdersController < ApplicationController
  def create
    @work_order = WorkOrder.new(work_order_params)
    @work_order.field_conductor = current_user  # Works!
    @work_order.save
  end
end

# ✅ In Views
<p>Welcome, <%= current_user.name %>!</p>

# ❌ In Models - WON'T WORK
class WorkOrder < ApplicationRecord
  before_save :set_creator

  def set_creator
    self.created_by = current_user  # ERROR: undefined method `current_user'
  end
end
```

## What is `Current.user`?

`Current.user` is a Rails Current Attributes pattern that stores the current user in a thread-safe way, making it accessible throughout the entire request lifecycle.

### Scope

- **Available:** Everywhere - Controllers, Views, Models, Services, Jobs, Libraries

### How It's Set

In `ApplicationController`, we set it on every request:

```ruby
class ApplicationController < ActionController::Base
  before_action :set_current_user

  private

  def set_current_user
    Current.user = current_user  # Copy from Devise to Current
  end
end
```

### Example Usage

```ruby
# ✅ In Controllers
class WorkOrdersController < ApplicationController
  def create
    @work_order = WorkOrder.new(work_order_params)
    @work_order.field_conductor = Current.user  # Works!
  end
end

# ✅ In Models
class WorkOrder < ApplicationRecord
  before_save :log_creator

  def log_creator
    Rails.logger.info "Created by: #{Current.user.email}"  # Works!
  end
end

# ✅ In Service Objects
class WorkOrderApprovalService
  def approve(work_order)
    work_order.update!(
      approved_by: Current.user.name,
      approved_at: Time.current
    )
  end
end

# ✅ In Background Jobs
class NotifyApprovalJob < ApplicationJob
  def perform(work_order_id)
    # Note: Current.user might be nil in jobs unless explicitly set
    # Jobs run outside the request cycle
    UserMailer.notification(work_order_id, Current.user).deliver_now
  end
end
```

## Why We Need Both

### 1. Audited Gem Integration

The `audited` gem automatically tracks who made changes, but it needs `Current.user`:

```ruby
class WorkOrder < ApplicationRecord
  audited  # Tracks all changes
end

# With Current.user set in ApplicationController:
@work_order.approve!  # AASM transition from pending -> completed
@work_order.audits.last.user  # => #<User id: 1, email: "clerk@example.com"> ✅

# Without Current.user:
@work_order.approve!  # AASM transition
@work_order.audits.last.user  # => nil ❌
```

### 2. Service Objects Need User Context

Service objects run business logic outside controllers and need user context:

```ruby
# app/services/work_order_approval_service.rb
class WorkOrderApprovalService
  def call(work_order)
    work_order.update!(
      approved_by: Current.user.name,    # ✅ Works
      # approved_by: current_user.name,  # ❌ Would fail
      approved_at: Time.current
    )

    WorkOrderHistory.record_transition(
      work_order,
      'pending',
      'completed',
      'approve',
      Current.user,  # ✅ Available here
      "Approved by #{Current.user.name}"
    )
  end
end
```

### 3. Model Callbacks Need User

Model callbacks don't have access to controller methods:

```ruby
class WorkOrder < ApplicationRecord
  after_create :notify_manager

  private

  def notify_manager
    # Who created this work order?
    ManagerMailer.new_work_order(self, Current.user).deliver_later  # ✅ Works
    # ManagerMailer.new_work_order(self, current_user).deliver_later  # ❌ Error
  end
end
```

## Best Practices

### ✅ DO

**Use `current_user` in:**

- Controllers for simple assignments
- Views for display logic
- When you only need user data in the current controller action

```ruby
# Controller
def show
  @user_name = current_user.name
end

# View
<p>Hello, <%= current_user.name %>!</p>
```

**Use `Current.user` in:**

- Models, Services, Libraries
- When using audited gem
- When you need user context across different layers
- Complex business logic that spans multiple objects

```ruby
# Service
class CreateWorkOrderService
  def call(params)
    work_order = WorkOrder.create!(params)
    work_order.update!(field_conductor: Current.user)
    AuditLog.create!(action: 'create', user: Current.user)
  end
end
```

### ❌ DON'T

**Don't:**

- Use `current_user` in models or services (it won't work)
- Forget to set `Current.user` in `ApplicationController`
- Rely on `Current.user` in background jobs without explicitly setting it
- Store sensitive data in `Current` attributes (it's cleared per-request)

## Common Patterns

### Pattern 1: Controller with Service Object

```ruby
class WorkOrdersController < ApplicationController
  def create
    @work_order = CreateWorkOrderService.call(work_order_params)
    # Current.user is already set by before_action
    # Service can access it internally
  end
end

class CreateWorkOrderService
  def self.call(params)
    work_order = WorkOrder.new(params)
    work_order.field_conductor = Current.user  # ✅ Available
    work_order.save!

    # Audit automatically captures Current.user
    work_order
  end
end
```

### Pattern 2: Model with Audit Trail

```ruby
class WorkOrder < ApplicationRecord
  audited  # Uses Current.user automatically

  # AASM automatically tracks transitions with Current.user
  aasm column: :work_order_status do
    state :ongoing, initial: true
    state :pending
    state :completed

    event :approve do
      transitions from: :pending, to: :completed do
        after do
          Rails.logger.info(
            "Status changed to #{work_order_status} by #{Current.user.email}"
          )
        end
      end
    end
  end
end
```

### Pattern 3: Complex Business Logic

```ruby
class WorkOrderApprovalService
  def initialize(work_order)
    @work_order = work_order
    @approver = Current.user  # Capture at initialization
  end

  def approve
    ActiveRecord::Base.transaction do
      # AASM transition - automatically logs to WorkOrderHistory
      @work_order.approve!

      # Update approval metadata
      @work_order.update!(
        approved_by: @approver.name,
        approved_at: Time.current
      )

      # Send notifications
      notify_field_conductor
      notify_managers

      # Log to audit
      AuditLog.create!(
        action: 'approve_work_order',
        user: @approver,
        details: { work_order_id: @work_order.id }
      )
    end
  end

  private

  def notify_field_conductor
    WorkOrderMailer.approved(@work_order, @approver).deliver_later
  end

  def notify_managers
    User.managers.each do |manager|
      ManagerMailer.work_order_approved(@work_order, manager).deliver_later
    end
  end
end

# Usage in controller
class WorkOrder::ApprovalsController < ApplicationController
  def approve
    @work_order = WorkOrder.find(params[:id])
    authorize @work_order, :approve?

    WorkOrderApprovalService.new(@work_order).approve
    # Current.user is available inside the service

    redirect_to @work_order, notice: 'Work order approved!'
  end
end
```

## Background Jobs Caveat

`Current.user` is request-scoped and **not automatically available in background jobs**:

```ruby
# ❌ Won't work as expected
class ProcessWorkOrderJob < ApplicationJob
  def perform(work_order_id)
    work_order = WorkOrder.find(work_order_id)
    Current.user  # => nil (no request context)
  end
end

# ✅ Pass user explicitly
class ProcessWorkOrderJob < ApplicationJob
  def perform(work_order_id, user_id)
    work_order = WorkOrder.find(work_order_id)
    user = User.find(user_id)

    # Set Current.user for the job duration
    Current.user = user

    # Now service objects can use Current.user
    ProcessWorkOrderService.call(work_order)
  ensure
    Current.user = nil  # Clean up
  end
end

# Enqueue with user
ProcessWorkOrderJob.perform_later(@work_order.id, current_user.id)
```

## Implementation Details

### Current Attribute Setup

The `Current` class is defined in `app/models/current.rb`:

```ruby
class Current < ActiveSupport::CurrentAttributes
  attribute :user
end
```

This provides:

- Thread-safe storage per request
- Automatic cleanup after each request
- Access from anywhere in the application

### ApplicationController Setup

```ruby
class ApplicationController < ActionController::Base
  before_action :set_current_user

  private

  def set_current_user
    Current.user = current_user if user_signed_in?
  end
end
```

This ensures:

1. Every request sets `Current.user` from Devise's `current_user`
2. It's set AFTER authentication (`authenticate_user!`)
3. It's available throughout the request lifecycle
4. It's automatically cleared when the request completes

## Debugging

### Check if Current.user is set

```ruby
# In console
Current.user  # => nil (no request context in console)

# In controller/view during request
Current.user  # => #<User id: 1, email: "user@example.com">

# In model during request
class WorkOrder < ApplicationRecord
  before_save :debug_current_user

  def debug_current_user
    Rails.logger.debug "Current.user: #{Current.user.inspect}"
  end
end
```

### Common Issues

**Issue 1: `Current.user` is nil**

```ruby
# Check: Is set_current_user being called?
# Check: Is user authenticated?
# Check: Is this in a background job? (needs manual setting)
```

**Issue 2: Audited not recording user**

```ruby
# Check: Is Current.user set in ApplicationController?
# Check: Is before_action :set_current_user present?
# Check: Is it called AFTER authenticate_user!?
```

## Summary

- **`current_user`**: Devise helper, controllers/views only
- **`Current.user`**: Rails pattern, available everywhere
- **Set once in `ApplicationController`**, use everywhere
- **Audited gem** requires `Current.user` for tracking
- **Service objects** and **models** need `Current.user`
- **Background jobs** need explicit user setting

Both are necessary for a complete, maintainable Rails application with proper authorization, audit trails, and service object patterns.

## Related Documentation

- [Pundit Authorization](PUNDIT_AUTHORIZATION.md)
- [Audited Usage](AUDITED_USAGE.md)
- [Rails Current Attributes Guide](https://api.rubyonrails.org/classes/ActiveSupport/CurrentAttributes.html)
- [Devise Documentation](https://github.com/heartcombo/devise)
