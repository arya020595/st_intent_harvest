class WorkOrder < ApplicationRecord
  belongs_to :block, optional: true
  has_many :work_order_workers, dependent: :destroy
  has_many :workers, through: :work_order_workers
  has_many :work_order_items, dependent: :destroy
  
  validates :start_date, presence: true
  validates :work_order_status, inclusion: { in: %w[pending approved rejected completed], allow_nil: true }
end
