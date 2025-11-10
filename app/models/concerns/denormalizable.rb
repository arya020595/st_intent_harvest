# frozen_string_literal: true

# Denormalizable concern
# Provides a clean DSL for defining denormalized fields that auto-populate from associations
#
# Usage:
#   class WorkOrder < ApplicationRecord
#     include Denormalizable
#
#     # Simple denormalization
#     denormalize :block_number, from: :block
#
#     # With custom attribute
#     denormalize :block_hectarage, from: :block, attribute: :hectarage, transform: ->(val) { val.to_s }
#
#     # Nested associations with path
#     denormalize :unit_name, from: :inventory, path: 'unit.name'
#     denormalize :category_name, from: :inventory, path: 'category.name'
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
    # @param path [String] Dot-separated path for nested associations (e.g., 'unit.name')
    # @param transform [Proc] Optional transformation to apply to the value
    def denormalize(field, from:, attribute: nil, path: nil, transform: nil)
      denormalized_fields[field] = {
        association: from,
        attribute: attribute || field,
        path: path,
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
      path = config[:path]
      transform = config[:transform]

      # Only update if the foreign key changed and association exists
      foreign_key = "#{association}_id"
      next unless respond_to?("#{foreign_key}_changed?") && public_send("#{foreign_key}_changed?")

      associated_record = public_send(association)
      next unless associated_record

      # Get the value from associated record
      # Support nested path (e.g., 'unit.name') or direct attribute
      value = if path
                # Navigate through nested associations using path
                # e.g., 'unit.name' becomes associated_record.unit&.name
                path.split('.').reduce(associated_record) do |obj, method|
                  obj&.public_send(method)
                end
              else
                associated_record.public_send(source_attribute)
              end

      # Apply transformation if provided
      value = transform.call(value) if transform

      # Set the denormalized field
      public_send("#{field}=", value)
    end
  end
end
