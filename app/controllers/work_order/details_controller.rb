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
    result = service.call(draft: draft)

    result.either(
      lambda { |work_order|
        message = draft ? 'Work order was saved as draft.' : 'Work order was successfully submitted.'
        redirect_to work_order_detail_path(work_order), notice: message
      },
      lambda { |errors|
        flash.now[:alert] = errors.is_a?(Array) ? errors.join(', ') : errors
        render :new, status: :unprocessable_entity
      }
    )
  end

  def edit
    authorize @work_order, policy_class: WorkOrder::DetailPolicy
  end

  def update
    authorize @work_order, policy_class: WorkOrder::DetailPolicy

    service = WorkOrderServices::UpdateService.new(@work_order, work_order_params)
    submit = params[:submit].present?
    result = service.call(submit: submit)

    result.either(
      lambda { |work_order|
        message = submit ? 'Work order was successfully submitted for approval.' : 'Work order was successfully updated.'
        redirect_to work_order_detail_path(work_order), notice: message
      },
      lambda { |errors|
        flash.now[:alert] = errors.is_a?(Array) ? errors.join(', ') : errors
        render :edit, status: :unprocessable_entity
      }
    )
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
    result = service.call

    result.either(
      ->(message) { redirect_to work_order_detail_path(@work_order), notice: message },
      ->(error) { redirect_to work_order_detail_path(@work_order), alert: error }
    )
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
