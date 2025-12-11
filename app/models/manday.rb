class Manday < ApplicationRecord
  has_many :mandays_workers, dependent: :destroy
  accepts_nested_attributes_for :mandays_workers, allow_destroy: true

  # Ransacker for searching by month string
  ransacker :work_month_str do |parent|
    Arel::Nodes::NamedFunction.new(
      'to_char',
      [parent.table[:work_month], Arel::Nodes.build_quoted('Month YYYY')]
    )
  end

  # --- Validations ---
  validates :work_month, presence: { message: "Month - Year cannot be blank" }
  validate :unique_month
  validate :at_least_one_worker_has_days

  def self.ransackable_attributes(auth_object = nil)
    %w[id work_month created_at updated_at work_month_str]
  end

  private

  # Prevent duplicate months
  def unique_month
    return unless work_month.present?

    existing = Manday.where(
      "EXTRACT(MONTH FROM work_month) = ? AND EXTRACT(YEAR FROM work_month) = ?",
      work_month.month, work_month.year
    )
    existing = existing.where.not(id: id) if persisted?
    if existing.exists?
      errors.add(:work_month, "for #{work_month.strftime('%B %Y')} already exists. Please edit it instead.")
    end
  end

  # Ensure at least one worker has days > 0
  def at_least_one_worker_has_days
    valid_workers = mandays_workers.reject { |w| w._destroy || w.days.to_i <= 0 }
    if valid_workers.empty?
      errors.add(:base, "At least one worker must have days greater than 0")
    end
  end
end
