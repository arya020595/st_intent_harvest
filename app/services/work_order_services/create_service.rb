# frozen_string_literal: true

module WorkOrderServices
  class CreateService
    include Dry::Monads[:result, :do]

    attr_reader :work_order

    def initialize(work_order_params)
      @work_order_params = ParamsNormalizer.call(work_order_params)
      @work_order = WorkOrder.new(@work_order_params)
    end

    def call(draft: false)
      AppLogger.service_start('CreateWorkOrder',
                              context: self.class.name,
                              draft: draft,
                              work_order_rate_type: @work_order.work_order_rate&.work_order_rate_type)

      result = if draft
                 save_as_draft
               else
                 save_and_submit
               end

      if result.success?
        AppLogger.service_success('CreateWorkOrder',
                                  context: self.class.name,
                                  work_order_id: @work_order.id,
                                  status: @work_order.work_order_status)
      else
        AppLogger.service_failure('CreateWorkOrder',
                                  context: self.class.name,
                                  error: result.failure.join(', '),
                                  work_order_params: @work_order_params.except(:work_order_workers_attributes,
                                                                               :work_order_items_attributes))
      end

      result
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
        # Step 1: Save the work order
        unless work_order.save
          result = Failure(work_order.errors.full_messages)
          raise ActiveRecord::Rollback
        end

        # Step 2: Transition to pending state (triggers history tracking)
        result = execute_submit_transition
        raise ActiveRecord::Rollback if result.failure?
      end

      result
    end

    # Executes AASM transition to submit work order for approval
    # @return [Success, Failure] Result monad with work_order and message or error
    def execute_submit_transition
      # Call AASM event to transition from ongoing -> pending
      # This triggers WorkOrderHistory.record_transition callback
      work_order.mark_complete!
      AppLogger.info('Work order transitioned to pending', context: self.class.name, work_order_id: work_order.id)
      Success(work_order: work_order, message: 'Work order was successfully submitted.')
    rescue AASM::InvalidTransition => e
      AppLogger.error('AASM transition failed', context: self.class.name, error: e.message,
                                                from_state: work_order.aasm.current_state)
      Failure("Transition error: #{e.message}")
    rescue StandardError => e
      AppLogger.error('Work order submission failed', context: self.class.name, error: e.message,
                                                      work_order_id: work_order.id)
      Failure("Submission error: #{e.message}")
    end
  end
end
