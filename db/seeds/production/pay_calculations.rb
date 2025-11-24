# frozen_string_literal: true

# Production Seeds - Pay Calculations
# Create pay calculations with worker details

puts '💵 Creating pay calculations...'

# Fetch active workers once
workers = Worker.where(is_active: true).limit(20).order(:id).to_a

# Create pay calculation for current month (has active deduction types)
pay_calc = PayCalculation.find_or_create_for_month('2025-01')

# Define pay calculation details (only gross_salary, deductions calculated automatically)
pay_calc_details_data = [
  { worker: workers[0], gross_salary: 4500.00 },
  { worker: workers[1], gross_salary: 5200.00 },
  { worker: workers[2], gross_salary: 3800.00 },
  { worker: workers[3], gross_salary: 6100.00 },
  { worker: workers[4], gross_salary: 4800.00 },
  { worker: workers[5], gross_salary: 5500.00 },
  { worker: workers[6], gross_salary: 4200.00 },
  { worker: workers[7], gross_salary: 5800.00 },
  { worker: workers[8], gross_salary: 4600.00 },
  { worker: workers[9], gross_salary: 5300.00 },
  { worker: workers[10], gross_salary: 3900.00 },
  { worker: workers[11], gross_salary: 6500.00 },
  { worker: workers[12], gross_salary: 5000.00 },
  { worker: workers[13], gross_salary: 4400.00 },
  { worker: workers[14], gross_salary: 5700.00 },
  { worker: workers[15], gross_salary: 4900.00 },
  { worker: workers[16], gross_salary: 5400.00 },
  { worker: workers[17], gross_salary: 4300.00 },
  { worker: workers[18], gross_salary: 6000.00 },
  { worker: workers[19], gross_salary: 4700.00 }
]

# Create pay calculation details with proper deduction calculations
# Note: We use create! instead of insert_all to trigger callbacks that calculate deductions
existing_details = PayCalculationDetail.where(pay_calculation: pay_calc).pluck(:worker_id).to_set
new_details = pay_calc_details_data.reject do |data|
  existing_details.include?(data[:worker].id)
end

if new_details.any?
  new_details.each do |data|
    PayCalculationDetail.create!(
      pay_calculation: pay_calc,
      worker: data[:worker],
      gross_salary: data[:gross_salary]
      # deductions, net_salary, and deduction_breakdown will be calculated by callbacks
    )
  end
end

# Recalculate overall totals
pay_calc.recalculate_overall_total!

puts "✓ Created pay calculation with #{PayCalculationDetail.count} worker details"
