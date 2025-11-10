class PayCalculation < ApplicationRecord
  has_many :pay_calculation_details, dependent: :destroy
  has_many :workers, through: :pay_calculation_details

  validates :month_year, presence: true

  # Ransack configuration
  def self.ransackable_attributes(_auth_object = nil)
    %w[
      id
      month_year
      overall_total
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
#  id            :integer          not null, primary key
#  month_year    :string           not null
#  overall_total :decimal(10, 2)
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#
