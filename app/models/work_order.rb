# frozen_string_literal: true

class WorkOrder < ApplicationRecord
  include AASM
  include Denormalizable

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

  belongs_to :block
  belongs_to :work_order_rate
  # The user responsible for the field (used for scoping/assignment)
  belongs_to :field_conductor, class_name: 'User', optional: true
  has_many :work_order_workers, dependent: :destroy
  has_many :work_order_items, dependent: :destroy
  has_many :work_order_histories, dependent: :destroy

  # Nested attributes for dynamic form
  accepts_nested_attributes_for :work_order_workers, allow_destroy: true, reject_if: :all_blank
  accepts_nested_attributes_for :work_order_items, allow_destroy: true, reject_if: :all_blank

  validates :start_date, presence: true
  validates :block_id, presence: true
  validates :work_order_rate_id, presence: true
  validates :work_order_status, inclusion: { in: STATUSES.values, allow_nil: true }

  # Define denormalized fields - auto-populated from associations
  denormalize :block_number, from: :block
  denormalize :block_hectarage, from: :block, attribute: :hectarage, transform: ->(val) { val.to_s if val }
  denormalize :work_order_rate_name, from: :work_order_rate, attribute: :work_order_name
  denormalize :work_order_rate_price, from: :work_order_rate, attribute: :rate
  denormalize :field_conductor_name, from: :field_conductor, attribute: :name

  # Ransack configuration
  def self.ransackable_attributes(_auth_object = nil)
    %w[
      id
      start_date
      work_order_status
      block_number
      block_hectarage
      work_order_rate_name
      work_order_rate_price
      field_conductor_name
      approved_by
      approved_at
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

  # Custom validation method - checks if work order has workers or items
  # Used as a guard for AASM transitions to pending state
  # Filters out records marked for destruction (when user removes them via nested form)
  def workers_or_items?
    # Count existing workers not marked for deletion
    workers_count = work_order_workers.reject(&:marked_for_destruction?).count
    # Count existing items not marked for deletion
    items_count = work_order_items.reject(&:marked_for_destruction?).count

    workers_count.positive? || items_count.positive?
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
        after do |**options|
          custom_remarks = options[:remarks] || 'Work order submitted for approval'

          WorkOrderHistory.record_transition(
            work_order: self,
            event_name: :mark_complete,
            user: Current.user,
            remarks: custom_remarks
          )
        end
      end
    end

    event :approve do
      transitions from: :pending, to: :completed do
        after do |**options|
          custom_remarks = options[:remarks] || 'Work order approved and completed'

          WorkOrderHistory.record_transition(
            work_order: self,
            event_name: :approve,
            user: Current.user,
            remarks: custom_remarks
          )
        end
      end
    end

    event :request_amendment do
      transitions from: :pending, to: :amendment_required do
        after do |**options|
          custom_remarks = options[:remarks] || 'Amendment requested by approver'

          WorkOrderHistory.record_transition(
            work_order: self,
            event_name: :request_amendment,
            user: Current.user,
            remarks: custom_remarks
          )
        end
      end
    end

    event :reopen do
      transitions from: :amendment_required, to: :pending, guard: :workers_or_items? do
        after do |**options|
          custom_remarks = options[:remarks] || 'Work order resubmitted after amendments'

          WorkOrderHistory.record_transition(
            work_order: self,
            event_name: :reopen,
            user: Current.user,
            remarks: custom_remarks
          )
        end
      end
    end
  end
end

# == Schema Information
#
# Table name: work_orders
#
#  id                    :bigint           not null, primary key
#  approved_at           :datetime
#  approved_by           :string
#  block_hectarage       :string
#  block_number          :string
#  field_conductor_name  :string
#  start_date            :date
#  work_order_rate_name  :string
#  work_order_rate_price :decimal(10, 2)
#  work_order_status     :string           default("ongoing")
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#  block_id              :bigint
#  field_conductor_id    :bigint
#  work_order_rate_id    :bigint
#
# Indexes
#
#  index_work_orders_on_block_and_rate       (block_id,work_order_rate_id)
#  index_work_orders_on_block_id             (block_id)
#  index_work_orders_on_field_conductor_id   (field_conductor_id)
#  index_work_orders_on_work_order_rate_id   (work_order_rate_id)
#
# Foreign Keys
#
#  fk_rails_...  (block_id => blocks.id)
#  fk_rails_...  (field_conductor_id => users.id)
#  fk_rails_...  (work_order_rate_id => work_order_rates.id)
#
