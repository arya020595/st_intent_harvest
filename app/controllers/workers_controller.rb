# frozen_string_literal: true

class WorkersController < ApplicationController
  include RansackMultiSort

  before_action :set_worker, only: %i[show edit update destroy]

  def index
    authorize Worker

    apply_ransack_search(policy_scope(Worker).order(id: :desc))
    @pagy, @workers = paginate_results(@q.result)
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

    if @worker.save
      redirect_to @worker, notice: 'Worker was successfully created.'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    authorize @worker
  end

  def update
    authorize @worker

    if @worker.update(worker_params)
      redirect_to @worker, notice: 'Worker was successfully updated.'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @worker

    @worker.destroy!
    redirect_to workers_url, notice: 'Worker was successfully deleted.'
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
