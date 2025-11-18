# frozen_string_literal: true

module WorkOrder
  class DetailsController < ApplicationController
    include RansackMultiSort
    include ResponseHandling

    before_action :set_work_order, only: %i[show edit update destroy mark_complete]

    def index
      authorize WorkOrder, policy_class: WorkOrder::DetailPolicy

      apply_ransack_search(policy_scope(WorkOrder, policy_scope_class: WorkOrder::DetailPolicy::Scope).order(id: :desc))
      @pagy, @work_orders = paginate_results(@q.result)
    end

    def show
      authorize @work_order, policy_class: WorkOrder::DetailPolicy

      # Load the latest amendment history for display
      @amendment_history = @work_order.latest_amendment_history

      # If the work order is completed, render the completed view layout
      return unless @work_order.work_order_status == 'completed'

      # Compute history values once to avoid N+1 queries in partials
      @verification_history = @work_order.work_order_histories.where(action: 'approve').order(created_at: :desc).first
      @completion_history = @work_order.work_order_histories.where(action: 'mark_complete').order(created_at: :desc).first

      render :show_completed
    end

    def new
      @work_order = WorkOrder.new
      authorize @work_order, policy_class: WorkOrder::DetailPolicy
      @workers = Worker.active
      @inventories = Inventory.includes(:category, :unit).all
    end

    def create
      service = WorkOrderServices::CreateService.new(work_order_params)
      @work_order = service.work_order
      authorize @work_order, policy_class: WorkOrder::DetailPolicy
      @workers = Worker.active
      @inventories = Inventory.includes(:category, :unit).all

      draft = params[:draft].present?
      result = service.call(draft: draft)

      handle_result(
        result,
        success_path: ->(data) { work_order_detail_path(data[:work_order]) },
        error_action: :new
      )
    end

    def edit
      authorize @work_order, policy_class: WorkOrder::DetailPolicy
      @workers = Worker.active
      @inventories = Inventory.includes(:category, :unit).all
    end

    def update
      authorize @work_order, policy_class: WorkOrder::DetailPolicy
      @workers = Worker.active
      @inventories = Inventory.includes(:category, :unit).all

      service = WorkOrderServices::UpdateService.new(@work_order, work_order_params)
      submit = params[:submit].present?
      result = service.call(submit: submit)

      handle_result(
        result,
        success_path: work_order_detail_path(@work_order),
        error_action: :edit
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

      handle_result(
        result,
        success_path: work_order_detail_path(@work_order),
        error_path: work_order_detail_path(@work_order)
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
        :work_month,
        :field_conductor_id,
        work_order_workers_attributes: %i[
          id
          worker_id
          work_area_size
          work_days
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
end
