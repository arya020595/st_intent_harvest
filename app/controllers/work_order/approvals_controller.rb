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

    service = WorkOrderServices::ApproveService.new(@work_order, current_user)
    result = service.call

    result.either(
      ->(message) { respond_with_success(message) },
      ->(error) { respond_with_error(error) }
    )
  end

  def request_amendment
    authorize @work_order, policy_class: WorkOrder::ApprovalPolicy

    remarks = params.dig(:work_order_history, :remarks)
    service = WorkOrderServices::RequestAmendmentService.new(@work_order, remarks)
    result = service.call

    result.either(
      ->(message) { respond_with_success(message) },
      ->(error) { respond_with_error(error) }
    )
  end

  private

  def set_work_order
    @work_order = WorkOrder.find(params[:id])
  end

  def approval_params
    params.require(:work_order).permit(:approved_by, :approved_at)
  end

  # Response handlers
  def respond_with_success(notice_message)
    respond_to do |format|
      format.html { redirect_to work_order_approvals_path, notice: notice_message }
      format.json { head :ok }
    end
  end

  def respond_with_error(error_message)
    respond_to do |format|
      format.html { redirect_to work_order_approval_path(@work_order), alert: error_message }
      format.json { render json: { error: error_message }, status: :unprocessable_entity }
    end
  end
end
