class PayCalculation < ApplicationRecord
  has_many :pay_calculation_details, dependent: :destroy
  has_many :workers, through: :pay_calculation_details
  
  validates :month_year, presence: true
end

# == Schema Information
#
# Table name: pay_calculations
#
#  id            :bigint           not null, primary key
#  month_year    :string           not null
#  overall_total :decimal(10, 2)
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#
