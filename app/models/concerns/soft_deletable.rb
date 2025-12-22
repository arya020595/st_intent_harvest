# frozen_string_literal: true

# SoftDeletable - A SOLID concern for soft delete functionality using Discard gem
#
# Single Responsibility: This concern only handles soft delete logic
# Open/Closed: Configurable through class methods, extendable without modification
# Interface Segregation: Provides focused interface for soft delete operations
# Dependency Inversion: Depends on Discard abstraction, not implementation details
#
# Usage:
#   class MyModel < ApplicationRecord
#     include SoftDeletable
#   end
#
# Note: Model must have 'discarded_at' column (datetime) for soft delete to work
#
module SoftDeletable
  extend ActiveSupport::Concern

  included do
    include Discard::Model

    # Default scope to exclude discarded records
    # Override with `with_discarded` or `unscope(:where)` when needed
    default_scope -> { kept }

    # Callback hooks for extensibility (Open/Closed Principle)
    define_callbacks :discard, :undiscard

    # Wrap discard/undiscard with callbacks for extensibility
    set_callback :discard, :after, :after_discard_callback, if: :respond_to_after_discard?
    set_callback :undiscard, :after, :after_undiscard_callback, if: :respond_to_after_undiscard?
  end

  class_methods do
    # Check if the model's table has discarded_at column
    # Safely returns false if table doesn't exist yet (for migrations)
    def soft_deletable?
      return false unless table_exists?

      column_names.include?('discarded_at')
    end

    # Scope: All records including soft-deleted
    # Already provided by Discard as `with_discarded`

    # Scope: Only soft-deleted records
    # Already provided by Discard as `discarded`

    # Scope: Only non-deleted records
    # Already provided by Discard as `kept`

    # Batch soft delete by IDs
    # Only discards kept (non-discarded) records to avoid re-discarding
    # Returns the count of records actually discarded
    def soft_delete_all(ids)
      kept.where(id: ids).discard_all
    end

    # Batch restore by IDs
    # Only restores discarded records
    # Returns the count of records actually restored
    def restore_all(ids)
      with_discarded.discarded.where(id: ids).undiscard_all
    end
  end

  # Instance Methods

  # Soft delete with optional reason tracking
  # Can be extended in model with after_discard callback
  def soft_delete(reason: nil)
    run_callbacks :discard do
      @discard_reason = reason
      discard
    end
  end

  # Alias for semantic clarity
  alias archive soft_delete

  # Restore a soft-deleted record
  def restore
    run_callbacks :undiscard do
      undiscard
    end
  end

  # Alias for semantic clarity
  alias unarchive restore

  # Check if record is soft deleted
  def soft_deleted?
    discarded?
  end

  # Alias for semantic clarity
  alias archived? soft_deleted?

  # Get the discard reason (if set during soft_delete)
  attr_reader :discard_reason

  private

  def respond_to_after_discard?
    respond_to?(:after_discard, true)
  end

  def respond_to_after_undiscard?
    respond_to?(:after_undiscard, true)
  end

  def after_discard_callback
    after_discard if respond_to?(:after_discard, true)
  end

  def after_undiscard_callback
    after_undiscard if respond_to?(:after_undiscard, true)
  end
end
