# Audited - Audit Trail Usage Guide

## Overview

This application uses the [audited gem](https://github.com/collectiveidea/audited) to automatically track all changes to models, including who created/updated records and what changed.

## Setup

### Installation (Already Done)

```bash
# Install gem
bundle install

# Generate and run migration
rails generate audited:install
rails db:migrate
```

This creates an `audits` table that stores all change history.

## Models Using Audited

### WorkOrder

```ruby
class WorkOrder < ApplicationRecord
  audited
  # ...
end
```

**What gets tracked:**

- Who created the work order (via `audit.user`)
- Who updated it and when
- What fields changed (before/after values)
- Complete state transition history (ongoing → pending → completed)
- Who deleted it (if soft-delete is used)

## Usage Examples

### In Controllers

Audited automatically captures `Current.user` or `current_user` when changes happen:

```ruby
# Create
@work_order = WorkOrder.create!(
  field_conductor: some_user,
  start_date: Date.today
  # ...
)
# Audit automatically created with current_user as the actor

# Update
@work_order.update!(work_order_status: 'completed')
# Audit automatically created showing the change from 'ongoing' to 'completed'
```

### Accessing Audit History

```ruby
# Get all audits for a work order
@work_order.audits
# => [#<Audited::Audit id: 1, ...>, #<Audited::Audit id: 2, ...>]

# Who created it?
@work_order.audits.first.user
# => #<User id: 5, name: "Admin User">

# Who last modified it?
@work_order.audits.last.user
# => #<User id: 3, name: "Manager">

# What changed in the last update?
audit = @work_order.audits.last
audit.audited_changes
# => {"work_order_status"=>["ongoing", "completed"]}

# When was it changed?
audit.created_at
# => 2025-10-26 10:30:00 UTC

# Get all changes to a specific field
@work_order.audits.where("audited_changes ? 'work_order_status'")
```

### In Views

```erb
<!-- Show audit history -->
<h3>Change History</h3>
<table>
  <thead>
    <tr>
      <th>Date</th>
      <th>User</th>
      <th>Action</th>
      <th>Changes</th>
    </tr>
  </thead>
  <tbody>
    <% @work_order.audits.reverse.each do |audit| %>
      <tr>
        <td><%= audit.created_at.strftime('%Y-%m-%d %H:%M') %></td>
        <td><%= audit.user&.name || 'System' %></td>
        <td><%= audit.action.titleize %></td>
        <td>
          <% audit.audited_changes.each do |field, (old_val, new_val)| %>
            <strong><%= field.humanize %>:</strong>
            <%= old_val.inspect %> → <%= new_val.inspect %><br>
          <% end %>
        </td>
      </tr>
    <% end %>
  </tbody>
</table>

<!-- Show who created this record -->
<p>
  <strong>Created by:</strong>
  <%= @work_order.audits.first&.user&.name || 'Unknown' %>
  on <%= @work_order.created_at.strftime('%Y-%m-%d') %>
</p>
```

### Advanced Queries

```ruby
# All audits by a specific user
Audited::Audit.where(user: current_user, auditable_type: 'WorkOrder')

# Recent changes (last 7 days)
WorkOrder.find(123).audits.where('created_at > ?', 7.days.ago)

# Find who approved a work order
work_order.audits.find_by(
  "audited_changes @> ?",
  { work_order_status: ['pending', 'completed'] }.to_json
)&.user

# Revert to previous version (use carefully!)
audit = @work_order.audits.last
audit.undo  # Reverts the last change
```

## Integration with Current User

Audited automatically uses `Current.user` (from Rails 5.2+) or `current_user` helper.

Make sure your `ApplicationController` sets it:

```ruby
class ApplicationController < ActionController::Base
  before_action :set_current_user

  private

  def set_current_user
    Current.user = current_user if user_signed_in?
  end
end
```

## Benefits

### Replaces Manual Audit Fields

**Before (manual tracking):**

```ruby
belongs_to :created_by, class_name: 'User'
belongs_to :updated_by, class_name: 'User'
before_create { self.created_by = current_user }
before_update { self.updated_by = current_user }
```

**After (with audited):**

```ruby
audited
# That's it! Full audit trail automatic.
```

### What You Get

✅ **Complete Change History**

- Not just creation, but every update
- Old and new values for each field
- Timestamp for each change

✅ **Actor Tracking**

- Who created
- Who modified
- Who deleted (if using paranoia/discard gems)

✅ **Audit Queries**

- Filter by user, date, action
- Find specific field changes
- Track workflow transitions

✅ **Compliance & Debugging**

- Regulatory compliance (who changed what when)
- Debug data issues (what changed and when)
- User accountability

## Configuration Options

### Per-Model Options

````ruby
class WorkOrder < ApplicationRecord
  # Basic - track everything (recommended)
  audited

  # Track only specific attributes
  audited only: [:work_order_status, :approved_by, :approved_at]

  # Exclude certain attributes
  audited except: [:updated_at, :block_hectarage]

  # Conditional auditing
  audited if: :should_audit?
  audited unless: :skip_audit?

  def should_audit?
    !importing?
  end
end
```### Global Configuration

```ruby
# config/initializers/audited.rb
Audited.config do |config|
  # Store additional info in each audit
  config.audit_class.attr_accessible :comment
end
````

## Best Practices

### ✅ DO

- Use audited for all business-critical models
- Use `associated_with` to link related audits
- Display audit trails in admin/detail views
- Query audits for compliance reports
- Use audits to debug data issues

### ❌ DON'T

- Don't use audited for high-frequency logs (use proper logging)
- Don't rely on audits for real-time monitoring (they're historical)
- Don't forget to set `Current.user` in controllers
- Don't audit sensitive data without encryption

## Troubleshooting

### Audits Not Being Created

**Check:**

1. Is `Current.user` or `current_user` set?
2. Did you run the migration? (`rails db:migrate`)
3. Is the model actually saving? (audits created on after_save)

### User Is Nil in Audits

**Solution:**
Make sure your controller sets the current user:

```ruby
class ApplicationController < ActionController::Base
  before_action :set_current_user

  private

  def set_current_user
    Current.user = current_user if user_signed_in?
  end
end
```

### Too Many Audits (Performance)

**Solutions:**

- Audit only critical fields: `audited only: [:status, :approved_by]`
- Archive old audits periodically
- Add indexes on `audits` table if querying frequently

## Examples for WorkOrder

### Track Who Submitted for Approval

```ruby
# In controller
def mark_complete
  @work_order.mark_complete!  # AASM transition
  # Audit automatically created showing status change and current_user

  audit = @work_order.audits.last
  redirect_to @work_order, notice: "Submitted by #{audit.user.name}"
end
```

### Display Approval History

```erb
<h4>Approval Trail</h4>
<% status_audits = @work_order.audits.where(
  "audited_changes ? 'work_order_status'"
) %>
<ul>
  <% status_audits.each do |audit| %>
    <li>
      <%= audit.created_at.strftime('%Y-%m-%d %H:%M') %> -
      <%= audit.user&.name %>
      changed status from
      <%= audit.audited_changes['work_order_status'][0] %>
      to
      <%= audit.audited_changes['work_order_status'][1] %>
    </li>
  <% end %>
</ul>
```

### Generate Compliance Report

```ruby
# Who approved work orders this month?
approvals = Audited::Audit.where(
  auditable_type: 'WorkOrder',
  action: 'update'
).where("created_at > ?", 1.month.ago)
 .where("audited_changes @> ?", { work_order_status: ['pending', 'completed'] }.to_json)

approvals.group_by(&:user).each do |user, audits|
  puts "#{user.name}: #{audits.count} approvals"
end
```

## Summary

Audited replaces manual `created_by`/`updated_by` tracking with a comprehensive audit trail that:

- Automatically tracks all changes
- Records who, what, when for every modification
- Provides queryable history for compliance and debugging
- Integrates seamlessly with your existing Rails app

For more details, see the [official audited documentation](https://github.com/collectiveidea/audited).
