# frozen_string_literal: true

# Production Seeds - Pay Calculations
# Create pay calculations with worker details

puts '💵 Creating pay calculations...'

# Fetch active workers once
workers = Worker.where(is_active: true).limit(20).order(:id).to_a

# Create pay calculation for November 2024
pay_calc = PayCalculation.find_or_create_for_month('2024-11')

# Define pay calculation details
pay_calc_details_data = [
  { worker: workers[0], gross_salary: 4500.00, deductions: 450.00 },
  { worker: workers[1], gross_salary: 5200.00, deductions: 520.00 },
  { worker: workers[2], gross_salary: 3800.00, deductions: 380.00 },
  { worker: workers[3], gross_salary: 6100.00, deductions: 610.00 },
  { worker: workers[4], gross_salary: 4800.00, deductions: 480.00 },
  { worker: workers[5], gross_salary: 5500.00, deductions: 550.00 },
  { worker: workers[6], gross_salary: 4200.00, deductions: 420.00 },
  { worker: workers[7], gross_salary: 5800.00, deductions: 580.00 },
  { worker: workers[8], gross_salary: 4600.00, deductions: 460.00 },
  { worker: workers[9], gross_salary: 5300.00, deductions: 530.00 },
  { worker: workers[10], gross_salary: 3900.00, deductions: 390.00 },
  { worker: workers[11], gross_salary: 6500.00, deductions: 650.00 },
  { worker: workers[12], gross_salary: 5000.00, deductions: 500.00 },
  { worker: workers[13], gross_salary: 4400.00, deductions: 440.00 },
  { worker: workers[14], gross_salary: 5700.00, deductions: 570.00 },
  { worker: workers[15], gross_salary: 4900.00, deductions: 490.00 },
  { worker: workers[16], gross_salary: 5400.00, deductions: 540.00 },
  { worker: workers[17], gross_salary: 4300.00, deductions: 430.00 },
  { worker: workers[18], gross_salary: 6000.00, deductions: 600.00 },
  { worker: workers[19], gross_salary: 4700.00, deductions: 470.00 }
]

# Batch insert pay calculation details
existing_details = PayCalculationDetail.where(pay_calculation: pay_calc).pluck(:worker_id).to_set
new_details = pay_calc_details_data.reject do |data|
  existing_details.include?(data[:worker].id)
end

if new_details.any?
  details_insert_data = new_details.map do |data|
    {
      pay_calculation_id: pay_calc.id,
      worker_id: data[:worker].id,
      gross_salary: data[:gross_salary],
      deductions: data[:deductions],
      net_salary: data[:gross_salary] - data[:deductions],
      created_at: Time.current,
      updated_at: Time.current
    }
  end
  PayCalculationDetail.insert_all(details_insert_data)
end

# Recalculate overall totals
pay_calc.recalculate_overall_total!

puts "✓ Created pay calculation with #{PayCalculationDetail.count} worker details"
