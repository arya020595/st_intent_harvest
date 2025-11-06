# frozen_string_literal: true

module ResponseHandler
  class WorkOrderResponseService
    include Dry::Monads[:result]

    attr_reader :controller, :work_order

    def initialize(controller, work_order = nil)
      @controller = controller
      @work_order = work_order
    end

    def handle_result(result, success_path: nil, error_path: nil)
      result.either(
        ->(message) { handle_success(message, success_path) },
        ->(error) { handle_error(error, error_path) }
      )
    end

    private

    def handle_success(message, path = nil)
      redirect_path = path || default_success_path
      
      controller.respond_to do |format|
        format.html { controller.redirect_to redirect_path, notice: message }
        format.json { controller.head :ok }
      end
    end

    def handle_error(error_message, path = nil)
      redirect_path = path || default_error_path
      error_text = error_message.is_a?(Array) ? error_message.join(', ') : error_message
      
      controller.respond_to do |format|
        format.html { controller.redirect_to redirect_path, alert: error_text }
        format.json { controller.render json: { error: error_text }, status: :unprocessable_entity }
      end
    end

    def default_success_path
      controller.work_order_approvals_path
    end

    def default_error_path
      if work_order
        controller.work_order_approval_path(work_order)
      else
        controller.work_order_approvals_path
      end
    end
  end
end
