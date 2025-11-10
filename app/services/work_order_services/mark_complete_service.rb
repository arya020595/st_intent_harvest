# frozen_string_literal: true

module WorkOrderServices
  class MarkCompleteService
    include Dry::Monads[:result]

    attr_reader :work_order

    def initialize(work_order)
      @work_order = work_order
    end

    def call
      # Perform state transition based on current AASM state
      if work_order.amendment_required?
        execute_transition(:reopen!, 'resubmitted for approval')
      elsif work_order.ongoing?
        execute_transition(:mark_complete!, 'submitted for approval')
      else
        Failure("Work order cannot be marked complete from '#{work_order.work_order_status.humanize}' status.")
      end
    end

    private

    # Executes AASM state transition event
    # @param event [Symbol] AASM event method to call (e.g., :reopen!, :mark_complete!)
    # @param success_context [String] Description for success message
    # @return [Success, Failure] Result monad with success or error message
    def execute_transition(event, success_context)
      # Dynamically call AASM event method
      # Using public_send to avoid duplicating error handling for each transition
      work_order.public_send(event)
      Success("Work order has been #{success_context}.")
    rescue AASM::InvalidTransition => e
      Rails.logger.error("WorkOrder transition failed: #{e.class}: #{e.message}")
      Failure("Transition error: #{e.message}")
    rescue StandardError => e
      Rails.logger.error("WorkOrder submission failed: #{e.class}: #{e.message}")
      Failure("Failed to mark work order as complete: #{e.message}")
    end
  end
end
