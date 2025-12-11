# frozen_string_literal: true

module WorkOrders
  class MandaysController < ApplicationController
    before_action :set_manday, only: %i[show edit update destroy]

    # GET /work_orders/mandays
    def index
      authorize Manday, policy_class: WorkOrders::MandayPolicy
      @q = Manday.ransack(params[:q])
      mandays_scope = @q.result.order(work_month: :desc)
      @pagy, @mandays = pagy(mandays_scope)
    end

    # GET /work_orders/mandays/new
    def new
      authorize Manday, policy_class: WorkOrders::MandayPolicy
      @manday = Manday.new
      build_worker_rows
    end

    # GET /work_orders/mandays/:id/edit
    def edit
      authorize Manday, policy_class: WorkOrders::MandayPolicy
      set_manday
      build_worker_rows
    end

    # POST /work_orders/mandays
    def create
      authorize Manday, policy_class: WorkOrders::MandayPolicy
      @manday = Manday.new(manday_params_with_date)

      if @manday.save
        redirect_to work_orders_mandays_path, notice: "Manday was successfully created."
      else
        flash.now[:alert] = "Error creating manday."
        build_worker_rows
        render :new, status: :unprocessable_entity
      end
    end

    # PATCH /work_orders/mandays/:id
    def update
      authorize Manday, policy_class: WorkOrders::MandayPolicy
      if @manday.update(manday_params_with_date)
        redirect_to work_orders_mandays_path, notice: "Manday was successfully updated."
      else
        flash.now[:alert] = "Error updating manday."
        build_worker_rows
        render :edit, status: :unprocessable_entity
      end
    end

    # DELETE /work_orders/mandays/:id
    def destroy
      authorize Manday, policy_class: WorkOrders::MandayPolicy
      @manday.destroy
      redirect_to work_orders_mandays_path, notice: "Manday was successfully deleted."
    end

    private

    def set_manday
      @manday = Manday.find(params[:id])
    end

    # Build missing worker rows for form
    def build_worker_rows
      @workers = Worker.active
      existing_names = @manday.mandays_workers.map(&:worker_name)
      (@workers.pluck(:name) - existing_names).each do |name|
        @manday.mandays_workers.build(worker_name: name)
      end
    end


    # Strong params + convert work_month string to Date
    def manday_params_with_date
      mp = params.require(:manday).permit(
        :work_month,
        mandays_workers_attributes: %i[id worker_name days remarks _destroy]
      )

      if mp[:work_month].present?
        year, month = mp[:work_month].split('-').map(&:to_i)
        mp[:work_month] = Date.new(year, month, 1) rescue nil
      end

      # Remove workers with 0 or blank days
      if mp[:mandays_workers_attributes]
        mp[:mandays_workers_attributes].delete_if do |_k, w|
          w["days"].blank? || w["days"].to_i <= 0
        end
      end

      mp
    end
  end
end
