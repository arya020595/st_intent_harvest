class WorkOrderRate < ApplicationRecord
  belongs_to :unit, optional: true

  validates :work_order_name, presence: true
  validates :rate, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true

  # Ransack configuration
  def self.ransackable_attributes(_auth_object = nil)
    %w[id work_order_name rate currency created_at updated_at unit_id]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[unit]
  end
end

# == Schema Information
#
# Table name: work_order_rates
#
#  id              :bigint           not null, primary key
#  currency        :string           default("RM")
#  rate            :decimal(10, 2)
#  work_order_name :string
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  unit_id         :bigint
#
# Indexes
#
#  index_work_order_rates_on_unit_id  (unit_id)
#
# Foreign Keys
#
#  fk_rails_...  (unit_id => units.id)
#
