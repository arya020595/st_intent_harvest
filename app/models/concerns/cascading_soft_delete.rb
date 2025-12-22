# frozen_string_literal: true

# CascadingSoftDelete - Handles cascading soft delete for associations
#
# Single Responsibility: Only handles cascade logic for soft deletes
# Open/Closed: Configurable cascade associations without modifying core logic
# Dependency Inversion: Depends on SoftDeletable abstraction
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
    association = send(association_name)
    return unless association.respond_to?(:each)

    association.find_each do |record|
      record.discard if record.respond_to?(:discard) && record.kept?
    end
  end

  def cascade_undiscard_association(association_name)
    association = self.class.reflect_on_association(association_name)
    return unless association

    # For has_many, we need to query with_discarded to find soft-deleted children
    klass = association.klass
    return unless klass.respond_to?(:with_discarded)

    foreign_key = association.foreign_key
    klass.with_discarded.discarded.where(foreign_key => id).find_each do |record|
      record.undiscard if record.respond_to?(:undiscard)
    end
  end
end
