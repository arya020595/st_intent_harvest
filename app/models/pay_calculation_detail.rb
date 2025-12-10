# frozen_string_literal: true

class PayCalculationDetail < ApplicationRecord
  belongs_to :pay_calculation
  belongs_to :worker

  validates :gross_salary, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :deductions, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :net_salary, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :employee_deductions, numericality: { greater_than_or_equal_to: 0 }
  validates :employer_deductions, numericality: { greater_than_or_equal_to: 0 }

  # Only apply deductions on creation - makes deductions immutable after initial calculation
  before_create :apply_deductions
  # Calculate net salary on every save
  before_save :calculate_net_salary

  def self.ransackable_attributes(_auth_object = nil)
    %w[id gross_salary deductions net_salary currency employee_deductions employer_deductions created_at updated_at
       pay_calculation_id worker_id]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[pay_calculation worker]
  end

  # Manually recalculate deductions - only for admin corrections
  # This bypasses the immutability constraint
  def recalculate_deductions!
    # Worker nationality values: 'local', 'foreigner', 'foreigner_no_passport'
    # - local: Has local deductions (EPF, SOCSO, etc.)
    # - foreigner: Has foreigner deductions
    # - foreigner_no_passport: No deductions
    result = PayCalculationServices::DeductionCalculator.calculate(
      pay_calculation.month_year,
      gross_salary: gross_salary || 0,
      nationality: worker.nationality || 'local'
    )

    update_columns(
      employee_deductions: result.employee_deduction,
      employer_deductions: result.employer_deduction,
      deduction_breakdown: result.deduction_breakdown,
      net_salary: (gross_salary || 0) - result.employee_deduction,
      deductions: result.employee_deduction,
      updated_at: Time.current
    )
  end

  private

  def apply_deductions
    # Calculate deductions based on the pay calculation's month
    # This ensures we use the deduction types that were active during that month
    # Worker nationality values: 'local', 'foreigner', 'foreigner_no_passport'
    # - local: Has local deductions (EPF, SOCSO, etc.)
    # - foreigner: Has foreigner deductions
    # - foreigner_no_passport: No deductions
    result = PayCalculationServices::DeductionCalculator.calculate(
      pay_calculation.month_year,
      gross_salary: gross_salary || 0,
      nationality: worker.nationality || 'local'
    )

    self.employee_deductions = result.employee_deduction
    self.employer_deductions = result.employer_deduction
    self.deduction_breakdown = result.deduction_breakdown

    # Calculate net salary immediately after setting deductions
    calculate_net_salary
  end

  def calculate_net_salary
    self.net_salary = (gross_salary || 0) - employee_deductions
    self.deductions = employee_deductions # Legacy compatibility
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
