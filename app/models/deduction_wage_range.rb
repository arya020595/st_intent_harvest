# frozen_string_literal: true

# DeductionWageRange represents salary-based deduction brackets
# Used for deductions that vary by wage level (e.g., SOCSO for local workers)
#
# Example: SOCSO local worker with salary RM 3,500
#   - Finds range: min_wage=3000, max_wage=4000
#   - Returns: employee_amount=24.50, employer_amount=63.00
#
# Supports both fixed amounts and percentage calculations within ranges
class DeductionWageRange < ApplicationRecord
  CALCULATION_METHODS = %w[fixed percentage].freeze

  # Associations
  belongs_to :deduction_type

  # Validations
  validates :min_wage, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :max_wage, numericality: { greater_than_or_equal_to: 0, allow_nil: true }
  validates :employee_amount, numericality: { greater_than_or_equal_to: 0 }
  validates :employer_amount, numericality: { greater_than_or_equal_to: 0 }
  validates :employee_percentage, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 100 }
  validates :employer_percentage, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 100 }
  validates :calculation_method, presence: true, inclusion: { in: CALCULATION_METHODS }

  validate :max_wage_greater_than_or_equal_to_min_wage

  # Scopes
  # Find the wage range that contains the given salary
  # @param salary [BigDecimal] The gross salary to match
  # @return [ActiveRecord::Relation] Matching wage ranges
  scope :for_salary, lambda { |salary|
    where('min_wage <= ?', salary)
      .where('max_wage IS NULL OR max_wage >= ?', salary)
  }

  # Calculate the deduction amount for this wage range
  # Follows Strategy Pattern - calculation method is determined by calculation_method field
  #
  # @param gross_salary [BigDecimal] Worker's gross salary
  # @param field [Symbol] :employee or :employer
  # @return [BigDecimal] Calculated deduction amount
  def calculate_for(gross_salary, field: :employee)
    case calculation_method
    when 'fixed'
      # Fixed amount (e.g., SOCSO local: RM 24.50 for employee)
      field == :employee ? employee_amount : employer_amount
    when 'percentage'
      # Percentage of gross salary (e.g., 1.25% for ranges that use percentage)
      percentage = field == :employee ? employee_percentage : employer_percentage
      (gross_salary * percentage / 100).round(2)
    else
      BigDecimal('0')
    end
  end

  # Human-readable wage range display
  # @return [String] Formatted wage range (e.g., "RM 3,000.00 - RM 4,000.00")
  def wage_range_display
    min = format('RM %.2f', min_wage)
    max = max_wage ? format('RM %.2f', max_wage) : 'and above'
    "#{min} - #{max}"
  end

  private

  def max_wage_greater_than_or_equal_to_min_wage
    return if max_wage.nil? || min_wage.nil?
    return if max_wage >= min_wage

    errors.add(:max_wage, 'must be greater than or equal to min_wage')
  end
end

# == Schema Information
#
# Table name: deduction_wage_ranges
#
#  id                   :bigint           not null, primary key
#  deduction_type_id    :bigint           not null
#  min_wage             :decimal(10, 2)   not null
#  max_wage             :decimal(10, 2)
#  employee_amount      :decimal(10, 2)   default(0.0), not null
#  employer_amount      :decimal(10, 2)   default(0.0), not null
#  employee_percentage  :decimal(5, 2)    default(0.0), not null
#  employer_percentage  :decimal(5, 2)    default(0.0), not null
#  calculation_method   :string           default("fixed"), not null
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#
# Indexes
#
#  index_deduction_wage_ranges_on_deduction_type_id  (deduction_type_id)
#  idx_wage_ranges_salary_lookup  (deduction_type_id,min_wage,max_wage)
#
