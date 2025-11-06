# frozen_string_literal: true

module WorkOrderServices
  class ApproveService
    include Dry::Monads[:result]

    attr_reader :work_order, :current_user

    def initialize(work_order, current_user)
      @work_order = work_order
      @current_user = current_user
    end

    def call
      unless work_order.may_approve?
        return Failure("Cannot approve work order in #{work_order.work_order_status} status.")
      end

      approve_work_order
      Success('Work order has been approved successfully.')
    rescue AASM::InvalidTransition => e
      Failure("Failed to approve work order: #{e.message}")
    end

    private

    def approve_work_order
      work_order.approved_by = current_user.name
      work_order.approved_at = Time.current
      work_order.approve!
    end
  end
end
