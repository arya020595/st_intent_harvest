# frozen_string_literal: true

module PayCalculationServices
  class DeductionCalculator
    DeductionResult = Struct.new(:deduction_breakdown, :worker_deduction, :employee_deduction, keyword_init: true)

    def self.calculate
      deduction_types = DeductionType.active
      breakdown = {}
      worker_total = 0
      employee_total = 0

      deduction_types.each do |deduction_type|
        worker_amt = deduction_type.worker_amount.to_f
        employee_amt = deduction_type.employee_amount.to_f

        breakdown[deduction_type.code] = build_deduction_entry(deduction_type, worker_amt, employee_amt)

        worker_total += worker_amt
        employee_total += employee_amt
      end

      DeductionResult.new(
        deduction_breakdown: breakdown,
        worker_deduction: worker_total,
        employee_deduction: employee_total
      )
    end

    def self.build_deduction_entry(deduction_type, worker_amt, employee_amt)
      {
        'name' => deduction_type.name,
        'worker' => worker_amt,
        'employee' => employee_amt
      }
    end

    private_class_method :build_deduction_entry
  end
end
