# frozen_string_literal: true

# CascadingSoftDelete - Handles cascading soft delete for associations
#
# Single Responsibility: Only handles cascade logic for soft deletes
# Open/Closed: Configurable cascade associations without modifying core logic
# Dependency Inversion: Depends on SoftDeletable abstraction
#
# Performance: Uses batch SQL updates instead of individual record updates
# for efficient cascading operations, especially with large associations.
#
# Supported Associations:
# - Standard associations (has_many, has_one, belongs_to)
# - Polymorphic associations
# - Custom foreign keys
#
# Limitations:
# - has_many :through associations are not supported for cascading
#   as the relationship is indirect
# - All associated models must include the Discard gem functionality
#
# Usage:
#   class ParentModel < ApplicationRecord
#     include SoftDeletable
#     include CascadingSoftDelete
#
#     has_many :children, dependent: :destroy
#
#     cascade_soft_delete :children, :other_association
#   end
#
module CascadingSoftDelete
  extend ActiveSupport::Concern

  included do
    class_attribute :_cascade_associations, default: []
  end

  class_methods do
    # Define which associations should cascade soft delete
    # @param associations [Array<Symbol>] - association names to cascade
    def cascade_soft_delete(*associations)
      self._cascade_associations = associations.flatten
    end
  end

  private

  # Override after_discard to cascade soft delete to associations
  def after_discard
    cascade_discard_to_associations
    super if defined?(super)
  end

  # Override after_undiscard to cascade restore to associations
  def after_undiscard
    cascade_undiscard_to_associations
    super if defined?(super)
  end

  def cascade_discard_to_associations
    self.class._cascade_associations.each do |association_name|
      cascade_discard_association(association_name)
    end
  end

  def cascade_undiscard_to_associations
    self.class._cascade_associations.each do |association_name|
      cascade_undiscard_association(association_name)
    end
  end

  def cascade_discard_association(association_name)
    association = self.class.reflect_on_association(association_name)
    return unless association

    klass = association.klass
    # Verify the model supports soft delete functionality
    return unless klass.respond_to?(:kept)

    # Build the query based on association type
    query = build_cascade_query_for_discard(association)
    return unless query

    # Use batch update instead of individual discard calls for better performance
    # This updates all records in a single SQL UPDATE statement
    query.update_all(discarded_at: Time.current)
  end

  def build_cascade_query_for_discard(association)
    build_cascade_base_query(association, association.klass.kept)
  end

  def cascade_undiscard_association(association_name)
    association = self.class.reflect_on_association(association_name)
    return unless association

    klass = association.klass
    return unless klass.respond_to?(:with_discarded)

    # Build the query based on association type
    query = build_cascade_query(association)
    return unless query

    # Use batch update instead of individual undiscard calls for better performance
    # This updates all records in a single SQL UPDATE statement
    query.update_all(discarded_at: nil)
  end

  def build_cascade_query(association)
    return unless association.klass.respond_to?(:with_discarded)
    
    build_cascade_base_query(association, association.klass.with_discarded.discarded)
  end

  # Shared method to build cascade queries for both discard and undiscard operations
  # @param association [ActiveRecord::Reflection::AssociationReflection] the association reflection
  # @param base_scope [ActiveRecord::Relation] the base scope to build upon (kept or with_discarded.discarded)
  # @return [ActiveRecord::Relation, nil] the query to execute, or nil if not supported
  def build_cascade_base_query(association, base_scope)
    # Handle has_many :through associations
    return nil if association.through_reflection

    # Handle polymorphic associations
    if association.polymorphic?
      foreign_type = association.foreign_type
      foreign_key = association.foreign_key

      base_scope.where(
        foreign_type => self.class.base_class.name,
        foreign_key => id
      )
    # Handle standard associations (has_many, has_one, etc.)
    else
      foreign_key = association.foreign_key
      base_scope.where(foreign_key => id)
    end
  end
end
