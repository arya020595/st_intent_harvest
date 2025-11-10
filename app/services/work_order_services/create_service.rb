# frozen_string_literal: true

module WorkOrderServices
  class CreateService
    include Dry::Monads[:result, :do]

    attr_reader :work_order

    def initialize(work_order_params)
      @work_order_params = work_order_params
      @work_order = WorkOrder.new(work_order_params)
    end

    def call(draft: false)
      if draft
        save_as_draft
      else
        save_and_submit
      end
    end

    private

    def save_as_draft
      if work_order.save
        Success(work_order: work_order, message: 'Work order was saved as draft.')
      else
        Failure(work_order.errors.full_messages)
      end
    end

    def save_and_submit
      result = nil

      ActiveRecord::Base.transaction do
        # Step 1: Save the work order
        unless work_order.save
          result = Failure(work_order.errors.full_messages)
          raise ActiveRecord::Rollback
        end

        # Step 2: Transition to pending state (triggers history tracking)
        result = execute_submit_transition
        raise ActiveRecord::Rollback if result.failure?
      end

      result
    end

    # Executes AASM transition to submit work order for approval
    # @return [Success, Failure] Result monad with work_order and message or error
    def execute_submit_transition
      # Call AASM event to transition from ongoing -> pending
      # This triggers WorkOrderHistory.record_transition callback
      unless work_order.has_workers_or_items?
        work_order.errors.add(:base, 'Work order must have at least one worker or one inventory item')
        return Failure(work_order.errors.full_messages)
      end

      work_order.mark_complete!
      Success(work_order: work_order, message: 'Work order was successfully submitted.')
    rescue AASM::InvalidTransition => e
      Rails.logger.error("WorkOrder submission transition failed: #{e.class}: #{e.message}")
      work_order.errors.add(:base, 'Work order must have at least one worker or one inventory item')
      Failure(work_order.errors.full_messages)
    rescue StandardError => e
      Rails.logger.error("WorkOrder submission failed: #{e.class}: #{e.message}")
      Failure("Submission error: #{e.message}")
    end
  end
end
