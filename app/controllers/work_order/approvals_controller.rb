# frozen_string_literal: true

module WorkOrder
  class ApprovalsController < ApplicationController
    before_action :set_work_order, only: %i[show update approve reject]

    def index
      @work_orders = policy_scope(
        WorkOrder,
        policy_scope_class: WorkOrder::ApprovalPolicy::Scope
      )
      authorize WorkOrder, policy_class: WorkOrder::ApprovalPolicy
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

      # Logic to be implemented later
    end

    def reject
      authorize @work_order, policy_class: WorkOrder::ApprovalPolicy

      # Logic to be implemented later
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
