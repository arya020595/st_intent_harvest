# frozen_string_literal: true

# Concern for WorkOrder guard failure messages
# Follows Single Responsibility Principle by isolating error message generation
# Follows Open/Closed Principle - easy to extend with new message types
module WorkOrderGuardMessages
  extend ActiveSupport::Concern

  # Error message templates
  GUARD_FAILURE_MESSAGES = {
    workers: 'Cannot submit work order: Please add at least one worker before submitting.',
    items: 'Cannot submit work order: Please add at least one item/resource before submitting.',
    workers_or_items: 'Cannot submit work order: Please add at least one worker or item before submitting.',
    default: 'Cannot submit work order: Required information is missing.'
  }.freeze

  # Generate user-friendly error message when guard fails
  # @return [String] Human-readable error message based on work order type
  def guard_failure_message
    requirement_type = required_associations.first || :default
    GUARD_FAILURE_MESSAGES[requirement_type] || GUARD_FAILURE_MESSAGES[:default]
  end
end
