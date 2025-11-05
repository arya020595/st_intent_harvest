# frozen_string_literal: true

class WorkOrder::ApprovalsController < ApplicationController
  include RansackMultiSort

  before_action :set_work_order, only: %i[show update approve request_amendment]

  def index
    authorize WorkOrder, policy_class: WorkOrder::ApprovalPolicy

    # Exclude 'ongoing' work orders from approvals listing
    base_scope = policy_scope(WorkOrder, policy_scope_class: WorkOrder::ApprovalPolicy::Scope)
                 .where.not(work_order_status: WorkOrder::STATUSES[:ongoing])
                 .order(id: :desc)

    apply_ransack_search(base_scope)
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

    if @work_order.may_approve?
      @work_order.approved_by = current_user.name
      @work_order.approved_at = Time.current
      @work_order.approve!
      redirect_to work_order_approvals_path, notice: 'Work order has been approved successfully.'
    else
      redirect_to work_order_approval_path(@work_order),
                  alert: "Cannot approve work order in #{@work_order.work_order_status} status."
    end
  rescue AASM::InvalidTransition => e
    redirect_to work_order_approval_path(@work_order), alert: "Failed to approve work order: #{e.message}"
  end

  def request_amendment
    authorize @work_order, policy_class: WorkOrder::ApprovalPolicy

    if @work_order.may_request_amendment?
      @work_order.request_amendment!
      redirect_to work_order_approvals_path, notice: 'Amendment has been requested for this work order.'
    else
      redirect_to work_order_approval_path(@work_order),
                  alert: "Cannot request amendment for work order in #{@work_order.work_order_status} status."
    end
  rescue AASM::InvalidTransition => e
    redirect_to work_order_approval_path(@work_order), alert: "Failed to request amendment: #{e.message}"
  end

  private

  def set_work_order
    @work_order = WorkOrder.find(params[:id])
  end

  def approval_params
    params.require(:work_order).permit(:approved_by, :approved_at)
  end
end
