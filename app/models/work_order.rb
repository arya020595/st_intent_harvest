class WorkOrder < ApplicationRecord
  belongs_to :block, optional: true
  has_many :work_order_workers, dependent: :destroy
  has_many :work_order_items, dependent: :destroy
  
  validates :start_date, presence: true
  validates :work_order_status, inclusion: { in: %w[pending approved rejected completed], allow_nil: true }
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
