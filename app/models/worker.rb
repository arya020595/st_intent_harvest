class Worker < ApplicationRecord
  has_many :work_order_workers, dependent: :destroy
  has_many :work_orders, through: :work_order_workers
  has_many :pay_calculation_details, dependent: :destroy
  has_many :pay_calculations, through: :pay_calculation_details
  
  validates :name, presence: true
  validates :worker_type, presence: true
  validates :gender, inclusion: { in: %w[Male Female], allow_nil: true }
end
