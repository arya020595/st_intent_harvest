# frozen_string_literal: true
# == Schema Information
#
# Table name: roles
#
#  id           :integer          not null, primary key
#  created_at   :datetime         not null
#  description  :text
#  name         :string
#  updated_at   :datetime         not null
#  discarded_at :datetime
#
# Indexes
#
#  index_roles_on_discarded_at  (discarded_at)
#

require 'test_helper'

class RoleTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
