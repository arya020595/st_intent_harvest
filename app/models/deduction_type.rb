class DeductionType < ApplicationRecord
  CALCULATION_TYPES = %w[percentage fixed].freeze
  NATIONALITY_TYPES = %w[all local foreigner].freeze

  validates :name, presence: true
  validates :code, presence: true
  validates :is_active, inclusion: { in: [true, false] }
  validates :employee_contribution, numericality: { greater_than_or_equal_to: 0 }
  validates :employer_contribution, numericality: { greater_than_or_equal_to: 0 }
  validates :effective_from, presence: true
  validates :calculation_type, presence: true, inclusion: { in: CALCULATION_TYPES }
  validates :applies_to_nationality, inclusion: { in: NATIONALITY_TYPES }, allow_nil: true

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
  scope :for_nationality, lambda { |nationality|
    where(
      'applies_to_nationality IS NULL OR applies_to_nationality = ? OR applies_to_nationality = ?',
      'all',
      nationality
    )
  }

  # Calculate actual deduction amount based on gross salary
  # @param gross_salary [BigDecimal] The worker's gross salary
  # @param field [Symbol] :employee_contribution or :employer_contribution
  # @return [BigDecimal] The calculated deduction amount
  def calculate_amount(gross_salary, field: :employee_contribution)
    rate = send(field)
    return 0 if rate.nil? || rate.zero?

    case calculation_type
    when 'percentage'
      (gross_salary * rate / 100).round(2)
    when 'fixed'
      rate
    else
      0
    end
  end

  # Ransack configuration
  def self.ransackable_attributes(_auth_object = nil)
    %w[id name code description is_active employee_contribution employer_contribution effective_from effective_until
       calculation_type applies_to_nationality created_at updated_at]
  end

  def self.ransackable_associations(_auth_object = nil)
    []
  end

  private

  def only_one_current_per_code
    return unless effective_until.nil? # Only validate if this is current (no end date)

    existing = DeductionType.where(code: code, effective_until: nil)
                            .where.not(id: id) # Exclude self if updating

    return unless existing.exists?

    errors.add(:code, 'already has an active record with no end date. End the current record first.')
  end
end
