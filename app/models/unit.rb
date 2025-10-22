class Unit < ApplicationRecord
  has_many :inventories, dependent: :nullify
  has_many :work_order_rates, dependent: :nullify
  
  validates :name, presence: true
end
