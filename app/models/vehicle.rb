class Vehicle < ApplicationRecord
  validates :vehicle_number, presence: true, uniqueness: true
end
