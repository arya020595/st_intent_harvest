# frozen_string_literal: true

module WorkOrderServices
  class RequestAmendmentService
    include Dry::Monads[:result]

    attr_reader :work_order, :remarks

    def initialize(work_order, remarks)
      @work_order = work_order
      @remarks = remarks
    end

    def call
      return Failure('Remarks are required for amendment request.') if remarks.blank?
      unless work_order.may_request_amendment?
        return Failure("Cannot request amendment for work order in #{work_order.work_order_status} status.")
      end

      request_amendment
      Success('Amendment has been requested for this work order.')
    rescue AASM::InvalidTransition => e
      Failure("Failed to request amendment: #{e.message}")
    end

    private

    def request_amendment
      work_order.request_amendment!
      update_work_order_history_with_remarks
    end

    def update_work_order_history_with_remarks
      work_order.work_order_histories.last.update(remarks: remarks)
    end
  end
end
