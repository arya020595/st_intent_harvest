# frozen_string_literal: true

module WorkOrderServices
  class RequestAmendmentService
    include Dry::Monads[:result]

    attr_reader :work_order, :remarks

    def initialize(work_order, remarks = nil)
      @work_order = work_order
      @remarks = remarks
    end

    def call
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
      # Pass remarks using keyword arguments
      # The after callback will receive this and use it for WorkOrderHistory
      work_order.request_amendment!(remarks: remarks)
    end
  end
end
