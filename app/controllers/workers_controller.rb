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
    # When requested inside a Turbo Frame (modal), render without layout
    render layout: false if turbo_frame_request?
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
        # Re-render the form in the frame without layout for validation errors
        format.turbo_stream { render :new, status: :unprocessable_entity, layout: false }
        format.html { render :new, status: :unprocessable_entity }
      end
    end
  end

  def edit
    authorize @worker
    # Render modal body only when loaded via Turbo Frame
    render layout: false if turbo_frame_request?
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
        format.turbo_stream { render :edit, status: :unprocessable_entity, layout: false }
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
          render turbo_stream: [
            turbo_stream.replace('flash-messages', partial: 'shared/flash')
          ]
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
