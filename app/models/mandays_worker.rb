class MandaysWorker < ApplicationRecord
  belongs_to :manday

  validates :worker_name, presence: true
end

# == Schema Information
#
# Table name: mandays_workers
#
#  id          :integer          not null, primary key
#  worker_name :string
#  days        :integer
#  remarks     :text
#  manday_id   :integer          not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
# Indexes
#
#  index_mandays_workers_on_manday_id  (manday_id)
#
