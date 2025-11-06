# frozen_string_literal: true

module WorkOrderServices
  class MarkCompleteService
    include Dry::Monads[:result]

    attr_reader :work_order

    def initialize(work_order)
      @work_order = work_order
    end

    def call
      case work_order.work_order_status
      when 'amendment_required'
        reopen_work_order
      when 'ongoing'
        complete_work_order
      else
        Failure('Work order cannot be marked complete from this status.')
      end
    end

    private

    def complete_work_order
      work_order.mark_complete!
      Success('Work order has been submitted for approval.')
    rescue StandardError => e
      Failure("Failed to mark work order as complete: #{e.message}")
    end

    def reopen_work_order
      work_order.reopen!
      Success('Work order has been resubmitted for approval.')
    rescue StandardError => e
      Failure("Failed to reopen work order: #{e.message}")
    end
  end
end
