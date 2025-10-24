# frozen_string_literal: true

class WorkOrder < ApplicationRecord
  include AASM

  belongs_to :block
  belongs_to :work_order_rate
  has_many :work_order_workers, dependent: :destroy
  has_many :work_order_items, dependent: :destroy
  has_many :work_order_histories, dependent: :destroy

  validates :start_date, presence: true
  validates :work_order_status, inclusion: { in: %w[ongoing pending amendment_required completed], allow_nil: true }
  
  # AASM State Machine Configuration with string column
  aasm column: :work_order_status do
    state :ongoing, initial: true
    state :pending
    state :amendment_required
    state :completed

    # Transitions
    event :mark_complete do
      transitions from: :ongoing, to: :pending do
        after do
          WorkOrderHistory.record_transition(self, 'ongoing', 'pending', 'mark_complete', Current.user, "State transitioned from ongoing to pending")
        end
      end
    end

    event :approve do
      transitions from: :pending, to: :completed do
        after do
          WorkOrderHistory.record_transition(self, 'pending', 'completed', 'approve', Current.user, "State transitioned from pending to completed")
        end
      end
    end

    event :request_amendment do
      transitions from: :pending, to: :amendment_required do
        after do
          WorkOrderHistory.record_transition(self, 'pending', 'amendment_required', 'request_amendment', Current.user, "State transitioned from pending to amendment_required")
        end
      end
    end

    event :reopen do
      transitions from: :amendment_required, to: :pending do
        after do
          WorkOrderHistory.record_transition(self, 'amendment_required', 'pending', 'reopen', Current.user, "State transitioned from amendment_required to pending")
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
#  field_conductor       :string
#  start_date            :date
#  work_order_rate_name  :string
#  work_order_rate_price :decimal(10, 2)
#  work_order_status     :string
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#  block_id              :bigint
#  work_order_rate_id    :bigint
#
# Indexes
#
#  index_work_orders_on_block_and_rate      (block_id,work_order_rate_id)
#  index_work_orders_on_block_id            (block_id)
#  index_work_orders_on_work_order_rate_id  (work_order_rate_id)
#
# Foreign Keys
#
#  fk_rails_...  (block_id => blocks.id)
#  fk_rails_...  (work_order_rate_id => work_order_rates.id)
#
