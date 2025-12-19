# frozen_string_literal: true

module WorkOrders
  class DetailsController < ApplicationController
    include RansackMultiSort
    include ResponseHandling

    before_action :set_work_order, only: %i[show edit update destroy mark_complete confirm_delete]

    def index
      authorize WorkOrder, policy_class: WorkOrders::DetailPolicy

      apply_ransack_search(policy_scope(WorkOrder,
                                        policy_scope_class: WorkOrders::DetailPolicy::Scope).order(id: :desc))
      @pagy, @work_orders = paginate_results(@q.result)
    end

    def show
      authorize @work_order, policy_class: WorkOrders::DetailPolicy

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
      authorize @work_order, policy_class: WorkOrders::DetailPolicy
      @workers = Worker.active
      @inventories = Inventory.includes(:category, :unit).all
      @vehicles = Vehicle.all
      @units = Unit.all
      @is_field_conductor = current_user.field_conductor?
    end

    def create
      service = WorkOrderServices::CreateService.new(work_order_params)
      @work_order = service.work_order
      authorize @work_order, policy_class: WorkOrders::DetailPolicy
      @workers = Worker.active
      @inventories = Inventory.includes(:category, :unit).all
      @vehicles = Vehicle.all
      @units = Unit.all

      draft = params[:draft].present?
      result = service.call(draft: draft)

      handle_result(
        result,
        success_path: ->(data) { work_orders_detail_path(data[:work_order]) },
        error_action: :new
      )
    end

    def edit
      authorize @work_order, policy_class: WorkOrders::DetailPolicy
      @workers = Worker.active
      @inventories = Inventory.includes(:category, :unit).all
      @vehicles = Vehicle.all
      @units = Unit.all
      @is_field_conductor = current_user.field_conductor?
    end

    def update
      authorize @work_order, policy_class: WorkOrders::DetailPolicy
      @workers = Worker.active
      @inventories = Inventory.includes(:category, :unit).all
      @vehicles = Vehicle.all
      @units = Unit.all

      service = WorkOrderServices::UpdateService.new(@work_order, work_order_params)
      submit = params[:submit].present?
      result = service.call(submit: submit)

      handle_result(
        result,
        success_path: work_orders_detail_path(@work_order),
        error_action: :edit
      )
    end

    def destroy
      authorize @work_order, policy_class: WorkOrders::DetailPolicy

      if @work_order.destroy
        respond_to do |format|
          format.turbo_stream do
            flash.now[:notice] = 'Work order was successfully deleted.'
          end
          format.html do
            redirect_to work_orders_details_path, notice: 'Work order was successfully deleted.', status: :see_other
          end
        end
      else
        respond_to do |format|
          format.turbo_stream do
            flash.now[:alert] = 'There was an error deleting the work order.'
            render turbo_stream: turbo_stream.update('flash_messages', partial: 'shared/flash')
          end
          format.html do
            redirect_to work_orders_detail_path(@work_order), alert: 'There was an error deleting the work order.',
                                                              status: :see_other
          end
        end
      end
    end

    def mark_complete
      authorize @work_order, policy_class: WorkOrders::DetailPolicy

      service = WorkOrderServices::MarkCompleteService.new(@work_order)
      result = service.call

      handle_result(
        result,
        success_path: work_orders_detail_path(@work_order),
        error_path: work_orders_detail_path(@work_order)
      )
    end

    def confirm_delete
      authorize @work_order, policy_class: WorkOrders::DetailPolicy

      # Only show the modal
      if turbo_frame_request?
        render layout: false
      else
        redirect_to work_orders_details_path
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
        :completion_date,
        :work_month,
        :date_of_usage,
        :field_conductor_id,
        :vehicle_id,
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
          unit_id
          amount_used
          _destroy
        ]
      )
    end
  end
end
