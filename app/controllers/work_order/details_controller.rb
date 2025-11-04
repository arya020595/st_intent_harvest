# frozen_string_literal: true

class WorkOrder::DetailsController < ApplicationController
  include RansackMultiSort

  before_action :set_work_order, only: %i[show edit update destroy mark_complete]

  def index
    authorize WorkOrder, policy_class: WorkOrder::DetailPolicy

    apply_ransack_search(policy_scope(WorkOrder, policy_scope_class: WorkOrder::DetailPolicy::Scope).order(id: :desc))
    @pagy, @work_orders = paginate_results(@q.result.includes(:block, :work_order_rate, :field_conductor))
  end

  def show
    authorize @work_order, policy_class: WorkOrder::DetailPolicy
  end

  def new
    @work_order = WorkOrder.new
    authorize @work_order, policy_class: WorkOrder::DetailPolicy
  end

  def create
    @work_order = WorkOrder.new(work_order_params)
    authorize @work_order, policy_class: WorkOrder::DetailPolicy

    # Logic to be implemented later
  end

  def edit
    authorize @work_order, policy_class: WorkOrder::DetailPolicy
  end

  def update
    authorize @work_order, policy_class: WorkOrder::DetailPolicy

    # Logic to be implemented later
  end

  def destroy
    authorize @work_order, policy_class: WorkOrder::DetailPolicy

    # Logic to be implemented later
  end

  def mark_complete
    authorize @work_order, policy_class: WorkOrder::DetailPolicy

    # Logic to be implemented later
  end

  private

  def set_work_order
    @work_order = WorkOrder.find(params[:id])
  end

  def work_order_params
    params.require(:work_order).permit(
      :block_id,
      :work_order_rate_id,
      :start_date,
      :block_number,
      :block_hectarage,
      :work_order_rate_name,
      :work_order_rate_price,
      :field_conductor_id
    )
  end
end
