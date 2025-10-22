class WorkOrderItem < ApplicationRecord
  belongs_to :work_order
  belongs_to :inventory, optional: true
  
  validates :item_name, presence: true
  validates :quantity, numericality: { greater_than: 0 }, allow_nil: true
  validates :price, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
end
