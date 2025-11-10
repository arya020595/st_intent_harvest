# frozen_string_literal: true

module WorkOrderServices
  class CreateService
    include Dry::Monads[:result, :do]

    attr_reader :work_order

    def initialize(work_order_params)
      @work_order_params = work_order_params
      @work_order = WorkOrder.new(work_order_params)
    end

    def call(draft: false)
      if draft
        save_as_draft
      else
        save_and_submit
      end
    end

    private

    def save_as_draft
      if work_order.save
        Success(work_order: work_order, message: 'Work order was saved as draft.')
      else
        Failure(work_order.errors.full_messages)
      end
    end

    def save_and_submit
      result = nil
      ActiveRecord::Base.transaction do
        if work_order.save
          begin
            # Use AASM transition to pending so history callbacks run
            work_order.mark_complete!
            result = Success(work_order: work_order, message: 'Work order was successfully submitted.')
          rescue StandardError => e
            Rails.logger.error("WorkOrder submission transition failed: #{e.class}: #{e.message}")
            result = Failure(['There was an error submitting the work order. Please try again.'])
            raise ActiveRecord::Rollback
          end
        else
          result = Failure(work_order.errors.full_messages)
        end
      end
      result
    end
  end
end
