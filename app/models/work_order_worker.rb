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
