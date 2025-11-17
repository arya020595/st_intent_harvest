# frozen_string_literal: true

# Custom validator for WorkOrder that validates fields based on work_order_rate_type
# Follows Single Responsibility Principle by isolating type-based validation logic
class WorkOrderTypeValidator < ActiveModel::Validator
  def validate(record)
    return unless record.work_order_rate

    validate_by_type(record)
  end

  private

  def validate_by_type(record)
    case record.work_order_rate.work_order_rate_type
    when 'normal'
      validate_normal_type(record)
    when 'work_days'
      validate_work_days_type(record)
    when 'resources'
      validate_resources_type(record)
    end
  end

  def validate_normal_type(record)
    record.errors.add(:start_date, :blank) if record.start_date.blank?
    record.errors.add(:block_id, :blank) if record.block_id.blank?
  end

  def validate_work_days_type(record)
    record.errors.add(:work_month, :blank) if record.work_month.blank?
  end

  def validate_resources_type(record)
    # Resources type has no additional field validations
    # Only requires items, which is checked in the guard method
  end
end
