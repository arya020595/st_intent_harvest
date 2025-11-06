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
      ActiveRecord::Base.transaction do
        if work_order.update(@work_order_params)
          begin
            # Use AASM transition to pending based on current status
            if work_order.work_order_status == 'amendment_required'
              work_order.reopen!
            elsif work_order.work_order_status == 'ongoing'
              work_order.mark_complete!
            else
              raise StandardError, "Work order cannot be submitted from '#{work_order.work_order_status}' status."
            end
            Success('Work order was successfully submitted for approval.')
          rescue StandardError => e
            Rails.logger.error("WorkOrder submission transition failed: #{e.class}: #{e.message}")
            raise ActiveRecord::Rollback
          end
        else
          Failure(work_order.errors.full_messages)
        end
      end || Failure(['There was an error submitting the work order. Please try again.'])
    end
  end
end
