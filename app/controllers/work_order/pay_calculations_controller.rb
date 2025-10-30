# frozen_string_literal: true

module WorkOrder
  class PayCalculationsController < ApplicationController
    before_action :set_pay_calculation, only: %i[show edit update destroy]

    def index
      @pay_calculations = policy_scope([:work_order, PayCalculation])
      authorize [:work_order, PayCalculation], :index?
    end

    def show
      authorize [:work_order, @pay_calculation], :show?
    end

    def new
      @pay_calculation = PayCalculation.new
      authorize [:work_order, @pay_calculation], :new?
    end

    def create
      @pay_calculation = PayCalculation.new(pay_calculation_params)
      authorize [:work_order, @pay_calculation], :create?

      # Logic to be implemented later
    end

    def edit
      authorize [:work_order, @pay_calculation], :edit?
    end

    def update
      authorize [:work_order, @pay_calculation], :update?

      # Logic to be implemented later
    end

    def destroy
      authorize [:work_order, @pay_calculation], :destroy?

      # Logic to be implemented later
    end

    private

    def set_pay_calculation
      @pay_calculation = PayCalculation.find(params[:id])
    end

    def pay_calculation_params
      params.require(:pay_calculation).permit(
        :work_order_id,
        :calculation_date,
        :total_amount,
        :status
      )
    end
  end
end
