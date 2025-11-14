# frozen_string_literal: true

class WorkOrderHistory < ApplicationRecord
  include Denormalizable

  belongs_to :work_order
  belongs_to :user, optional: true

  validates :work_order_id, presence: true
  validates :from_state, :to_state, presence: true
  validates :action, presence: true

  # Denormalize user name to avoid JOINs when displaying history
  denormalize :user_name, from: :user, attribute: :name

  scope :recent, -> { order(created_at: :desc) }
  scope :for_work_order, ->(work_order_id) { where(work_order_id: work_order_id).recent }
  # Histories that indicate the work order moved to amendment_required
  scope :amendments, -> { where(to_state: 'amendment_required') }
  scope :since, ->(time) { where('created_at >= ?', time).recent }

  # Simplified transition recording - derives states from AASM
  def self.record_transition(work_order:, event_name:, user: nil, remarks: nil)
    create(
      work_order: work_order,
      from_state: work_order.aasm.from_state.to_s,
      to_state: work_order.aasm.to_state.to_s,
      action: event_name.to_s,
      user: user,
      remarks: remarks,
      transition_details: build_transition_details(work_order)
    )
  end

  def transition_description
    "#{from_state&.titleize} → #{to_state&.titleize}"
  end

  # Extract relevant data from work order for audit trail
  def self.build_transition_details(work_order)
    {
      workers_count: work_order.work_order_workers.count,
      items_count: work_order.work_order_items.count,
      block_number: work_order.block_number,
      work_order_rate_name: work_order.work_order_rate_name
    }
  end
  private_class_method :build_transition_details

  # Return the most recent WorkOrderHistory for a work order that amendment
  def self.latest_amendment_for(work_order_or_id)
    id = work_order_or_id.respond_to?(:id) ? work_order_or_id.id : work_order_or_id
    for_work_order(id).amendments.first
  end
end

# == Schema Information
#
# Table name: work_order_histories
#
#  id                 :bigint           not null, primary key
#  action             :string
#  from_state         :string
#  remarks            :text
#  to_state           :string
#  transition_details :jsonb
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  user_id            :bigint
#  work_order_id      :bigint           not null
#
# Indexes
#
#  index_work_order_histories_on_order_and_created  (work_order_id,created_at)
#  index_work_order_histories_on_user_id            (user_id)
#  index_work_order_histories_on_work_order_id      (work_order_id)
#
# Foreign Keys
#
#  fk_rails_...  (user_id => users.id)
#  fk_rails_...  (work_order_id => work_orders.id)
#
