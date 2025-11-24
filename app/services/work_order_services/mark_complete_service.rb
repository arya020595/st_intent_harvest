# frozen_string_literal: true

module WorkOrderServices
  class MarkCompleteService
    include Dry::Monads[:result]
    include AasmErrorHandler

    attr_reader :work_order, :remarks

    def initialize(work_order, remarks = nil)
      @work_order = work_order
      @remarks = remarks
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
      work_order.public_send(event, remarks: remarks)
      Success("Work order has been #{success_context}.")
    rescue AASM::InvalidTransition => e
      error_message = handle_aasm_error(e, work_order)
      Failure(error_message)
    rescue StandardError => e
      AppLogger.error('WorkOrder submission failed', context: self.class.name, error_class: e.class.name,
                                                     error_message: e.message, work_order_id: work_order.id)
      Failure("Failed to mark work order as complete: #{e.message}")
    end
  end
end
