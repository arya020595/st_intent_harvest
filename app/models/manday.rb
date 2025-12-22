# frozen_string_literal: true

class Manday < ApplicationRecord
  has_many :mandays_workers, dependent: :destroy
  accepts_nested_attributes_for :mandays_workers,
                                allow_destroy: true,
                                reject_if: proc { |attrs| attrs['days'].blank? || attrs['days'].to_i <= 0 }

  # Ransacker for searching by month string
  ransacker :work_month_str do |parent|
    Arel::Nodes::NamedFunction.new(
      'to_char',
      [parent.table[:work_month], Arel::Nodes.build_quoted('Month YYYY')]
    )
  end

  # --- Validations ---
  validates :work_month, presence: { message: 'Month - Year cannot be blank' },
                         uniqueness: {
                           message: lambda { |object, _data|
                             "for #{object.work_month&.strftime('%B %Y')} already exists. Please edit it instead."
                           }
                         }
  validate :at_least_one_worker_with_days?

  def self.ransackable_attributes(_auth_object = nil)
    %w[id work_month created_at updated_at work_month_str]
  end

  private

  # Ensure at least one worker has days > 0
  # Only validates workers that aren't marked for destruction
  def at_least_one_worker_with_days?
    valid_workers = mandays_workers.reject(&:marked_for_destruction?)
                                   .any? { |worker| worker.days.to_i.positive? }

    errors.add(:base, 'At least one worker must have days greater than 0') unless valid_workers
  end
end

# == Schema Information
#
# Table name: mandays
#
#  id           :integer          not null, primary key
#  work_month   :date             not null
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  discarded_at :datetime
#
# Indexes
#
#  index_mandays_on_discarded_at  (discarded_at)
#  index_mandays_on_work_month    (work_month) UNIQUE
#
