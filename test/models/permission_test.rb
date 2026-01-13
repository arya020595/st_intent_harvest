# frozen_string_literal: true

# == Schema Information
#
# Table name: permissions
#
#  id           :integer          not null, primary key
#  code         :string           not null
#  created_at   :datetime         not null
#  name         :string           not null
#  resource     :string           not null
#  section      :string
#  updated_at   :datetime         not null
#  discarded_at :datetime
#
# Indexes
#
#  index_permissions_on_code          (code) UNIQUE
#  index_permissions_on_discarded_at  (discarded_at)
#  index_permissions_on_resource      (resource)
#

require 'test_helper'

class PermissionTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
