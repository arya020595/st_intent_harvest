class Vehicle < ApplicationRecord
  validates :vehicle_number, presence: true, uniqueness: true
end

# == Schema Information
#
# Table name: vehicles
#
#  id             :integer          not null, primary key
#  vehicle_number :string
#  vehicle_model  :string
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#
