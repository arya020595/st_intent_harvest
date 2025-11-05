# frozen_string_literal: true

class WorkOrder::ApprovalsController < ApplicationController
  include RansackMultiSort

  before_action :set_work_order, only: %i[show update approve reject]

  def index
    authorize WorkOrder, policy_class: WorkOrder::ApprovalPolicy

    apply_ransack_search(policy_scope(WorkOrder, policy_scope_class: WorkOrder::ApprovalPolicy::Scope).order(id: :desc))
    @pagy, @work_orders = paginate_results(@q.result.includes(:block, :work_order_rate, :field_conductor))
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
