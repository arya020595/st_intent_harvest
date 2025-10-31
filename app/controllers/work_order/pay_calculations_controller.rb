# frozen_string_literal: true

class WorkOrder::PayCalculationsController < ApplicationController
  before_action :set_pay_calculation, only: %i[show edit update destroy]

  def index
    @pay_calculations = policy_scope(
      PayCalculation,
      policy_scope_class: WorkOrder::PayCalculationPolicy::Scope
    )
    authorize PayCalculation, policy_class: WorkOrder::PayCalculationPolicy
  end

  def show
    authorize @pay_calculation, policy_class: WorkOrder::PayCalculationPolicy
  end

  def new
    @pay_calculation = PayCalculation.new
    authorize @pay_calculation, policy_class: WorkOrder::PayCalculationPolicy
  end

  def create
    @pay_calculation = PayCalculation.new(pay_calculation_params)
    authorize @pay_calculation, policy_class: WorkOrder::PayCalculationPolicy

    # Logic to be implemented later
  end

  def edit
    authorize @pay_calculation, policy_class: WorkOrder::PayCalculationPolicy
  end

  def update
    authorize @pay_calculation, policy_class: WorkOrder::PayCalculationPolicy

    # Logic to be implemented later
  end

  def destroy
    authorize @pay_calculation, policy_class: WorkOrder::PayCalculationPolicy

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
