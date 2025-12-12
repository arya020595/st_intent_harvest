# frozen_string_literal: true

module DeductionCalculators
  # Factory for creating appropriate deduction calculator
  # Implements Factory Pattern to encapsulate calculator selection logic
  #
  # SOLID Benefits:
  # - Open/Closed: Add new calculator types without modifying this factory
  # - Dependency Inversion: Clients depend on factory, not concrete calculators
  # - Single Responsibility: Only responsible for calculator creation
  #
  # Usage:
  #   calculator = DeductionCalculators::Factory.for(deduction_type)
  #   amount = calculator.calculate(gross_salary, field: :employee_contribution)
  class Factory
    # Map calculation types to calculator classes
    CALCULATORS = {
      'percentage' => PercentageCalculator,
      'fixed' => FixedCalculator,
      'wage_range' => WageRangeCalculator
    }.freeze

    class << self
      # Create appropriate calculator for the given deduction type
      # @param deduction_type [DeductionType] The deduction configuration
      # @return [Base] Concrete calculator instance
      # @raise [ArgumentError] If calculation_type is unknown
      def for(deduction_type)
        calculator_class = CALCULATORS[deduction_type.calculation_type]

        unless calculator_class
          raise ArgumentError,
                "Unknown calculation type: #{deduction_type.calculation_type}. " \
                "Valid types: #{CALCULATORS.keys.join(', ')}"
        end

        calculator_class.new(deduction_type)
      end

      # Check if a calculation type is supported
      # @param calculation_type [String] The calculation type to check
      # @return [Boolean] True if supported
      def supports?(calculation_type)
        CALCULATORS.key?(calculation_type)
      end

      # Get all supported calculation types
      # @return [Array<String>] List of supported types
      def supported_types
        CALCULATORS.keys
      end
    end
  end
end
