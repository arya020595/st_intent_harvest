# frozen_string_literal: true

# Deduction Types Seed Data
# Based on Malaysian standard deductions (EPF, SOCSO, SIP)
# All amounts are stored as percentages (11.0 = 11%)

puts 'Seeding Deduction Types...'

# Set effective_from to beginning of current year (or company start date)
# This ensures deductions work for all months in the current year
effective_start_date = Date.new(Date.current.year, 1, 1)

# Clean up existing deductions to start fresh
DeductionType.delete_all

# EPF (Employees Provident Fund) - Percentage based
# Different for Local vs Foreign employees
DeductionType.create!([
                        {
                          code: 'EPF',
                          name: 'EPF (Employees Provident Fund) - Malaysian',
                          description: 'Malaysian employees: Employee 11% | Employer 13% (retirement savings)',
                          employee_contribution: 11.0, # 11%
                          employer_contribution: 13.0, # 13%
                          calculation_type: 'percentage',
                          applies_to_nationality: 'local',
                          is_active: true,
                          effective_from: effective_start_date,
                          effective_until: nil
                        }
                      ])

DeductionType.create!([
                        {
                          code: 'EPF',
                          name: 'EPF (Employees Provident Fund) - Foreign',
                          description: 'Foreign employees: Employee 2% | Employer 2% (retirement savings)',
                          employee_contribution: 2.0, # 2%
                          employer_contribution: 2.0, # 2%
                          calculation_type: 'percentage',
                          applies_to_nationality: 'foreigner',
                          is_active: true,
                          effective_from: effective_start_date,
                          effective_until: nil
                        }
                      ])

# SOCSO (Social Security Organization) - Different for Local vs Foreign
# Local Employees
DeductionType.create!([
                        {
                          code: 'SOCSO_MALAYSIAN',
                          name: 'SOCSO (Malaysian)',
                          description: 'Social Security Organization for Malaysian employees (0.5% employee, 1.75% employer)',
                          employee_contribution: 0.5, # 0.5%
                          employer_contribution: 1.75, # 1.75%
                          calculation_type: 'percentage',
                          applies_to_nationality: 'local',
                          is_active: true,
                          effective_from: effective_start_date,
                          effective_until: nil
                        }
                      ])

# Foreign Employees (employee doesn't contribute, only employer)
DeductionType.create!([
                        {
                          code: 'SOCSO_FOREIGN',
                          name: 'SOCSO (Foreign)',
                          description: 'Social Security Organization for Foreign employees (0% employee, 1.25% employer)',
                          employee_contribution: 0.0, # 0% (employee doesn't contribute)
                          employer_contribution: 1.25, # 1.25%
                          calculation_type: 'percentage',
                          applies_to_nationality: 'foreigner',
                          is_active: true,
                          effective_from: effective_start_date,
                          effective_until: nil
                        }
                      ])

# SIP/EIS (Employment Insurance System) - Only for Local employees
DeductionType.create!([
                        {
                          code: 'SIP',
                          name: 'SIP (Employment Insurance)',
                          description: 'Employment Insurance System - Only for Malaysian employees (0.2% employee, 0.2% employer)',
                          employee_contribution: 0.2, # 0.2%
                          employer_contribution: 0.2, # 0.2%
                          calculation_type: 'percentage',
                          applies_to_nationality: 'local',
                          is_active: true,
                          effective_from: effective_start_date,
                          effective_until: nil
                        }
                      ])

puts "Created #{DeductionType.count} deduction types"
puts "\nDeduction Breakdown:"
DeductionType.order(:code).each do |dt|
  puts "\n#{dt.code} - #{dt.name}"
  puts "  Employee: #{dt.employee_contribution}% | Employer: #{dt.employer_contribution}%"
  puts "  Applies to: #{dt.applies_to_nationality}"
  puts "  Calculation: #{dt.calculation_type}"
  puts "  Effective: #{dt.effective_from} to #{dt.effective_until || 'present'}"
end

puts "\n✓ Deduction types seeded successfully!"
