# frozen_string_literal: true

class PayslipsController < ApplicationController
  before_action :set_payslip, only: %i[show]

  def index
    @payslips = policy_scope(Payslip)
    authorize Payslip
  end

  def show
    authorize @payslip
  end

  def export
    authorize Payslip, :export?

    # Logic to be implemented later
    # Export payslips to CSV/PDF
  end

  private

  def set_payslip
    @payslip = Payslip.find(params[:id])
  end
end
