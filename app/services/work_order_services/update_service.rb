# frozen_string_literal: true

module WorkOrderServices
  class UpdateService
    attr_reader :work_order, :errors

    def initialize(work_order, work_order_params)
      @work_order = work_order
      @work_order_params = work_order_params
      @errors = []
    end

    def call(submit: false)
      if submit
        update_and_submit
      else
        update_only
      end
    end

    def success?
      errors.empty?
    end

    private

    def update_only
      if work_order.update(@work_order_params)
        true
      else
        @errors = work_order.errors.full_messages
        false
      end
    end

    def update_and_submit
      success = false
      ActiveRecord::Base.transaction do
        if work_order.update(@work_order_params)
          begin
            # Use AASM transition to pending based on current status
            if work_order.work_order_status == 'amendment_required'
              work_order.reopen!
            elsif work_order.work_order_status == 'ongoing'
              work_order.mark_complete!
            else
              @errors << "Work order cannot be submitted from '#{work_order.work_order_status}' status."
              raise ActiveRecord::Rollback
            end
            success = true
          rescue StandardError => e
            Rails.logger.error("WorkOrder submission transition failed: #{e.class}: #{e.message}")
            @errors << 'There was an error submitting the work order. Please try again.' unless @errors.any?
            raise ActiveRecord::Rollback
          end
        else
          @errors = work_order.errors.full_messages
        end
      end
      success
    end
  end
end
