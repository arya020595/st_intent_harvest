# frozen_string_literal: true

class Vehicle < ApplicationRecord
  validates :vehicle_number, presence: true, uniqueness: true

  # Ransack configuration
  def self.ransackable_attributes(_auth_object = nil)
    %w[id vehicle_number vehicle_model created_at updated_at]
  end
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
