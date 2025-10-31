# frozen_string_literal: true

class PayslipsController < ApplicationController
  before_action :set_payslip, only: %i[show]

  def index
    @payslips = policy_scope(PayCalculation, policy_scope_class: PayslipPolicy::Scope)
    authorize PayCalculation, policy_class: PayslipPolicy
  end

  def show
    authorize @payslip, policy_class: PayslipPolicy
  end

  def export
    authorize PayCalculation, :export?, policy_class: PayslipPolicy

    # Logic to be implemented later
    # Export payslips to CSV/PDF
  end

  private

  def set_payslip
    @payslip = PayCalculation.find(params[:id])
  end
end
