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

      if @work_order_rate.save
        redirect_to master_data_work_order_rate_path(@work_order_rate),
                    notice: 'Work order rate was successfully created.'
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
      authorize @work_order_rate, policy_class: MasterData::WorkOrderRatePolicy
    end

    def update
      authorize @work_order_rate, policy_class: MasterData::WorkOrderRatePolicy

      if @work_order_rate.update(work_order_rate_params)
        redirect_to master_data_work_order_rate_path(@work_order_rate),
                    notice: 'Work order rate was successfully updated.'
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      authorize @work_order_rate, policy_class: MasterData::WorkOrderRatePolicy

      @work_order_rate.destroy!
      redirect_to master_data_work_order_rates_url, notice: 'Work order rate was successfully deleted.'
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
