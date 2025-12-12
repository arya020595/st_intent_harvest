# frozen_string_literal: true

class MandaysWorker < ApplicationRecord
  belongs_to :manday
  belongs_to :worker

  validates :worker_id, uniqueness: { scope: :manday_id, message: 'already added to this month' }

  delegate :name, to: :worker, prefix: true, allow_nil: true
end

# == Schema Information
#
# Table name: mandays_workers
#
#  id         :integer          not null, primary key
#  worker_id  :integer          not null
#  manday_id  :integer          not null
#  days       :integer
#  remarks    :text
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_mandays_workers_on_manday_id                (manday_id)
#  index_mandays_workers_on_manday_id_and_worker_id  (manday_id,worker_id) UNIQUE
#  index_mandays_workers_on_worker_id                (worker_id)
#
