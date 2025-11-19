# frozen_string_literal: true

module WorkOrders
  class PayCalculationsController < ApplicationController
    include RansackMultiSort

    before_action :set_pay_calculation, only: %i[show edit update destroy]

    def index
      authorize PayCalculation, policy_class: WorkOrders::PayCalculationPolicy

      apply_ransack_search(policy_scope(PayCalculation,
                                        policy_scope_class: WorkOrders::PayCalculationPolicy::Scope).order(id: :desc))

      @pagy, @pay_calculations = paginate_results(@q.result)
    end

    def show
      authorize @pay_calculation, policy_class: WorkOrders::PayCalculationPolicy

      apply_ransack_search(@pay_calculation.pay_calculation_details.includes(:worker).order(id: :asc))

      @pagy, @pay_calculation_details = paginate_results(@q.result)
    end

    def new
      @pay_calculation = PayCalculation.new
      authorize @pay_calculation, policy_class: WorkOrders::PayCalculationPolicy
    end

    def create
      @pay_calculation = PayCalculation.new(pay_calculation_params)
      authorize @pay_calculation, policy_class: WorkOrders::PayCalculationPolicy

      # Logic to be implemented later
    end

    def edit
      authorize @pay_calculation, policy_class: WorkOrders::PayCalculationPolicy
    end

    def update
      authorize @pay_calculation, policy_class: WorkOrders::PayCalculationPolicy

      # Logic to be implemented later
    end

    def destroy
      authorize @pay_calculation, policy_class: WorkOrders::PayCalculationPolicy

      # Logic to be implemented later
    end

    private

    def set_pay_calculation
      @pay_calculation = PayCalculation.find(params[:id])
    end

    def pay_calculation_params
      params.require(:pay_calculation).permit(
        :month_year,
        :overall_total
      )
    end
  end
end
