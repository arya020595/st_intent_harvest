# frozen_string_literal: true

# Concern for WorkOrder type-specific behavior
# Follows Single Responsibility Principle by isolating type checking logic
# Follows Open/Closed Principle - easy to extend with new types
module WorkOrderTypeBehavior
  extend ActiveSupport::Concern

  # Type checking methods - delegates to work_order_rate
  def normal_type?
    work_order_rate&.normal?
  end

  def work_days_type?
    work_order_rate&.work_days?
  end

  def resources_type?
    work_order_rate&.resources?
  end

  # Strategy pattern for validation requirements
  # Returns what is required based on type
  def required_associations
    case work_order_rate&.work_order_rate_type
    when 'normal'
      [:workers_or_items]
    when 'work_days'
      [:workers]
    when 'resources'
      [:items]
    else
      []
    end
  end

  # Checks if the work order has the required associations for its type
  def has_required_associations?
    requirements = required_associations

    return true if requirements.empty?

    workers_count = work_order_workers.reject(&:marked_for_destruction?).count
    items_count = work_order_items.reject(&:marked_for_destruction?).count

    requirements.all? do |requirement|
      case requirement
      when :workers
        workers_count.positive?
      when :items
        items_count.positive?
      when :workers_or_items
        workers_count.positive? || items_count.positive?
      else
        false
      end
    end
  end
end
