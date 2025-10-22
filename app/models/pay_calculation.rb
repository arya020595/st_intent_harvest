class PayCalculation < ApplicationRecord
  has_many :pay_calculation_details, dependent: :destroy
  has_many :workers, through: :pay_calculation_details
  
  validates :month_year, presence: true
end
