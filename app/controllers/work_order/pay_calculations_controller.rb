# frozen_string_literal: true

module WorkOrder
  class PayCalculationsController < ApplicationController
    before_action :set_work_order, only: %i[show edit update destroy]

    def index
      @work_orders = policy_scope(
        WorkOrder,
        policy_scope_class: WorkOrder::PayCalculationPolicy::Scope
      )
      authorize WorkOrder, policy_class: WorkOrder::PayCalculationPolicy
    end

    def show
      authorize @work_order, policy_class: WorkOrder::PayCalculationPolicy
    end

    def new
      @work_order = WorkOrder.new
      authorize @work_order, policy_class: WorkOrder::PayCalculationPolicy
    end

    def create
      @work_order = WorkOrder.new(work_order_params)
      authorize @work_order, policy_class: WorkOrder::PayCalculationPolicy

      # Logic to be implemented later
    end

    def edit
      authorize @work_order, policy_class: WorkOrder::PayCalculationPolicy
    end

    def update
      authorize @work_order, policy_class: WorkOrder::PayCalculationPolicy

      # Logic to be implemented later
    end

    def destroy
      authorize @work_order, policy_class: WorkOrder::PayCalculationPolicy

      # Logic to be implemented later
    end

    private

    def set_work_order
      @work_order = WorkOrder.find(params[:id])
    end

    def work_order_params
      params.require(:work_order).permit(
        :calculation_date,
        :total_amount,
        :status
      )
    end
  end
end
