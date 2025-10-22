class WorkOrderWorker < ApplicationRecord
  belongs_to :work_order
  belongs_to :worker
  
  validates :quantity, numericality: { greater_than: 0 }, allow_nil: true
  validates :rate, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  
  before_save :calculate_amount
  
  private
  
  def calculate_amount
    self.amount = (quantity || 0) * (rate || 0)
  end
end

# == Schema Information
#
# Table name: work_order_workers
#
#  id            :bigint           not null, primary key
#  amount        :decimal(10, 2)
#  quantity      :integer
#  rate          :decimal(10, 2)
#  remarks       :text
#  worker_name   :string
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  work_order_id :bigint           not null
#  worker_id     :bigint           not null
#
# Indexes
#
#  index_work_order_workers_on_work_order_id  (work_order_id)
#  index_work_order_workers_on_worker_id      (worker_id)
#
# Foreign Keys
#
#  fk_rails_...  (work_order_id => work_orders.id)
#  fk_rails_...  (worker_id => workers.id)
#
