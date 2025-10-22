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
#  id              :bigint           not null, primary key
#  gender          :string
#  hired_date      :date
#  identity_number :string
#  is_active       :boolean
#  name            :string
#  nationality     :string
#  worker_type     :string
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#
