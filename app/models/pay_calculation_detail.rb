class PayCalculationDetail < ApplicationRecord
  belongs_to :pay_calculation
  belongs_to :worker

  validates :gross_salary, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :deductions, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :net_salary, numericality: true, allow_nil: true
  validates :worker_deductions, numericality: { greater_than_or_equal_to: 0 }
  validates :employee_deductions, numericality: { greater_than_or_equal_to: 0 }

  before_save :apply_deductions
  before_save :calculate_net_salary

  def self.ransackable_attributes(_auth_object = nil)
    %w[id gross_salary deductions net_salary currency worker_deductions employee_deductions created_at updated_at
       pay_calculation_id worker_id]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[pay_calculation worker]
  end

  private

  def apply_deductions
    result = PayCalculationServices::DeductionCalculator.calculate

    self.worker_deductions = result.worker_deduction
    self.employee_deductions = result.employee_deduction
    self.deduction_breakdown = result.deduction_breakdown
  end

  def calculate_net_salary
    self.net_salary = (gross_salary || 0) - worker_deductions
    self.deductions = worker_deductions # Legacy compatibility
  end
end

# == Schema Information
#
# Table name: pay_calculation_details
#
#  id                 :bigint           not null, primary key
#  currency           :string           default("RM")
#  deductions         :decimal(10, 2)
#  gross_salary       :decimal(10, 2)
#  net_salary         :decimal(10, 2)
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  pay_calculation_id :bigint           not null
#  worker_id          :bigint           not null
#
# Indexes
#
#  index_pay_calculation_details_on_pay_calculation_id  (pay_calculation_id)
#  index_pay_calculation_details_on_worker_id           (worker_id)
#
# Foreign Keys
#
#  fk_rails_...  (pay_calculation_id => pay_calculations.id)
#  fk_rails_...  (worker_id => workers.id)
#
