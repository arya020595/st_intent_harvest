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
          format.turbo_stream do
            flash.now[:notice] = 'Work order rate was successfully created.'
          end
          format.html do
            redirect_to master_data_work_order_rates_path, notice: 'Work order rate was successfully created.'
          end
        else
          format.turbo_stream do
            render turbo_stream: turbo_stream.replace('modal', partial: 'master_data/work_order_rates/form', locals: { work_order_rate: @work_order_rate }),
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
          format.turbo_stream do
            flash.now[:notice] = 'Work order rate was successfully updated.'
          end
          format.html do
            redirect_to master_data_work_order_rates_path, notice: 'Work order rate was successfully updated.'
          end
        else
          format.turbo_stream do
            render turbo_stream: turbo_stream.replace('modal', partial: 'master_data/work_order_rates/form', locals: { work_order_rate: @work_order_rate }),
                   status: :unprocessable_entity
          end
          format.html { render :edit, status: :unprocessable_entity }
        end
      end
    end

    def destroy
      authorize @work_order_rate, policy_class: MasterData::WorkOrderRatePolicy

      respond_to do |format|
        if @work_order_rate.destroy
          format.turbo_stream do
            flash.now[:notice] = 'Work order rate was successfully deleted.'
          end
          format.html do
            redirect_to master_data_work_order_rates_url, notice: 'Work order rate was successfully deleted.'
          end
        else
          format.turbo_stream do
            flash.now[:alert] = "Unable to delete work order rate: #{@work_order_rate.errors.full_messages.join(', ')}"
            render :destroy, status: :unprocessable_entity
          end
          format.html do
            redirect_to master_data_work_order_rates_url,
                        alert: "Unable to delete work order rate: #{@work_order_rate.errors.full_messages.join(', ')}"
          end
        end
      end
    end

    private

    def set_work_order_rate
      @work_order_rate = WorkOrderRate.find(params[:id])
    end

    def work_order_rate_params
      params.require(:work_order_rate).permit(
        :work_order_name,
        :rate,
        :unit_id,
        :currency
      )
    end
  end
end
