# frozen_string_literal: true

# == Schema Information
#
# Table name: blocks
#
#  id           :integer          not null, primary key
#  block_number :string
#  created_at   :datetime         not null
#  hectarage    :decimal(10, 2)
#  updated_at   :datetime         not null
#  discarded_at :datetime
#
# Indexes
#
#  index_blocks_on_discarded_at  (discarded_at)
#

require 'test_helper'

class BlockTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
