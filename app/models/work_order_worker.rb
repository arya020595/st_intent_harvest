class WorkOrderWorker < ApplicationRecord
  belongs_to :work_order
  belongs_to :worker

  validates :worker_id, presence: true
  validates :work_area_size, numericality: { greater_than: 0 }, allow_nil: true
  validates :rate, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true

  before_save :populate_worker_name
  before_save :calculate_amount

  private

  def populate_worker_name
    self.worker_name = worker.name if worker_id_changed? && worker
  end

  def calculate_amount
    self.amount = (work_area_size || 0) * (rate || 0)
  end
end

# == Schema Information
#
# Table name: work_order_workers
#
#  id             :integer          not null, primary key
#  work_order_id  :integer          not null
#  worker_id      :integer          not null
#  worker_name    :string
#  work_area_size :integer
#  rate           :decimal(10, 2)
#  amount         :decimal(10, 2)
#  remarks        :text
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#
# Indexes
#
#  index_work_order_workers_on_work_order_id  (work_order_id)
#  index_work_order_workers_on_worker_id      (worker_id)
#
