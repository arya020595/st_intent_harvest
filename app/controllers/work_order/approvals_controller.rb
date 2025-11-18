# frozen_string_literal: true

module WorkOrder
  class ApprovalsController < ApplicationController
    include RansackMultiSort
    include ResponseHandling

    before_action :set_work_order, only: %i[show update approve request_amendment]

    def index
      authorize WorkOrder, policy_class: WorkOrder::ApprovalPolicy

      # Exclude 'ongoing' work orders from approvals listing
      base_scope = policy_scope(WorkOrder, policy_scope_class: WorkOrder::ApprovalPolicy::Scope)
                   .where.not(work_order_status: WorkOrder::STATUSES[:ongoing])
                   .order(id: :desc)

      apply_ransack_search(base_scope)
      @pagy, @work_orders = paginate_results(@q.result)
    end

    def show
      authorize @work_order, policy_class: WorkOrder::ApprovalPolicy
    end

    def update
      authorize @work_order, policy_class: WorkOrder::ApprovalPolicy

      # Logic to be implemented later
    end

    def approve
      authorize @work_order, policy_class: WorkOrder::ApprovalPolicy

      service = WorkOrderServices::ApproveService.new(@work_order, current_user)
      result = service.call

      # HTML (ERB form) -> redirect to index
      # JSON (JavaScript) -> redirect to show (stay on current page)
      handle_result(result,
                    success_path: work_order_approvals_path,
                    json_success_path: work_order_approval_path(@work_order),
                    error_path: work_order_approval_path(@work_order))
    end

    def request_amendment
      authorize @work_order, policy_class: WorkOrder::ApprovalPolicy

      remarks = params.dig(:work_order_history, :remarks)
      service = WorkOrderServices::RequestAmendmentService.new(@work_order, remarks)
      result = service.call

      # HTML (ERB form) -> redirect to index
      # JSON (JavaScript) -> redirect to show (stay on current page)
      handle_result(result,
                    success_path: work_order_approvals_path,
                    json_success_path: work_order_approval_path(@work_order),
                    error_path: work_order_approval_path(@work_order))
    end

    private

    def set_work_order
      @work_order = WorkOrder.find(params[:id])
    end

    def approval_params
      params.require(:work_order).permit(:approved_by, :approved_at)
    end
  end
end
