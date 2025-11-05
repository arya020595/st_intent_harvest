# frozen_string_literal: true

module WorkOrderServices
  class CreateService
    attr_reader :work_order, :errors

    def initialize(work_order_params)
      @work_order_params = work_order_params
      @work_order = WorkOrder.new(work_order_params)
      @errors = []
    end

    def call(draft: false)
      if draft
        save_as_draft
      else
        save_and_submit
      end
    end

    def success?
      errors.empty? && work_order.persisted?
    end

    private

    def save_as_draft
      if work_order.save
        true
      else
        @errors = work_order.errors.full_messages
        false
      end
    end

    def save_and_submit
      ActiveRecord::Base.transaction do
        if work_order.save
          begin
            # Use AASM transition to pending so history callbacks run
            work_order.mark_complete!
            true
          rescue StandardError => e
            Rails.logger.error("WorkOrder submission transition failed: #{e.class}: #{e.message}")
            @errors << 'There was an error submitting the work order. Please try again.'
            raise ActiveRecord::Rollback
          end
        else
          @errors = work_order.errors.full_messages
          false
        end
      end
    end
  end
end
