# == Schema Information
#
# Table name: blocks
#
#  id           :integer          not null, primary key
#  block_number :string
#  hectarage    :decimal(10, 2)
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#

require "test_helper"

class BlockTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
