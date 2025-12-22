# frozen_string_literal: true

module SoftDelete
  # SoftDeleteService - Handles soft delete operations with business logic
  #
  # Single Responsibility: Only handles soft delete/restore operations
  # Open/Closed: Can be extended for different models without modification
  # Liskov Substitution: Works with any model that includes SoftDeletable
  # Dependency Inversion: Depends on SoftDeletable interface, not concrete models
  #
  # Usage:
  #   result = SoftDelete::Service.call(record, action: :delete)
  #   result = SoftDelete::Service.call(record, action: :restore)
  #   result = SoftDelete::Service.call(record, action: :delete, cascade: true)
  #
  class Service
    include Dry::Monads[:result]

    def self.call(record, action:, **options)
      new(record, action:, **options).call
    end

    def initialize(record, action:, cascade: false, reason: nil)
      @record = record
      @action = action.to_sym
      @cascade = cascade
      @reason = reason
    end

    def call
      return Failure(:not_soft_deletable) unless soft_deletable?
      return Failure(:invalid_action) unless valid_action?

      send("perform_#{@action}")
    end

    private

    attr_reader :record, :action, :cascade, :reason

    def soft_deletable?
      record.class.respond_to?(:soft_deletable?) && record.class.soft_deletable?
    end

    def valid_action?
      %i[delete restore].include?(action)
    end

    def perform_delete
      return Failure(:already_deleted) if record.discarded?

      if record.soft_delete(reason:)
        Success(record)
      else
        Failure(:delete_failed)
      end
    end

    def perform_restore
      return Failure(:not_deleted) unless record.discarded?

      if record.restore
        Success(record)
      else
        Failure(:restore_failed)
      end
    end
  end
end
