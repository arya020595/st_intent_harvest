# frozen_string_literal: true

module SoftDelete
  # BatchService - Handles batch soft delete/restore operations
  #
  # Single Responsibility: Only handles batch operations
  # Open/Closed: Can be extended for different batch behaviors
  #
  # Usage:
  #   result = SoftDelete::BatchService.call(User, ids: [1, 2, 3], action: :delete)
  #   result = SoftDelete::BatchService.call(Worker, ids: [1, 2], action: :restore)
  #
  class BatchService
    include Dry::Monads[:result]

    def self.call(model_class, ids:, action:, **options)
      new(model_class, ids:, action:, **options).call
    end

    def initialize(model_class, ids:, action:)
      @model_class = model_class
      @ids = Array(ids)
      @action = action.to_sym
    end

    def call
      return Failure(:empty_ids) if ids.empty?
      return Failure(:not_soft_deletable) unless soft_deletable?
      return Failure(:invalid_action) unless valid_action?

      send("perform_batch_#{action}")
    end

    private

    attr_reader :model_class, :ids, :action

    def soft_deletable?
      model_class.respond_to?(:soft_deletable?) && model_class.soft_deletable?
    end

    def valid_action?
      %i[delete restore].include?(action)
    end

    def perform_batch_delete
      count = model_class.soft_delete_all(ids)
      Success(deleted_count: count)
    end

    def perform_batch_restore
      count = model_class.restore_all(ids)
      Success(restored_count: count)
    end
  end
end
