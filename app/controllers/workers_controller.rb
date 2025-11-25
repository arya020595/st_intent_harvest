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

    # Base query for completed work orders
    completed_work_orders = @worker.work_order_workers
                                   .joins(work_order: :work_order_rate)
                                   .where(work_orders: { work_order_status: 'completed' })

    # Ransack search for previous work orders
    @q = completed_work_orders.order(work_orders: { created_at: :desc }).ransack(params[:q])
    @pagy, @work_order_workers = paginate_results(@q.result)

    # Calculate totals from ALL completed work orders (not just filtered results)
    @total_completed_work_orders = completed_work_orders.distinct.count(:work_order_id)
    @total_working_days = completed_work_orders.select('DATE(work_orders.created_at) as work_date')
                                               .distinct
                                               .count(:work_date)
  end

  def new
    @worker = Worker.new
    authorize @worker

    if turbo_frame_request?
      render layout: false
    else
      redirect_to workers_path
    end
  end

  def create
    @worker = Worker.new(worker_params)
    authorize @worker

    respond_to do |format|
      if @worker.save
        format.turbo_stream do
          # Use flash.now so it renders in the same request
          flash.now[:notice] = 'Worker was successfully created.'
        end
        format.html { redirect_to workers_path, notice: 'Worker was successfully created.' }
      else
        # Re-render the form in the modal for validation errors
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace('modal', partial: 'workers/form', locals: { worker: @worker }),
                 status: :unprocessable_entity
        end
        format.html { render :new, status: :unprocessable_entity }
      end
    end
  end

  def edit
    authorize @worker

    if turbo_frame_request?
      render layout: false
    else
      redirect_to workers_path
    end
  end

  def update
    authorize @worker

    respond_to do |format|
      if @worker.update(worker_params)
        format.turbo_stream do
          flash.now[:notice] = 'Worker was successfully updated.'
        end
        format.html { redirect_to workers_path, notice: 'Worker was successfully updated.' }
      else
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace('modal', partial: 'workers/form', locals: { worker: @worker }),
                 status: :unprocessable_entity
        end
        format.html { render :edit, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    authorize @worker

    respond_to do |format|
      if @worker.destroy
        format.turbo_stream do
          flash.now[:notice] = 'Worker was successfully deleted.'
        end
        format.html { redirect_to workers_url, notice: 'Worker was successfully deleted.' }
      else
        format.turbo_stream do
          flash.now[:alert] = "Unable to delete worker: #{@worker.errors.full_messages.join(', ')}"
          render turbo_stream: turbo_stream.replace('flash', partial: 'shared/flash'), status: :unprocessable_entity
        end
        format.html do
          redirect_to workers_url, alert: "Unable to delete worker: #{@worker.errors.full_messages.join(', ')}"
        end
      end
    end
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
