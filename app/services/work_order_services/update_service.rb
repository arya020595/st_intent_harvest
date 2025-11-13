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
        begin
          work_order.public_send(:reopen!)
          Success("Work order was successfully resubmitted after amendments.")
        rescue AASM::InvalidTransition => e
          Rails.logger.error("WorkOrder transition failed: #{e.class}: #{e.message}")
          Failure("Transition error: #{e.message}")
        rescue StandardError => e
          Rails.logger.error("WorkOrder submission failed: #{e.class}: #{e.message}")
          Failure("Submission error: #{e.message}")
        end
      elsif work_order.ongoing?
        begin
          work_order.public_send(:mark_complete!)
          Success("Work order was successfully submitted for approval.")
        rescue AASM::InvalidTransition => e
          Rails.logger.error("WorkOrder transition failed: #{e.class}: #{e.message}")
          Failure("Transition error: #{e.message}")
        rescue StandardError => e
          Rails.logger.error("WorkOrder submission failed: #{e.class}: #{e.message}")
          Failure("Submission error: #{e.message}")
        end
      else
        Failure("Work order cannot be submitted from '#{work_order.work_order_status.humanize}' status.")
      end
    end
  end
end
