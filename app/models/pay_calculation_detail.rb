class PayCalculationDetail < ApplicationRecord
  belongs_to :pay_calculation
  belongs_to :worker

  validates :gross_salary, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :deductions, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :net_salary, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true

  # Ransack configuration
  def self.ransackable_attributes(_auth_object = nil)
    %w[id gross_salary deductions net_salary currency created_at updated_at pay_calculation_id worker_id]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[pay_calculation worker]
  end
end

# == Schema Information
#
# Table name: pay_calculation_details
#
#  id                 :bigint           not null, primary key
#  currency           :string           default("RM")
#  deductions         :decimal(10, 2)
#  gross_salary       :decimal(10, 2)
#  net_salary         :decimal(10, 2)
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  pay_calculation_id :bigint           not null
#  worker_id          :bigint           not null
#
# Indexes
#
#  index_pay_calculation_details_on_pay_calculation_id  (pay_calculation_id)
#  index_pay_calculation_details_on_worker_id           (worker_id)
#
# Foreign Keys
#
#  fk_rails_...  (pay_calculation_id => pay_calculations.id)
#  fk_rails_...  (worker_id => workers.id)
#
