# frozen_string_literal: true

module MasterData
  class WorkOrderRatesController < ApplicationController
    include RansackMultiSort
    include SoftDeletableController

    before_action :set_work_order_rate, only: %i[show edit update destroy confirm_delete]

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

      if turbo_frame_request?
        render layout: false
      else
        redirect_to master_data_work_order_rates_path
      end
    end

    def create
      @work_order_rate = WorkOrderRate.new(work_order_rate_params)
      authorize @work_order_rate, policy_class: MasterData::WorkOrderRatePolicy

      respond_to do |format|
        if @work_order_rate.save
          format.turbo_stream { flash.now[:notice] = 'Work order rate was successfully created.' }
          format.html do
            redirect_to master_data_work_order_rates_path, notice: 'Work order rate was successfully created.'
          end
        else
          format.turbo_stream do
            render turbo_stream: turbo_stream.replace(
              'modal',
              partial: 'master_data/work_order_rates/form',
              locals: { work_order_rate: @work_order_rate }
            ),
                   status: :unprocessable_entity
          end
          format.html { render :new, status: :unprocessable_entity }
        end
      end
    end

    def edit
      authorize @work_order_rate, policy_class: MasterData::WorkOrderRatePolicy

      if turbo_frame_request?
        render layout: false
      else
        redirect_to master_data_work_order_rates_path
      end
    end

    def update
      authorize @work_order_rate, policy_class: MasterData::WorkOrderRatePolicy

      respond_to do |format|
        if @work_order_rate.update(work_order_rate_params)
          format.turbo_stream { flash.now[:notice] = 'Work order rate was successfully updated.' }
          format.html do
            redirect_to master_data_work_order_rates_path, notice: 'Work order rate was successfully updated.'
          end
        else
          format.turbo_stream do
            render turbo_stream: turbo_stream.replace(
              'modal',
              partial: 'master_data/work_order_rates/form',
              locals: { work_order_rate: @work_order_rate }
            ),
                   status: :unprocessable_entity
          end
          format.html { render :edit, status: :unprocessable_entity }
        end
      end
    end

    def confirm_delete
      if @work_order_rate.nil?
        if turbo_frame_request?
          render turbo_stream: turbo_stream.replace('modal', ''), status: :ok
        else
          redirect_to master_data_work_order_rates_path
        end
        return
      end

      authorize @work_order_rate, policy_class: MasterData::WorkOrderRatePolicy

      if turbo_frame_request?
        render layout: false
      else
        redirect_to master_data_work_order_rates_path
      end
    end

    def destroy
      authorize @work_order_rate, policy_class: MasterData::WorkOrderRatePolicy
      super
    end

    def restore
      @work_order_rate = WorkOrderRate.with_discarded.find(params[:id])
      authorize @work_order_rate, policy_class: MasterData::WorkOrderRatePolicy
      super
    end

    private

    def set_work_order_rate
      @work_order_rate = WorkOrderRate.find_by(id: params[:id])
      return if @work_order_rate.present?

      if turbo_frame_request?
        # For missing record in Turbo modal → clear the modal
        render turbo_stream: turbo_stream.replace('modal', ''), status: :ok
      else
        # Normal HTML request → redirect to index safely
        redirect_to master_data_work_order_rates_path
      end
    end

    def work_order_rate_params
      params.require(:work_order_rate).permit(
        :work_order_name,
        :rate,
        :unit_id,
        :currency,
        :work_order_rate_type
      )
    end
  end
end
