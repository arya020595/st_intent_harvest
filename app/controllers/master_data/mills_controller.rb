# frozen_string_literal: true

module MasterData
  class MillsController < ApplicationController
    include RansackMultiSort

    before_action :set_mill, only: %i[show edit update destroy confirm_delete]

    def index
      authorize Mill, policy_class: MasterData::MillPolicy

      apply_ransack_search(policy_scope(Mill, policy_scope_class: MasterData::MillPolicy::Scope).order(id: :desc))
      @pagy, @mills = paginate_results(@q.result)
    end

    def show
      authorize @mill, policy_class: MasterData::MillPolicy

      if turbo_frame_request?
        render layout: false
      else
        redirect_to master_data_mills_path
      end
    end

    def new
      @mill = Mill.new
      authorize @mill, policy_class: MasterData::MillPolicy

      if turbo_frame_request?
        render layout: false
      else
        redirect_to master_data_mills_path
      end
    end

    def create
      @mill = Mill.new(mill_params)
      authorize @mill, policy_class: MasterData::MillPolicy

      respond_to do |format|
        if @mill.save
          format.turbo_stream do
            flash.now[:notice] = 'Mill was successfully created.'
          end
          format.html { redirect_to master_data_mills_path, notice: 'Mill was successfully created.' }
        else
          format.turbo_stream do
            render turbo_stream: turbo_stream.replace('modal', partial: 'master_data/mills/form', locals: { mill: @mill }),
                   status: :unprocessable_entity
          end
          format.html { render :new, status: :unprocessable_entity }
        end
      end
    end

    def edit
      authorize @mill, policy_class: MasterData::MillPolicy

      if turbo_frame_request?
        render layout: false
      else
        redirect_to master_data_mills_path
      end
    end

    def update
      authorize @mill, policy_class: MasterData::MillPolicy

      respond_to do |format|
        if @mill.update(mill_params)
          format.turbo_stream do
            flash.now[:notice] = 'Mill was successfully updated.'
          end
          format.html { redirect_to master_data_mills_path, notice: 'Mill was successfully updated.' }
        else
          format.turbo_stream do
            render turbo_stream: turbo_stream.replace('modal', partial: 'master_data/mills/form', locals: { mill: @mill }),
                   status: :unprocessable_entity
          end
          format.html { render :edit, status: :unprocessable_entity }
        end
      end
    end

    def destroy
      authorize @mill, policy_class: MasterData::MillPolicy

      respond_to do |format|
        if @mill.discard
          format.turbo_stream do
            flash.now[:notice] = 'Mill was successfully deleted.'
          end
          format.html { redirect_to master_data_mills_path, notice: 'Mill was successfully deleted.' }
        else
          format.turbo_stream do
            flash.now[:alert] = @mill.errors.full_messages.join(', ')
            render turbo_stream: [
              turbo_stream.update('flash', partial: 'layouts/flash')
            ]
          end
          format.html { redirect_to master_data_mills_path, alert: @mill.errors.full_messages.join(', ') }
        end
      end
    end

    # GET /master_data/mills/:id/confirm_delete
    def confirm_delete
      authorize @mill, policy_class: MasterData::MillPolicy

      # Only render the modal if Turbo frame request
      if turbo_frame_request?
        render layout: false
      else
        redirect_to master_data_mills_path
      end
    end

    private

    def set_mill
      @mill = Mill.find(params[:id])
    end

    def mill_params
      params.require(:mill).permit(:name)
    end
  end
end
