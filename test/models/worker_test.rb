# frozen_string_literal: true
# == Schema Information
#
# Table name: workers
#
#  id              :integer          not null, primary key
#  created_at      :datetime         not null
#  gender          :string
#  hired_date      :date
#  identity_number :string
#  is_active       :boolean
#  name            :string
#  nationality     :string
#  updated_at      :datetime         not null
#  worker_type     :string
#  position        :string
#  discarded_at    :datetime
#
# Indexes
#
#  index_workers_on_discarded_at  (discarded_at)
#

require 'test_helper'

class WorkerTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
