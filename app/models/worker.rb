# frozen_string_literal: true

class Worker < ApplicationRecord
  # Constants for form options
  WORKER_TYPES = ['Part - Time', 'Full - Time'].freeze
  GENDERS = %w[Male Female].freeze
  # Nationality values - stored as business logic values (lowercase, underscored)
  # These are used directly in deduction calculations without transformation
  NATIONALITIES = %w[local foreigner foreigner_no_passport].freeze

  # Human-readable labels for UI display
  NATIONALITY_LABELS = {
    'local' => 'Local',
    'foreigner' => 'Foreigner',
    'foreigner_no_passport' => 'Foreigner (No Passport)'
  }.freeze

  has_many :work_order_workers, dependent: :destroy
  has_many :work_orders, through: :work_order_workers
  has_many :pay_calculation_details, dependent: :destroy
  has_many :pay_calculations, through: :pay_calculation_details

  validates :name, presence: true
  validates :worker_type, presence: true, inclusion: { in: WORKER_TYPES }
  validates :gender, inclusion: { in: GENDERS, allow_nil: true }
  validates :nationality, inclusion: { in: NATIONALITIES, allow_nil: true }

  scope :active, -> { where(is_active: true) }
  scope :inactive, -> { where(is_active: false) }
  scope :by_type, ->(type) { where(worker_type: type) if type.present? }
  scope :local, -> { where(nationality: 'local') }
  scope :foreigner, -> { where(nationality: %w[foreigner foreigner_no_passport]) }
  scope :foreigner_with_passport, -> { where(nationality: 'foreigner') }
  scope :foreigner_no_passport, -> { where(nationality: 'foreigner_no_passport') }

  # Class method for form select options
  # Returns array of [label, value] pairs for Rails select helper
  # Example: [['Local', 'local'], ['Foreigner', 'foreigner'], ...]
  def self.nationality_options
    NATIONALITY_LABELS.map { |value, label| [label, value] }
  end

  # Ransack configuration
  def self.ransackable_attributes(_auth_object = nil)
    %w[id name worker_type gender is_active hired_date nationality identity_number created_at updated_at]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[work_order_workers work_orders pay_calculation_details pay_calculations]
  end
end

# == Schema Information
#
# Table name: workers
#
#  id              :integer          not null, primary key
#  name            :string
#  worker_type     :string
#  gender          :string
#  is_active       :boolean
#  hired_date      :date
#  nationality     :string
#  identity_number :string
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#
