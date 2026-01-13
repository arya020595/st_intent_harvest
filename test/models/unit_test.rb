# frozen_string_literal: true

# == Schema Information
#
# Table name: units
#
#  id           :integer          not null, primary key
#  created_at   :datetime         not null
#  name         :string
#  unit_type    :string
#  updated_at   :datetime         not null
#  discarded_at :datetime
#
# Indexes
#
#  index_units_on_discarded_at  (discarded_at)
#

require 'test_helper'

class UnitTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
