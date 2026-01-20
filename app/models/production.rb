# frozen_string_literal: true

class Production < ApplicationRecord
  belongs_to :block
  belongs_to :mill

  validates :date, presence: true
  validates :total_bunches, presence: true, numericality: { greater_than_or_equal_to: 0, only_integer: true }
  validates :total_weight_ton, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :block_id, presence: true
  validates :mill_id, presence: true

  scope :ordered, -> { order(date: :desc, created_at: :desc) }
  scope :by_date_range, ->(start_date, end_date) { where(date: start_date..end_date) }
  scope :by_block, ->(block_id) { where(block_id: block_id) }
  scope :by_mill, ->(mill_id) { where(mill_id: mill_id) }

  # Ransack configuration
  def self.ransackable_attributes(_auth_object = nil)
    %w[id date ticket_estate_no ticket_mill_no total_bunches total_weight_ton created_at updated_at]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[block mill]
  end
end
