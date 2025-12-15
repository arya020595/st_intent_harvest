# frozen_string_literal: true

require 'test_helper'

module DeductionCalculators
  class FactoryTest < ActiveSupport::TestCase
    # ============================================================================
    # FACTORY CREATION TESTS
    # ============================================================================

    test 'should create PercentageCalculator for percentage type' do
      deduction_type = deduction_types(:epf_foreign)
      calculator = Factory.for(deduction_type)

      assert_instance_of PercentageCalculator, calculator
      assert_equal deduction_type, calculator.deduction_type
    end

    test 'should create FixedCalculator for fixed type' do
      deduction_type = DeductionType.create!(
        name: 'Fixed Test',
        code: 'FIXED_TEST',
        calculation_type: 'fixed',
        employee_contribution: 10.00,
        employer_contribution: 10.00,
        is_active: true,
        effective_from: Date.new(2025, 1, 1)
      )
      calculator = Factory.for(deduction_type)

      assert_instance_of FixedCalculator, calculator
      assert_equal deduction_type, calculator.deduction_type
    end

    test 'should create WageRangeCalculator for wage_range type' do
      deduction_type = deduction_types(:socso)
      calculator = Factory.for(deduction_type)

      assert_instance_of WageRangeCalculator, calculator
      assert_equal deduction_type, calculator.deduction_type
    end

    # ============================================================================
    # ERROR HANDLING TESTS
    # ============================================================================

    test 'should raise ArgumentError for unknown calculation type' do
      deduction_type = DeductionType.new(
        name: 'Invalid',
        code: 'INVALID',
        calculation_type: 'unknown_type'
      )

      error = assert_raises(ArgumentError) do
        Factory.for(deduction_type)
      end

      assert_match(/Unknown calculation type: unknown_type/, error.message)
      assert_match(/Valid types: percentage, fixed, wage_range/, error.message)
    end

    test 'should raise error with helpful message listing valid types' do
      deduction_type = DeductionType.new(
        name: 'Invalid',
        code: 'INVALID',
        calculation_type: 'tiered'
      )

      error = assert_raises(ArgumentError) do
        Factory.for(deduction_type)
      end

      assert_includes error.message, 'percentage'
      assert_includes error.message, 'fixed'
      assert_includes error.message, 'wage_range'
    end

    # ============================================================================
    # HELPER METHOD TESTS
    # ============================================================================

    test 'supports? should return true for valid calculation types' do
      assert Factory.supports?('percentage')
      assert Factory.supports?('fixed')
      assert Factory.supports?('wage_range')
    end

    test 'supports? should return false for invalid calculation types' do
      assert_not Factory.supports?('unknown')
      assert_not Factory.supports?('tiered')
      assert_not Factory.supports?('custom')
    end

    test 'supports? should be case-sensitive' do
      assert_not Factory.supports?('Percentage')
      assert_not Factory.supports?('FIXED')
      assert_not Factory.supports?('Wage_Range')
    end

    test 'supported_types should return all valid calculation types' do
      types = Factory.supported_types

      assert_includes types, 'percentage'
      assert_includes types, 'fixed'
      assert_includes types, 'wage_range'
      assert_equal 3, types.size
    end

    # ============================================================================
    # INTEGRATION TESTS
    # ============================================================================

    test 'factory should create calculator that can perform calculations' do
      deduction_type = deduction_types(:epf_foreign)
      calculator = Factory.for(deduction_type)

      result = calculator.calculate(3500, field: :employee_contribution)
      assert_equal BigDecimal('385.00'), result
    end

    test 'factory should handle all calculation types in real scenario' do
      # Percentage (EPF)
      epf = deduction_types(:epf_foreign)
      epf_calculator = Factory.for(epf)
      assert_instance_of PercentageCalculator, epf_calculator
      assert_equal BigDecimal('385.00'), epf_calculator.calculate(3500, field: :employee_contribution)

      # Fixed
      eis = DeductionType.create!(
        name: 'EIS',
        code: 'EIS',
        calculation_type: 'fixed',
        employee_contribution: 7.90,
        employer_contribution: 7.90,
        is_active: true,
        effective_from: Date.new(2025, 1, 1)
      )
      eis_calculator = Factory.for(eis)
      assert_instance_of FixedCalculator, eis_calculator
      assert_equal BigDecimal('7.90'), eis_calculator.calculate(3500, field: :employee_contribution)

      # Wage Range
      socso_local = deduction_types(:socso)
      # Clear existing ranges first
      DeductionWageRange.where(deduction_type: socso_local).delete_all
      DeductionWageRange.create!(
        deduction_type: socso_local,
        min_wage: 3400.01,
        max_wage: 3500.00,
        employee_amount: 17.75,
        employer_amount: 62.15,
        calculation_method: 'fixed'
      )
      socso_calculator = Factory.for(socso_local)
      assert_instance_of WageRangeCalculator, socso_calculator
      assert_equal BigDecimal('17.75'), socso_calculator.calculate(3500, field: :employee_contribution)
    end

    # ============================================================================
    # EXTENSIBILITY TESTS
    # ============================================================================

    test 'CALCULATORS constant should be frozen' do
      assert Factory::CALCULATORS.frozen?
    end

    test 'CALCULATORS should map string keys to calculator classes' do
      assert_equal PercentageCalculator, Factory::CALCULATORS['percentage']
      assert_equal FixedCalculator, Factory::CALCULATORS['fixed']
      assert_equal WageRangeCalculator, Factory::CALCULATORS['wage_range']
    end

    test 'supported_types should match CALCULATORS keys' do
      assert_equal Factory::CALCULATORS.keys.sort, Factory.supported_types.sort
    end

    # ============================================================================
    # OPEN/CLOSED PRINCIPLE TESTS
    # ============================================================================

    test 'factory should create different calculator instances for different deduction types' do
      epf1 = deduction_types(:epf_foreign)
      epf2 = deduction_types(:sip)

      calculator1 = Factory.for(epf1)
      calculator2 = Factory.for(epf2)

      assert_not_equal calculator1.object_id, calculator2.object_id
      assert_instance_of PercentageCalculator, calculator1
      assert_instance_of PercentageCalculator, calculator2
    end

    test 'factory should return new instance each time' do
      deduction_type = deduction_types(:epf_foreign)

      calculator1 = Factory.for(deduction_type)
      calculator2 = Factory.for(deduction_type)

      assert_not_equal calculator1.object_id, calculator2.object_id
    end
  end
end
