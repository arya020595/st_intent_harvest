# frozen_string_literal: true

module MasterData
  class WorkOrderRatesController < ApplicationController
    include RansackMultiSort

    before_action :set_work_order_rate, only: %i[show edit update destroy]

    def index
      authorize WorkOrderRate, policy_class: MasterData::WorkOrderRatePolicy

      apply_ransack_search(policy_scope(WorkOrderRate,
                                        policy_scope_class: MasterData::WorkOrderRatePolicy::Scope).order(id: :desc))
      @pagy, @work_order_rates = paginate_results(@q.result.includes(:unit))
    end

    def show
      authorize @work_order_rate, policy_class: MasterData::WorkOrderRatePolicy
    end

    def new
      @work_order_rate = WorkOrderRate.new
      authorize @work_order_rate, policy_class: MasterData::WorkOrderRatePolicy
    end

    def create
      @work_order_rate = WorkOrderRate.new(work_order_rate_params)
      authorize @work_order_rate, policy_class: MasterData::WorkOrderRatePolicy

      # Logic to be implemented later
    end

    def edit
      authorize @work_order_rate, policy_class: MasterData::WorkOrderRatePolicy
    end

    def update
      authorize @work_order_rate, policy_class: MasterData::WorkOrderRatePolicy

      # Logic to be implemented later
    end

    def destroy
      authorize @work_order_rate, policy_class: MasterData::WorkOrderRatePolicy

      # Logic to be implemented later
    end

    private

    def set_work_order_rate
      @work_order_rate = WorkOrderRate.find(params[:id])
    end

    def work_order_rate_params
      params.require(:work_order_rate).permit(
        :name,
        :price,
        :unit_id
      )
    end
  end
end
