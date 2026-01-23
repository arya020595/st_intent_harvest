# Work Order Status Flow Documentation

## Overview

The Work Order system uses AASM (Acts As State Machine) to manage the lifecycle of work orders through different states. This ensures data integrity, provides audit trails, and enforces business rules for state transitions.

## State Machine Architecture

### Technology Stack

- **AASM Gem**: State machine implementation
- **String-based States**: Human-readable status values stored in database
- **Automatic History Tracking**: Every state transition is automatically logged

### Database Schema

```ruby
# work_orders table
work_order_status: string, default: 'ongoing'

# work_order_histories table (audit trail)
- work_order_id
- from_state
- to_state
- action
- user_id
- remarks
- created_at
```

## Work Order States

### 1. **Ongoing** (Initial State)

- **Description**: Work order is in draft mode
- **Purpose**: Allows users to create and edit work orders before submission
- **Color Code**: ⚠️ Warning/Yellow
- **Who Can Access**: Creator, Editors

### 2. **Pending**

- **Description**: Work order submitted and awaiting approval
- **Purpose**: Work order is complete and ready for manager review
- **Color Code**: ℹ️ Info/Blue
- **Who Can Access**: Approvers, Managers

### 3. **Amendment Required**

- **Description**: Work order needs corrections/changes
- **Purpose**: Approver has requested modifications before approval
- **Color Code**: 🔶 Warning/Orange
- **Who Can Access**: Creator, Editors

### 4. **Completed**

- **Description**: Work order approved and finalized
- **Purpose**: Work order has been reviewed and accepted
- **Color Code**: ✅ Success/Green
- **Who Can Access**: All (Read-only)

## State Transition Flow

```
┌─────────────────────────────────────────────────────────────┐
│                    Work Order Lifecycle                      │
└─────────────────────────────────────────────────────────────┘

  CREATE
    │
    ▼
┌──────────────┐
│   ONGOING    │ ◄──────────────────────┐
│   (Draft)    │                        │
└──────┬───────┘                        │
       │                                │
       │ mark_complete!                 │
       │ "Submit for Approval"          │
       │                                │
       ▼                                │
┌──────────────┐                        │
│   PENDING    │                        │
│ (Awaiting    │                        │
│  Approval)   │                        │
└──┬────────┬──┘                        │
   │        │                           │
   │        │ request_amendment!        │
   │        │ "Request Changes"         │
   │        │                           │
   │        ▼                           │
   │   ┌────────────────┐               │
   │   │   AMENDMENT    │               │
   │   │   REQUIRED     │───────────────┘
   │   │ (Needs Fixes)  │   reopen!
   │   └────────────────┘   "Resubmit"
   │
   │ approve!
   │ "Approve & Complete"
   │
   ▼
┌──────────────┐
│  COMPLETED   │
│   (Final)    │
└──────────────┘
```

## State Transition Events

### 1. `mark_complete!`

**Transition**: `ongoing` → `pending`

**Trigger**: User clicks "Complete" or "Submit for Approval" button

**Business Logic**:

- Validates all required fields are filled
- Moves work order to approval queue
- Notifies approvers (if implemented)

**Remarks**: "Work order submitted for approval"

**Code Example**:

```ruby
work_order = WorkOrder.find(1)
work_order.mark_complete!
# Status changes from 'ongoing' to 'pending'
```

**Controller Action**:

```ruby
def mark_complete
  if @work_order.mark_complete!
    redirect_to work_order_detail_path(@work_order),
                notice: 'Work order submitted for approval.'
  end
rescue AASM::InvalidTransition
  redirect_to work_order_detail_path(@work_order),
              alert: 'Can only submit ongoing work orders.'
end
```

---

### 2. `approve!`

**Transition**: `pending` → `completed`

**Trigger**: Approver clicks "Approve" button

**Business Logic**:

- Sets `approved_by` to current user's name
- Sets `approved_at` to current timestamp
- Finalizes the work order
- Work order becomes read-only

**Remarks**: "Work order approved and completed"

**Code Example**:

```ruby
work_order = WorkOrder.find(1)
work_order.approve!
work_order.update(
  approved_by: current_user.name,
  approved_at: Time.current
)
# Status changes from 'pending' to 'completed'
```

**Authorization**: Requires `approve` permission on WorkOrder

---

### 3. `request_amendment!`

**Transition**: `pending` → `amendment_required`

**Trigger**: Approver clicks "Request Amendment" button

**Business Logic**:

- Returns work order to creator for corrections
- Sets `approved_by` to reviewer's name
- Allows creator to edit and resubmit
- Optionally include amendment notes/comments

**Remarks**: "Amendment requested by approver"

**Code Example**:

```ruby
work_order = WorkOrder.find(1)
work_order.request_amendment!
work_order.update(
  approved_by: current_user.name,
  approved_at: Time.current
)
# Status changes from 'pending' to 'amendment_required'
```

**Authorization**: Requires `approve` permission on WorkOrder

---

### 4. `reopen!`

**Transition**: `amendment_required` → `pending`

**Trigger**: User clicks "Resubmit" after making corrections

**Business Logic**:

- Resubmits work order for approval
- Clears previous amendment requests
- Returns to approval queue
- Can be approved or requested for amendment again

**Remarks**: "Work order resubmitted after amendments"

**Code Example**:

```ruby
work_order = WorkOrder.find(1)
# User makes corrections...
work_order.reopen!
# Status changes from 'amendment_required' to 'pending'
```

---

## State Query Methods

AASM provides convenient boolean methods to check the current state:

```ruby
work_order = WorkOrder.find(1)

# Check current state
work_order.ongoing?              # => true/false
work_order.pending?              # => true/false
work_order.amendment_required?   # => true/false
work_order.completed?            # => true/false

# Get current state
work_order.aasm.current_state    # => :ongoing, :pending, etc.
work_order.work_order_status     # => 'ongoing', 'pending', etc.
```

## Automatic History Tracking

Every state transition automatically creates a `WorkOrderHistory` record:

```ruby
# After any state transition
work_order.work_order_histories.last
# => {
#   from_state: 'ongoing',
#   to_state: 'pending',
#   action: 'mark_complete',
#   user_id: 123,
#   remarks: 'Work order submitted for approval',
#   created_at: '2025-10-24 10:30:00'
# }

# View full history
work_order.work_order_histories.order(:created_at).each do |h|
  puts "#{h.from_state} → #{h.to_state} by #{h.user&.name} at #{h.created_at}"
  puts "  #{h.remarks}"
end
```

## User Interface Guidelines

### Creating New Work Order

#### Option 1: Save as Draft

```ruby
# User clicks "Save as Draft" button
@work_order.work_order_status = 'ongoing'
@work_order.save
# Message: "Work order saved as draft."
```

#### Option 2: Submit for Approval

```ruby
# User clicks "Complete" button
@work_order.work_order_status = 'pending'
@work_order.save
# Message: "Work order submitted for approval."
```

### Status Badges (Recommended UI)

```erb
<!-- Ongoing -->
<span class="badge badge-warning">
  <i class="fas fa-edit"></i> Draft
</span>

<!-- Pending -->
<span class="badge badge-info">
  <i class="fas fa-clock"></i> Pending Approval
</span>

<!-- Amendment Required -->
<span class="badge badge-warning">
  <i class="fas fa-exclamation-triangle"></i> Amendment Required
</span>

<!-- Completed -->
<span class="badge badge-success">
  <i class="fas fa-check-circle"></i> Completed
</span>
```

### Action Buttons by State

#### Ongoing State

- ✏️ **Edit** - Modify work order details
- ✅ **Submit for Approval** - Trigger `mark_complete!`
- 🗑️ **Delete** - Remove draft

#### Pending State

- 👁️ **View Only** - No editing allowed
- ✅ **Approve** (Approvers only) - Trigger `approve!`
- 🔄 **Request Amendment** (Approvers only) - Trigger `request_amendment!`

#### Amendment Required State

- ✏️ **Edit** - Make requested changes
- 🔄 **Resubmit** - Trigger `reopen!`
- 👁️ **View History** - See amendment notes

#### Completed State

- 👁️ **View Only** - Read-only access
- 📄 **Print/Export** - Generate reports

## Database Queries

### Filter by Status

```ruby
# Find all drafts
WorkOrder.where(work_order_status: 'ongoing')

# Find pending approvals
WorkOrder.where(work_order_status: 'pending')

# Find work orders needing amendments
WorkOrder.where(work_order_status: 'amendment_required')

# Find completed work orders
WorkOrder.where(work_order_status: 'completed')
```

### Count by Status

```ruby
{
  ongoing: WorkOrder.where(work_order_status: 'ongoing').count,
  pending: WorkOrder.where(work_order_status: 'pending').count,
  amendment_required: WorkOrder.where(work_order_status: 'amendment_required').count,
  completed: WorkOrder.where(work_order_status: 'completed').count
}
```

### Recent Activity

```ruby
# Get recent state changes
WorkOrderHistory
  .includes(:work_order, :user)
  .order(created_at: :desc)
  .limit(10)

# Get work orders pending approval for > 3 days
WorkOrder
  .where(work_order_status: 'pending')
  .where('updated_at < ?', 3.days.ago)
```

## Error Handling

### Invalid State Transitions

AASM raises `AASM::InvalidTransition` when attempting invalid transitions:

```ruby
begin
  work_order.approve! # If not in 'pending' state
rescue AASM::InvalidTransition => e
  # Handle error
  flash[:alert] = "Cannot approve work order in #{work_order.work_order_status} state"
end
```

### Common Invalid Transitions

- ❌ `ongoing` → `completed` (Must go through pending)
- ❌ `completed` → any state (Final state, no transitions)
- ❌ `ongoing` → `amendment_required` (Must be pending first)

## Permissions & Authorization

### Using Pundit Policy

```ruby
class WorkOrderPolicy < ApplicationPolicy
  def mark_complete?
    user.present? && record.ongoing?
  end

  def approve?
    user.present? && user.has_permission?('WorkOrder', 'approve') && record.pending?
  end

  def request_amendment?
    approve? # Same permission as approve
  end

  def reopen?
    user.present? && record.amendment_required?
  end
end
```

### Controller Authorization

```ruby
class WorkOrder::ApprovalsController < ApplicationController
  def approve
    authorize @work_order, :approve?
    @work_order.approve!
    # ...
  end

  def request_amendment
    authorize @work_order, :approve?
    @work_order.request_amendment!
    # ...
  end
end
```

## Best Practices

### ✅ DO

1. **Always use state machine events** instead of directly setting status

   ```ruby
   # Good
   work_order.mark_complete!

   # Bad
   work_order.update(work_order_status: 'pending')
   ```

2. **Check state before showing action buttons**

   ```ruby
   <% if @work_order.ongoing? %>
     <%= button_to "Submit", mark_complete_path %>
   <% end %>
   ```

3. **Use transaction blocks for complex operations**

   ```ruby
   ActiveRecord::Base.transaction do
     work_order.approve!
     work_order.update!(approved_by: current_user.name)
     # Send notification...
   end
   ```

4. **Log state transitions in controllers**
   ```ruby
   Rails.logger.info "Work Order ##{@work_order.id} #{action} by User ##{current_user.id}"
   ```

### ❌ DON'T

1. **Don't bypass state machine validations**

   ```ruby
   # Bad - Skips history tracking and validations
   work_order.update_column(:work_order_status, 'completed')
   ```

2. **Don't allow state changes without authorization**

   ```ruby
   # Missing authorization check
   def approve
     @work_order.approve! # Dangerous!
   end
   ```

3. **Don't forget to handle exceptions**
   ```ruby
   # Always rescue AASM::InvalidTransition
   begin
     work_order.approve!
   rescue AASM::InvalidTransition
     # Handle error
   end
   ```

## Testing

### RSpec Examples

```ruby
RSpec.describe WorkOrder, type: :model do
  describe 'state transitions' do
    let(:work_order) { create(:work_order, work_order_status: 'ongoing') }

    it 'transitions from ongoing to pending' do
      expect { work_order.mark_complete! }
        .to change(work_order, :work_order_status)
        .from('ongoing').to('pending')
    end

    it 'creates history record on transition' do
      expect { work_order.mark_complete! }
        .to change(WorkOrderHistory, :count).by(1)
    end

    it 'prevents invalid transitions' do
      expect { work_order.approve! }
        .to raise_error(AASM::InvalidTransition)
    end
  end
end
```

## Troubleshooting

### Issue: State transition not working

**Solution**: Check current state and valid transitions

```ruby
work_order.aasm.current_state  # Check current state
work_order.aasm.states         # See all available states
work_order.aasm.events         # See all available events
```

### Issue: History not being recorded

**Solution**: Ensure `Current.user` is set

```ruby
# In ApplicationController
before_action :set_current_user

def set_current_user
  Current.user = current_user
end
```

### Issue: AASM::InvalidTransition errors

**Solution**: Add proper error handling in controllers

```ruby
rescue_from AASM::InvalidTransition do |exception|
  redirect_back fallback_location: root_path,
                alert: "Invalid state transition: #{exception.message}"
end
```

## Database Migration

If you need to add states or modify transitions:

1. **Add new state to validation**

   ```ruby
   validates :work_order_status,
     inclusion: { in: %w[ongoing pending amendment_required completed new_state] }
   ```

2. **Add AASM state definition**

   ```ruby
   aasm column: :work_order_status do
     state :new_state
     # ...
   end
   ```

3. **Add transition events**

   ```ruby
   event :new_event do
     transitions from: :some_state, to: :new_state
   end
   ```

4. **Update existing records if needed**
   ```ruby
   # Migration
   WorkOrder.where(work_order_status: 'old_status')
            .update_all(work_order_status: 'new_status')
   ```

## References

- **AASM Documentation**: https://github.com/aasm/aasm
- **Rails State Machines**: https://guides.rubyonrails.org/
- **Pundit Authorization**: https://github.com/varvet/pundit

---

**Document Version**: 1.0  
**Last Updated**: October 24, 2025  
**Maintained By**: Development Team
