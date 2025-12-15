# frozen_string_literal: true

module DeductionCalculators
  # Base class for deduction calculation strategies
  # Follows Strategy Pattern - each concrete calculator implements a specific calculation algorithm
  #
  # SOLID Principles Applied:
  # - Single Responsibility: Each calculator handles ONE calculation method
  # - Open/Closed: Add new calculators without modifying existing code
  # - Liskov Substitution: All calculators are interchangeable through common interface
  # - Interface Segregation: Simple, focused interface (calculate method)
  # - Dependency Inversion: DeductionType depends on abstraction, not concrete calculators
  #
  # Usage:
  #   calculator = DeductionCalculators::PercentageCalculator.new(deduction_type)
  #   amount = calculator.calculate(gross_salary, field: :employee_contribution)
  class Base
    attr_reader :deduction_type

    # @param deduction_type [DeductionType] The deduction type configuration
    def initialize(deduction_type)
      @deduction_type = deduction_type
    end

    # Calculate deduction amount - must be implemented by subclasses
    # @param gross_salary [BigDecimal] Worker's gross salary
    # @param field [Symbol] :employee_contribution or :employer_contribution
    # @return [BigDecimal] Calculated deduction amount
    # @raise [NotImplementedError] If subclass doesn't implement this method
    def calculate(gross_salary, field: :employee_contribution)
      raise NotImplementedError, "#{self.class} must implement #calculate"
    end

    protected

    # Helper: Get the contribution rate for specified field
    # @param field [Symbol] :employee_contribution or :employer_contribution
    # @return [BigDecimal, nil] The contribution rate
    def contribution_rate(field)
      deduction_type.send(field)
    end

    # Helper: Check if contribution rate is valid for calculation
    # @param rate [BigDecimal, nil] The rate to check
    # @return [Boolean] True if rate is present and non-zero
    def valid_rate?(rate)
      rate.present? && !rate.zero?
    end
  end
end
