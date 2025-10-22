class PayCalculationDetail < ApplicationRecord
  belongs_to :pay_calculation
  belongs_to :worker
  
  validates :gross_salary, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :deductions, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :net_salary, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
end
