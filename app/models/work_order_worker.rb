class WorkOrderWorker < ApplicationRecord
  include Denormalizable

  belongs_to :work_order
  belongs_to :worker

  validates :work_area_size, numericality: { greater_than: 0 }, allow_nil: true
  validates :rate, numericality: { greater_than_or_equal_to: 0, message: 'must be 0 or greater' }, allow_nil: true

  # Denormalize worker name from worker association
  denormalize :worker_name, from: :worker, attribute: :name

  before_save :calculate_amount

  private

  def calculate_amount
    # Calculate amount based on work_order's rate type
    if work_order&.work_order_rate&.work_days?
      # For work_days type: amount = rate * work_days
      self.amount = (rate || 0) * (work_days || 0)
    else
      # For normal/resources type: amount = rate * work_area_size
      self.amount = (work_area_size || 0) * (rate || 0)
    end
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
