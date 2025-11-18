# frozen_string_literal: true

class DeductionType < ApplicationRecord
  validates :name, presence: true
  validates :code, presence: true, uniqueness: true
  validates :is_active, inclusion: { in: [true, false] }
  validates :worker_amount, numericality: { greater_than_or_equal_to: 0 }
  validates :employee_amount, numericality: { greater_than_or_equal_to: 0 }

  scope :active, -> { where(is_active: true) }

  # Ransack configuration
  def self.ransackable_attributes(_auth_object = nil)
    %w[id name code description is_active worker_amount employee_amount created_at updated_at]
  end

  def self.ransackable_associations(_auth_object = nil)
    []
  end
end
