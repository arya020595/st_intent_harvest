# frozen_string_literal: true

class WorkersController < ApplicationController
  before_action :set_worker, only: %i[show edit update destroy]

  def index
    authorize Worker

    @q = policy_scope(Worker).ransack(params[:q])
    per_page = params[:per_page].present? ? params[:per_page].to_i : 10
    @pagy, @workers = pagy(@q.result, limit: per_page)
  end

  def show
    authorize @worker
  end

  def new
    @worker = Worker.new
    authorize @worker
  end

  def create
    @worker = Worker.new(worker_params)
    authorize @worker

    # Logic to be implemented later
  end

  def edit
    authorize @worker
  end

  def update
    authorize @worker

    # Logic to be implemented later
  end

  def destroy
    authorize @worker

    # Logic to be implemented later
  end

  private

  def set_worker
    @worker = Worker.find(params[:id])
  end

  def worker_params
    params.require(:worker).permit(
      :name,
      :worker_type,
      :gender,
      :is_active,
      :hired_date,
      :nationality,
      :identity_number
    )
  end
end
