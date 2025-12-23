# frozen_string_literal: true

class ApplicationRecord < ActiveRecord::Base
  primary_abstract_class

  # Include soft delete functionality for all models
  # Models need 'discarded_at' column to enable soft delete
  # Use `with_discarded` scope to include soft-deleted records
  # Use `discarded` scope to only get soft-deleted records
  include SoftDeletable
end
