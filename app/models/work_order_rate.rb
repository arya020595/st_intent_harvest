# frozen_string_literal: true

class WorkOrderRate < ApplicationRecord
  belongs_to :unit, optional: true

  # Define enum for work_order_rate_type
  enum :work_order_rate_type, {
    normal: 'normal',         # Show all fields (workers + resources + work days)
    resources: 'resources',   # Show only resource fields
    work_days: 'work_days'    # Show only worker details
  }

  # Remove unit_id when work_order_rate_type is work_days
  before_save :clear_unit_for_work_days

  validates :work_order_name, presence: true
  validates :rate, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :work_order_rate_type, presence: true, inclusion: { in: work_order_rate_types.keys }
  validates :unit_id, presence: true, unless: :work_days?

  # Ransack configuration
  def self.ransackable_attributes(_auth_object = nil)
    %w[id work_order_name rate currency work_order_rate_type created_at updated_at unit_id]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[unit]
  end

  private

  def clear_unit_for_work_days
    self.unit_id = nil if work_days?
  end
end
# == Schema Information
#
# Table name: work_order_rates
#
#  id                   :integer , not null
#  created_at           :datetime, not null
#  currency             :string  , default("RM")
#  rate                 :decimal , precision: 10, scale: 2
#  unit_id              :integer
#  updated_at           :datetime, not null
#  work_order_name      :string
#  work_order_rate_type :string  , default("normal"), comment: "Type of work order rate: normal (all fields), resources (resource fields only), work_days (worker details only)"
#
# Indexes
#
#  index_work_order_rates_on_unit_id                  (unit_id)
#
# Foreign Keys
#
#  fk_rails_26d0d8d5ca                                (unit_id => units.id)
#
