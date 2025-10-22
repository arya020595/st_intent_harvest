class Vehicle < ApplicationRecord
  validates :vehicle_number, presence: true, uniqueness: true
end

# == Schema Information
#
# Table name: vehicles
#
#  id             :bigint           not null, primary key
#  vehicle_model  :string
#  vehicle_number :string
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#
