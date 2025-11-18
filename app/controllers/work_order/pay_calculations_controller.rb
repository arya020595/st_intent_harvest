# frozen_string_literal: true

class WorkOrder::PayCalculationsController < ApplicationController
  include RansackMultiSort

  before_action :set_pay_calculation, only: %i[show edit update destroy]

  def index
    authorize PayCalculation, policy_class: WorkOrder::PayCalculationPolicy

    apply_ransack_search(policy_scope(PayCalculation,
                                      policy_scope_class: WorkOrder::PayCalculationPolicy::Scope).order(id: :desc))

    @pagy, @pay_calculations = paginate_results(@q.result)
  end

  def show
    authorize @pay_calculation, policy_class: WorkOrder::PayCalculationPolicy

    apply_ransack_search(@pay_calculation.pay_calculation_details.includes(:worker).order(id: :asc))

    @pagy, @pay_calculation_details = paginate_results(@q.result)
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
