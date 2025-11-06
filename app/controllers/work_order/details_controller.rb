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
    service = WorkOrderServices::CreateService.new(work_order_params)
    @work_order = service.work_order
    authorize @work_order, policy_class: WorkOrder::DetailPolicy

    draft = params[:draft].present?

    if service.call(draft: draft)
      message = draft ? 'Work order was saved as draft.' : 'Work order was successfully submitted.'
      redirect_to work_order_detail_path(@work_order), notice: message
    else
      flash.now[:alert] =
        service.errors.any? ? service.errors.join(', ') : 'There was an error creating the work order. Please check the form.'
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    authorize @work_order, policy_class: WorkOrder::DetailPolicy
  end

  def update
    authorize @work_order, policy_class: WorkOrder::DetailPolicy

    service = WorkOrderServices::UpdateService.new(@work_order, work_order_params)
    submit = params[:submit].present?

    if service.call(submit: submit)
      message = submit ? 'Work order was successfully submitted for approval.' : 'Work order was successfully updated.'
      redirect_to work_order_detail_path(@work_order), notice: message
    else
      flash.now[:alert] =
        service.errors.any? ? service.errors.join(', ') : 'There was an error updating the work order. Please check the form.'
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @work_order, policy_class: WorkOrder::DetailPolicy

    if @work_order.destroy
      redirect_to work_order_details_path, notice: 'Work order was successfully deleted.'
    else
      redirect_to work_order_detail_path(@work_order), alert: 'There was an error deleting the work order.'
    end
  end

  def mark_complete
    authorize @work_order, policy_class: WorkOrder::DetailPolicy

    service = WorkOrderServices::MarkCompleteService.new(@work_order)

    if service.call
      redirect_to work_order_detail_path(@work_order), notice: service.message
    else
      redirect_to work_order_detail_path(@work_order), alert: service.message
    end
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
      :field_conductor_id,
      work_order_workers_attributes: %i[
        id
        worker_id
        work_area_size
        rate
        amount
        remarks
        _destroy
      ],
      work_order_items_attributes: %i[
        id
        inventory_id
        amount_used
        _destroy
      ]
    )
  end
end
