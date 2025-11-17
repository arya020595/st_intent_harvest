# frozen_string_literal: true

# Allow NULL values in work_days column for WorkOrderWorkers
#
# Rationale:
# - For 'normal' type work orders: work_days is not used → should be NULL
# - For 'resources' type: work_days is not used → should be NULL
# - For 'work_days' type: work_days has meaning → can be 0 or positive
#
# NULL = "not applicable" (semantically correct)
# 0 = "zero days worked" (actual value)
#
# This also fixes the PG::NotNullViolation when empty string comes from forms
class AllowNullWorkDaysInWorkOrderWorkers < ActiveRecord::Migration[8.0]
  def change
    # Allow NULL values in work_days
    change_column_null :work_order_workers, :work_days, true

    # Change default from 0 to NULL
    change_column_default :work_order_workers, :work_days, from: 0, to: nil
  end
end
