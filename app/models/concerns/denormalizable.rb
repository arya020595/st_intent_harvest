# frozen_string_literal: true

# Denormalizable concern
# Provides a clean DSL for defining denormalized fields that auto-populate from associations
#
# Usage:
#   class WorkOrder < ApplicationRecord
#     include Denormalizable
#
#     denormalize :block_number, from: :block
#     denormalize :block_hectarage, from: :block, attribute: :hectarage, transform: ->(val) { val.to_s }
#     denormalize :work_order_rate_name, from: :work_order_rate, attribute: :work_order_name
#   end
module Denormalizable
  extend ActiveSupport::Concern

  included do
    before_save :populate_denormalized_fields
  end

  class_methods do
    # Define denormalized fields with their source associations
    # @param field [Symbol] The denormalized field name in current model
    # @param from [Symbol] The association name to get data from
    # @param attribute [Symbol] The attribute name in the associated model (defaults to field name)
    # @param transform [Proc] Optional transformation to apply to the value
    def denormalize(field, from:, attribute: nil, transform: nil)
      denormalized_fields[field] = {
        association: from,
        attribute: attribute || field,
        transform: transform
      }
    end

    # Returns the denormalized fields configuration for this class
    # Uses class instance variable to avoid inheritance issues
    def denormalized_fields
      @denormalized_fields ||= if superclass.respond_to?(:denormalized_fields)
                                 superclass.denormalized_fields.dup
                               else
                                 {}
                               end
    end
  end

  private

  def populate_denormalized_fields
    self.class.denormalized_fields.each do |field, config|
      association = config[:association]
      source_attribute = config[:attribute]
      transform = config[:transform]

      # Only update if the foreign key changed and association exists
      foreign_key = "#{association}_id"
      next unless respond_to?("#{foreign_key}_changed?") && public_send("#{foreign_key}_changed?")

      associated_record = public_send(association)
      next unless associated_record

      # Get the value from associated record
      value = associated_record.public_send(source_attribute)

      # Apply transformation if provided (even on nil values)
      value = transform.call(value) if transform

      # Set the denormalized field
      public_send("#{field}=", value)
    end
  end
end
