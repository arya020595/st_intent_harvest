# frozen_string_literal: true

class PayCalculation < ApplicationRecord
  has_many :pay_calculation_details, dependent: :destroy
  has_many :workers, through: :pay_calculation_details

  validates :month_year, presence: true

  # Class method to find or create pay calculation by month_year
  def self.find_or_create_for_month(month_year)
    find_or_create_by!(month_year: month_year) do |pc|
      pc.total_gross_salary = 0
      pc.total_deductions = 0
      pc.total_net_salary = 0
    end
  end

  # Recalculate all totals from pay calculation details
  def recalculate_overall_total!
    update!(
      total_gross_salary: pay_calculation_details.sum(:gross_salary),
      total_deductions: pay_calculation_details.sum(:worker_deductions),
      total_net_salary: pay_calculation_details.sum(:net_salary)
    )
  end

  # Ransack configuration
  def self.ransackable_attributes(_auth_object = nil)
    %w[
      id
      month_year
      total_gross_salary
      total_deductions
      total_net_salary
      created_at
      updated_at
    ]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[pay_calculation_details workers]
  end
end

# == Schema Information
#
# Table name: pay_calculations
#
#  id                  :integer          not null, primary key
#  month_year          :string           not null
#  total_gross_salary  :decimal(10, 2)   default(0), not null
#  total_deductions    :decimal(10, 2)   default(0), not null
#  total_net_salary    :decimal(10, 2)   default(0), not null
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#
