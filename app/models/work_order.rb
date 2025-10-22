class WorkOrder < ApplicationRecord
  belongs_to :block, optional: true
  has_many :work_order_workers, dependent: :destroy
  has_many :workers, through: :work_order_workers
  has_many :work_order_items, dependent: :destroy
  
  validates :start_date, presence: true
  validates :work_order_status, inclusion: { in: %w[pending approved rejected completed], allow_nil: true }
end

# == Schema Information
#
# Table name: work_orders
#
#  id                :bigint           not null, primary key
#  approved_at       :datetime
#  approved_by       :string
#  hired_date        :date
#  identity_number   :string
#  is_active         :boolean          default(TRUE)
#  start_date        :date
#  work_order_status :string
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  block_id          :bigint
#
# Indexes
#
#  index_work_orders_on_block_id         (block_id)
#  index_work_orders_on_identity_number  (identity_number)
#
# Foreign Keys
#
#  fk_rails_...  (block_id => blocks.id)
#
