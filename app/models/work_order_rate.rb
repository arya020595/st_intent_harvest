class WorkOrderRate < ApplicationRecord
  belongs_to :unit, optional: true
  
  validates :work_order_name, presence: true
  validates :rate, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
end
