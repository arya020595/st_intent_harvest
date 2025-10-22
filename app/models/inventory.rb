class Inventory < ApplicationRecord
  belongs_to :category, optional: true
  belongs_to :unit, optional: true
  has_many :work_order_items, dependent: :nullify
  
  validates :name, presence: true
  validates :quantity, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :price, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
end
