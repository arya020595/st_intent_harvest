class Block < ApplicationRecord
  has_many :work_orders, dependent: :nullify
  
  validates :block_number, presence: true, uniqueness: true
  validates :hectarage, numericality: { greater_than: 0 }, allow_nil: true
end

# == Schema Information
#
# Table name: blocks
#
#  id           :bigint           not null, primary key
#  block_number :string
#  hectarage    :decimal(, )
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#
