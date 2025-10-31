# frozen_string_literal: true

class WorkersController < ApplicationController
  before_action :set_worker, only: %i[show edit update destroy]

  def index
    @workers = policy_scope(Worker)
    authorize Worker
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
      :description
    )
  end
end
