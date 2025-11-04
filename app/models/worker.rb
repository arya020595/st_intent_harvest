class Worker < ApplicationRecord
  has_many :work_order_workers, dependent: :destroy
  has_many :work_orders, through: :work_order_workers
  has_many :pay_calculation_details, dependent: :destroy
  has_many :pay_calculations, through: :pay_calculation_details

  validates :name, presence: true
  validates :worker_type, presence: true
  validates :gender, inclusion: { in: %w[Male Female], allow_nil: true }

  # Ransack configuration
  def self.ransackable_attributes(_auth_object = nil)
    %w[id name worker_type gender is_active hired_date nationality identity_number created_at updated_at]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[work_order_workers work_orders pay_calculation_details pay_calculations]
  end
end

# == Schema Information
#
# Table name: workers
#
#  id              :integer          not null, primary key
#  name            :string
#  worker_type     :string
#  gender          :string
#  is_active       :boolean
#  hired_date      :date
#  nationality     :string
#  identity_number :string
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#
