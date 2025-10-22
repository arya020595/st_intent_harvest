class Unit < ApplicationRecord
  has_many :inventories, dependent: :nullify
  has_many :work_order_rates, dependent: :nullify
  
  validates :name, presence: true
end

# == Schema Information
#
# Table name: units
#
#  id         :bigint           not null, primary key
#  name       :string
#  unit_type  :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
