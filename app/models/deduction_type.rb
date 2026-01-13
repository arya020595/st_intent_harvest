# frozen_string_literal: true

class DeductionType < ApplicationRecord
  CALCULATION_TYPES = %w[percentage fixed wage_range].freeze
  NATIONALITY_TYPES = %w[all local foreigner foreigner_no_passport].freeze
  ROUNDING_METHODS = %w[round ceil floor].freeze

  # Associations
  has_many :deduction_wage_ranges, dependent: :destroy

  validates :name, presence: true
  validates :code, presence: true
  validates :is_active, inclusion: { in: [true, false] }
  validates :employee_contribution, numericality: { greater_than_or_equal_to: 0, allow_nil: true }
  validates :employer_contribution, numericality: { greater_than_or_equal_to: 0, allow_nil: true }
  validates :effective_from, presence: true
  validates :calculation_type, presence: true, inclusion: { in: CALCULATION_TYPES }
  validates :applies_to_nationality, inclusion: { in: NATIONALITY_TYPES }, allow_nil: true
  # Allow up to 4 decimal places for rounding precision.
  # 2 is the standard for most currencies, but 3–4 decimals are supported for
  # specific deduction use cases (e.g. statutory rules, prorated or percentage
  # calculations) where higher precision is required before final rounding.
  validates :rounding_precision,
            numericality: { only_integer: true, greater_than_or_equal_to: 0, less_than_or_equal_to: 4 }
  # Rounding method: 'round' (standard), 'ceil' (always up), 'floor' (always down)
  validates :rounding_method, inclusion: { in: ROUNDING_METHODS }

  # Custom validation: Only one active record per code with no end date
  validate :only_one_current_per_code

  scope :active, -> { where(is_active: true) }

  # Returns deduction types that were active on a specific date
  # A deduction type is active on a date if:
  # - effective_from <= date AND (effective_until IS NULL OR effective_until >= date)
  scope :active_on, lambda { |date|
    where(is_active: true)
      .where('effective_from <= ?', date)
      .where('effective_until IS NULL OR effective_until >= ?', date)
  }

  # Filter by nationality
  # Special handling: foreigner_no_passport workers get NO deductions
  # 'all' means local + foreigner (with passport), NOT foreigner_no_passport
  scope :for_nationality, lambda { |nationality|
    if nationality == 'foreigner_no_passport'
      # No deductions for workers without passport
      none
    else
      where(
        'applies_to_nationality IS NULL OR applies_to_nationality = ? OR applies_to_nationality = ?',
        'all',
        nationality
      )
    end
  }

  # Calculate actual deduction amount based on gross salary
  # Delegates to appropriate calculator strategy (Strategy Pattern)
  #
  # @param gross_salary [BigDecimal] The worker's gross salary
  # @param field [Symbol] :employee_contribution or :employer_contribution
  # @return [BigDecimal] The calculated deduction amount
  def calculate_amount(gross_salary, field: :employee_contribution)
    calculator.calculate(gross_salary, field: field)
  end

  # Ransack configuration
  def self.ransackable_attributes(_auth_object = nil)
    %w[id name code description is_active employee_contribution employer_contribution effective_from effective_until
       calculation_type applies_to_nationality rounding_precision rounding_method created_at updated_at]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[deduction_wage_ranges]
  end

  private

  # Factory method - creates appropriate calculator strategy
  # Memoized to avoid recreating calculator on each call
  # @return [DeductionCalculators::Base] Calculator instance
  def calculator
    @calculator ||= DeductionCalculators::Factory.for(self)
  end

  def only_one_current_per_code
    return unless effective_until.nil? # Only validate if this is current (no end date)

    existing = DeductionType.where(code: code, effective_until: nil)
                            .where.not(id: id) # Exclude self if updating

    return unless existing.exists?

    errors.add(:code, 'already has an active record with no end date. End the current record first.')
  end
end

# == Schema Information
#
# Table name: deduction_types
#
#  id                     :integer , not null, primary key
#  applies_to_nationality :string  , comment: "Nationality filter: all, malaysian, foreign"
#  calculation_type       :string  , default("percentage"), not null, comment: "Type of calculation: percentage (multiply by gross_salary) or fixed (use amount as-is)"
#  code                   :string  , not null
#  created_at             :datetime, not null
#  description            :text
#  effective_from         :date
#  effective_until        :date
#  employee_contribution  :decimal , precision: 10, scale: 2, default(0.0), not null, comment: "Employee's contribution rate (percentage) or fixed amount (RM)"
#  employer_contribution  :decimal , precision: 10, scale: 2, default(0.0), not null, comment: "Employer's contribution rate (percentage) or fixed amount (RM)"
#  is_active              :boolean , default(true), not null
#  name                   :string  , not null
#  updated_at             :datetime, not null
#
# Indexes
#
#  index_deduction_types_on_applies_to_nationality    (applies_to_nationality)
#  index_deduction_types_on_calculation_type          (calculation_type)
#  index_deduction_types_on_code                      (code)
#  index_deduction_types_on_code_and_effective_until  (code, effective_until)
#  index_deduction_types_on_effective_from            (effective_from)
#  index_deduction_types_on_effective_until           (effective_until)
#  index_deduction_types_on_is_active                 (is_active)
#
