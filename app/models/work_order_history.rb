# frozen_string_literal: true

class WorkOrderHistory < ApplicationRecord
  belongs_to :work_order
  belongs_to :user, optional: true

  validates :work_order_id, presence: true
  validates :from_state, :to_state, presence: true
  validates :action, presence: true

  scope :recent, -> { order(created_at: :desc) }
  scope :for_work_order, ->(work_order_id) { where(work_order_id: work_order_id).recent }
  scope :since, ->(time) { where('created_at >= ?', time).recent }

  def self.record_transition(work_order, from_state, to_state, action, user = nil, remarks = nil)
    create(
      work_order: work_order,
      from_state: from_state,
      to_state: to_state,
      action: action,
      user: user,
      remarks: remarks,
      transition_details: {}
    )
  end

  def transition_description
    "#{from_state&.titleize} → #{to_state&.titleize}"
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
#  transition_details :text             default("{}")
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
