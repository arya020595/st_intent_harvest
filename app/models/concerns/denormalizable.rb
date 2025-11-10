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
#
#     # Force refresh on every save (useful when associated data changes frequently)
#     denormalize :block_number, from: :block, force_refresh: true
#   end
#
# Note: By default, denormalized fields are only updated when the foreign key changes.
# This prevents unnecessary database queries but means changes to associated records won't
# automatically propagate. Use force_refresh: true or call refresh_denormalized_fields!
# to update fields even when the association hasn't changed.
#
# To manually refresh all denormalized fields:
#   work_order.refresh_denormalized_fields!
#   work_order.save
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
    # @param force_refresh [Boolean] If true, always refresh this field on save (default: false)
    def denormalize(field, from:, attribute: nil, path: nil, transform: nil, force_refresh: false)
      denormalized_fields[field] = {
        association: from,
        attribute: attribute || field,
        path: path,
        transform: transform,
        force_refresh: force_refresh
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
      force_refresh = config[:force_refresh]

      # Skip if foreign key hasn't changed, unless force_refresh is enabled
      foreign_key = "#{association}_id"
      if respond_to?("#{foreign_key}_changed?")
        next unless force_refresh || public_send("#{foreign_key}_changed?")
      end

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

  # Public method to manually refresh all denormalized fields
  # This is useful when associated records have been updated and you want
  # to refresh the denormalized data without changing the association
  #
  # Example:
  #   block.update(block_number: 'NEW-123')
  #   work_order.refresh_denormalized_fields!
  #   work_order.save
  public

  def refresh_denormalized_fields!
    self.class.denormalized_fields.each do |field, config|
      association = config[:association]
      source_attribute = config[:attribute]
      path = config[:path]
      transform = config[:transform]

      associated_record = public_send(association)
      next unless associated_record

      # Get the value from associated record
      value = if path
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
