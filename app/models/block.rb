class Block < ApplicationRecord
  has_many :work_orders, dependent: :nullify
  
  validates :block_number, presence: true, uniqueness: true
  validates :hectarage, numericality: { greater_than: 0 }, allow_nil: true
end
