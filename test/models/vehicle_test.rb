# frozen_string_literal: true

# == Schema Information
#
# Table name: vehicles
#
#  id             :integer          not null, primary key
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  vehicle_model  :string
#  vehicle_number :string
#  discarded_at   :datetime
#
# Indexes
#
#  index_vehicles_on_discarded_at  (discarded_at)
#

require 'test_helper'

class VehicleTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
