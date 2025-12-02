# frozen_string_literal: true

class WorkOrder < ApplicationRecord
  include AASM
  include Denormalizable
  include WorkOrderTypeBehavior
  include WorkOrderGuardMessages

  # Status constants
  STATUSES = {
    ongoing: 'ongoing',
    pending: 'pending',
    amendment_required: 'amendment_required',
    completed: 'completed'
  }.freeze

  # Audit trail - automatically tracks create/update/destroy with user and changes
  # audited # Temporarily disabled due to Psych::DisallowedClass issue with Date serialization
  # TODO: Re-enable audited after fixing Psych::DisallowedClass issue. See tracking ticket: TICKET-1234

  belongs_to :block, optional: true
  belongs_to :work_order_rate
  # The user responsible for the field (used for scoping/assignment)
  belongs_to :field_conductor, class_name: 'User', optional: true
  has_many :work_order_workers, dependent: :destroy
  has_many :work_order_items, dependent: :destroy
  has_many :work_order_histories, dependent: :destroy

  # Nested attributes for dynamic form
  accepts_nested_attributes_for :work_order_workers, allow_destroy: true, reject_if: :all_blank
  accepts_nested_attributes_for :work_order_items, allow_destroy: true, reject_if: :all_blank

  # Type-based validations using custom validator (Single Responsibility Principle)
  validates_with WorkOrderTypeValidator
  validates :work_order_rate_id, presence: true
  validates :work_order_status, inclusion: { in: STATUSES.values, allow_nil: true }

  # Define denormalized fields - auto-populated from associations
  denormalize :block_number, from: :block
  denormalize :block_hectarage, from: :block, attribute: :hectarage, transform: ->(val) { val.to_s if val }
  denormalize :work_order_rate_name, from: :work_order_rate, attribute: :work_order_name
  denormalize :work_order_rate_price, from: :work_order_rate, attribute: :rate
  denormalize :work_order_rate_unit_name, from: :work_order_rate, attribute: :unit, transform: ->(unit) { unit&.name }
  denormalize :work_order_rate_type, from: :work_order_rate, attribute: :work_order_rate_type
  denormalize :field_conductor_name, from: :field_conductor, attribute: :name

  # Ransack configuration
  def self.ransackable_attributes(_auth_object = nil)
    %w[
      id
      start_date
      completion_date
      work_order_status
      block_number
      block_hectarage
      work_order_rate_name
      work_order_rate_price
      work_order_rate_type
      work_order_rate_unit_name
      field_conductor_name
      approved_by
      approved_at
      work_month
      created_at
      updated_at
      block_id
      work_order_rate_id
      field_conductor_id
    ]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[block work_order_rate field_conductor work_order_workers work_order_items work_order_histories]
  end

  # Guard method for AASM transitions - delegates to concern
  # Follows Single Responsibility and Open/Closed Principles
  def workers_or_items?
    has_required_associations?
  end

  # AASM State Machine Configuration with string column
  aasm column: :work_order_status do
    state :ongoing, initial: true
    state :pending
    state :amendment_required
    state :completed

    # Transitions
    event :mark_complete do
      transitions from: :ongoing, to: :pending, guard: :workers_or_items? do
        after do |*args|
          remarks = args.last.is_a?(Hash) ? args.last[:remarks] : nil
          record_work_order_history(:mark_complete, remarks, 'Work order submitted for approval')
        end
      end
    end

    event :approve do
      transitions from: :pending, to: :completed do
        after do |*args|
          remarks = args.last.is_a?(Hash) ? args.last[:remarks] : nil
          record_work_order_history(:approve, remarks, 'Work order approved and completed')
          process_pay_calculation
        end
      end
    end

    event :request_amendment do
      transitions from: :pending, to: :amendment_required do
        after do |*args|
          remarks = args.last.is_a?(Hash) ? args.last[:remarks] : nil
          record_work_order_history(:request_amendment, remarks, 'Amendment requested by approver')
        end
      end
    end

    event :reopen do
      transitions from: :amendment_required, to: :pending, guard: :workers_or_items? do
        after do |*args|
          remarks = args.last.is_a?(Hash) ? args.last[:remarks] : nil
          record_work_order_history(:reopen, remarks, 'Work order resubmitted after amendments')
        end
      end
    end
  end

  def latest_amendment_history
    WorkOrderHistory.latest_amendment_for(self)
  end

  private

  # Process pay calculation when work order is completed
  def process_pay_calculation
    result = PayCalculationServices::ProcessWorkOrderService.new(self).call

    if result.failure?
      AppLogger.error("Pay calculation failed for WorkOrder ##{id}: #{result.failure}")
    else
      AppLogger.info("Pay calculation processed for WorkOrder ##{id}: #{result.value!}")
    end
  end

  # Helper method to record work order history with optional custom remarks
  # Follows AASM callback parameter passing convention
  def record_work_order_history(event_name, custom_remarks, default_remarks)
    final_remarks = custom_remarks.presence || default_remarks

    WorkOrderHistory.record_transition(
      work_order: self,
      event_name: event_name,
      user: Current.user,
      remarks: final_remarks
    )
  end
end

# == Schema Information
#
# Table name: work_orders
#
#  id                    :integer , not null
#  approved_at           :datetime
#  approved_by           :string
#  block_hectarage       :string
#  block_id              :integer
#  block_number          :string
#  created_at            :datetime, not null
#  field_conductor_id    :integer
#  field_conductor_name  :string
#  start_date            :date
#  updated_at            :datetime, not null
#  work_month            :date    , comment: "First day of the month for Mandays calculation"
#  work_order_rate_id    :integer
#  work_order_rate_name  :string
#  work_order_rate_price :decimal , precision: 10, scale: 2
#  work_order_status     :string  , default("ongoing")
#
# Indexes
#
#  index_work_orders_on_block_and_rate                (block_id, work_order_rate_id)
#  index_work_orders_on_block_id                      (block_id)
#  index_work_orders_on_field_conductor_id            (field_conductor_id)
#  index_work_orders_on_work_order_rate_id            (work_order_rate_id)
#
# Foreign Keys
#
#  fk_rails_8a5d10c0ab                                (work_order_rate_id => work_order_rates.id)
#  fk_rails_ada4e43333                                (block_id => blocks.id)
#  fk_rails_d5db43ba21                                (field_conductor_id => users.id)
#
