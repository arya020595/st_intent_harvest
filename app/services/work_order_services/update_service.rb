# frozen_string_literal: true

module WorkOrderServices
  class UpdateService
    include Dry::Monads[:result, :do]

    attr_reader :work_order

    def initialize(work_order, work_order_params)
      @work_order = work_order
      @work_order_params = work_order_params
    end

    def call(submit: false)
      if submit
        update_and_submit
      else
        update_only
      end
    end

    private

    def update_only
      if work_order.update(@work_order_params)
        Success('Work order was successfully updated.')
      else
        Failure(work_order.errors.full_messages)
      end
    end

    def update_and_submit
      result = nil

      ActiveRecord::Base.transaction do
        # Step 1: Update the work order
        unless work_order.update(@work_order_params)
          result = Failure(work_order.errors.full_messages)
          raise ActiveRecord::Rollback
        end

        # Step 2: Perform state transition based on current AASM state
        result = perform_transition
        raise ActiveRecord::Rollback if result.failure?
      end

      result
    end

    def perform_transition
      if work_order.amendment_required?
        execute_transition(:reopen!, 'resubmitted after amendments')
      elsif work_order.ongoing?
        execute_transition(:mark_complete!, 'submitted for approval')
      else
        Failure("Work order cannot be submitted from '#{work_order.work_order_status.humanize}' status.")
      end
    end

    # Executes AASM state transition event dynamically
    # @param event [Symbol] AASM event method to call (e.g., :reopen!, :mark_complete!)
    # @param success_context [String] Description for success message
    # @return [Success, Failure] Result monad with success or error message
    def execute_transition(event, success_context)
      # Check if work order has workers or items before transitioning to pending
      unless work_order.has_workers_or_items?
        work_order.errors.add(:base, 'Work order must have at least one worker or one inventory item')
        return Failure(work_order.errors.full_messages)
      end

      # Dynamically call AASM event method (e.g., work_order.reopen! or work_order.mark_complete!)
      # Using public_send to avoid duplicating error handling for each transition
      work_order.public_send(event)
      Success("Work order was successfully #{success_context}.")
    rescue AASM::InvalidTransition => e
      Rails.logger.error("WorkOrder transition failed: #{e.class}: #{e.message}")
      work_order.errors.add(:base, 'Work order must have at least one worker or one inventory item')
      Failure(work_order.errors.full_messages)
    rescue StandardError => e
      Rails.logger.error("WorkOrder submission failed: #{e.class}: #{e.message}")
      Failure("Submission error: #{e.message}")
    end
  end
end
