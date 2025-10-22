# == Schema Information
#
# Table name: workers
#
#  id              :bigint           not null, primary key
#  gender          :string
#  hired_date      :date
#  identity_number :string
#  is_active       :boolean
#  name            :string
#  nationality     :string
#  worker_type     :string
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#
require "test_helper"

class WorkerTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
