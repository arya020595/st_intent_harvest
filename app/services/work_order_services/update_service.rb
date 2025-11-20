# frozen_string_literal: true

module WorkOrderServices
  class UpdateService
    include Dry::Monads[:result, :do]

    attr_reader :work_order

    def initialize(work_order, work_order_params)
      @work_order = work_order
      @work_order_params = ParamsNormalizer.call(work_order_params)
    end

    def call(submit: false)
      AppLogger.service_start('UpdateWorkOrder',
                              context: self.class.name,
                              work_order_id: work_order.id,
                              submit: submit)

      result = if submit
                 update_and_submit
               else
                 update_only
               end

      if result.success?
        AppLogger.service_success('UpdateWorkOrder',
                                  context: self.class.name,
                                  work_order_id: work_order.id,
                                  status: work_order.work_order_status)
      else
        AppLogger.service_failure('UpdateWorkOrder',
                                  context: self.class.name,
                                  error: result.failure,
                                  work_order_id: work_order.id)
      end

      result
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
          work_order.reopen!
          AppLogger.info('Work order reopened after amendments', context: self.class.name, work_order_id: work_order.id)
          Success('Work order was successfully resubmitted after amendments.')
        rescue AASM::InvalidTransition => e
          AppLogger.error('Reopen transition failed', context: self.class.name, error: e.message,
                                                      current_state: work_order.work_order_status)
          Failure("Transition error: #{e.message}")
        rescue StandardError => e
          AppLogger.error('Reopen failed', context: self.class.name, error: e.message, work_order_id: work_order.id)
          Failure("Reopen error: #{e.message}")
        end
      elsif work_order.ongoing?
        begin
          work_order.mark_complete!
          AppLogger.info('Work order marked complete', context: self.class.name, work_order_id: work_order.id)
          Success('Work order was successfully submitted for approval.')
        rescue AASM::InvalidTransition => e
          AppLogger.error('Mark complete transition failed', context: self.class.name, error: e.message,
                                                             current_state: work_order.work_order_status)
          Failure("Transition error: #{e.message}")
        rescue StandardError => e
          AppLogger.error('Submit failed', context: self.class.name, error: e.message, work_order_id: work_order.id)
          Failure("Submission error: #{e.message}")
        end
      else
        AppLogger.warn('Invalid state for submission', context: self.class.name, work_order_id: work_order.id,
                                                       current_state: work_order.work_order_status)
        Failure("Work order cannot be submitted from '#{work_order.work_order_status.humanize}' status.")
      end
    end
  end
end
