# frozen_string_literal: true

# Deduction Types Seed Data
# Based on Malaysian standard deductions (EPF, SOCSO, SIP)

puts 'Seeding Deduction Types...'

# EPF (Employees Provident Fund)
# Note: Actual EPF rates are percentage-based and vary by salary bracket
# These are placeholder values - adjust to your actual requirements
DeductionType.find_or_create_by!(code: 'EPF') do |d|
  d.name = 'EPF'
  d.description = 'Employees Provident Fund - retirement savings'
  d.worker_amount = 0.00 # Set based on salary (typically 11% of salary)
  d.employee_amount = 0.00 # Set based on salary (typically 12-13% of salary)
  d.is_active = false # Disabled by default, enable when rates are configured
end

# SOCSO (Social Security Organization)
DeductionType.find_or_create_by!(code: 'SOCSO') do |d|
  d.name = 'SOCSO'
  d.description = 'Social Security Organization - social protection'
  d.worker_amount = 21.25 # Example fixed amount from payslip
  d.employee_amount = 74.35 # Example fixed amount from payslip
  d.is_active = true
end

# SIP (Skim Insurans Pekerjaan / Employment Insurance System)
DeductionType.find_or_create_by!(code: 'SIP') do |d|
  d.name = 'SIP'
  d.description = 'Employment Insurance System'
  d.worker_amount = 0.00 # Set based on requirements
  d.employee_amount = 0.00 # Set based on requirements
  d.is_active = false # Disabled by default
end

puts "Created/Updated #{DeductionType.count} deduction types"
puts "Active deductions: #{DeductionType.active.pluck(:name).join(', ')}"
