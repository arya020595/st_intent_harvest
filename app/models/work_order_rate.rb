class WorkOrderRate < ApplicationRecord
  belongs_to :unit, optional: true
  
  validates :work_order_name, presence: true
  validates :rate, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
end

# == Schema Information
#
# Table name: work_order_rates
#
#  id              :bigint           not null, primary key
#  rate            :decimal(10, 2)
#  work_order_name :string           not null
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
