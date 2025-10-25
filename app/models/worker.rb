class Worker < ApplicationRecord
  has_many :work_order_workers, dependent: :destroy
  has_many :work_orders, through: :work_order_workers
  has_many :pay_calculation_details, dependent: :destroy
  has_many :pay_calculations, through: :pay_calculation_details
  
  validates :name, presence: true
  validates :worker_type, presence: true
  validates :gender, inclusion: { in: %w[Male Female], allow_nil: true }
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
