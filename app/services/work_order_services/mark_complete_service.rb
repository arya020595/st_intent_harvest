# frozen_string_literal: true

module WorkOrderServices
  class MarkCompleteService
    attr_reader :work_order, :errors

    def initialize(work_order)
      @work_order = work_order
      @errors = []
    end

    def call
      case work_order.work_order_status
      when 'amendment_required'
        reopen_work_order
      when 'ongoing'
        complete_work_order
      else
        @errors << 'Work order cannot be marked complete from this status.'
        false
      end
    end

    def message
      case work_order.work_order_status
      when 'amendment_required'
        'Work order has been resubmitted for approval.'
      when 'ongoing'
        'Work order has been submitted for approval.'
      else
        errors.first || 'There was an error updating the work order status.'
      end
    end

    private

    def complete_work_order
      if work_order.mark_complete!
        true
      else
        @errors << 'Failed to mark work order as complete.'
        false
      end
    end

    def reopen_work_order
      if work_order.reopen!
        true
      else
        @errors << 'Failed to reopen work order.'
        false
      end
    end
  end
end
