# frozen_string_literal: true

class ProductionsController < ApplicationController
  include RansackMultiSort

  before_action :set_production, only: %i[show edit update destroy confirm_delete]
  before_action :load_form_data, only: %i[new create edit update]

  def index
    authorize Production

    apply_ransack_search(policy_scope(Production).includes(:block, :mill).ordered)
    @pagy, @productions = paginate_results(@q.result)
  end

  def show
    authorize @production

    if turbo_frame_request?
      render layout: false
    else
      redirect_to productions_path
    end
  end

  def new
    @production = Production.new
    authorize @production

    if turbo_frame_request?
      render layout: false
    else
      redirect_to productions_path
    end
  end

  def create
    @production = Production.new(production_params)
    authorize @production

    respond_to do |format|
      if @production.save
        format.turbo_stream do
          flash.now[:notice] = 'Production record was successfully created.'
        end
        format.html { redirect_to productions_path, notice: 'Production record was successfully created.' }
      else
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace('modal', partial: 'productions/form', locals: { production: @production }),
                 status: :unprocessable_entity
        end
        format.html { render :new, status: :unprocessable_entity }
      end
    end
  end

  def edit
    authorize @production

    if turbo_frame_request?
      render layout: false
    else
      redirect_to productions_path
    end
  end

  def update
    authorize @production

    respond_to do |format|
      if @production.update(production_params)
        format.turbo_stream do
          flash.now[:notice] = 'Production record was successfully updated.'
        end
        format.html { redirect_to productions_path, notice: 'Production record was successfully updated.' }
      else
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace('modal', partial: 'productions/form', locals: { production: @production }),
                 status: :unprocessable_entity
        end
        format.html { render :edit, status: :unprocessable_entity }
      end
    end
  end

  # GET /productions/:id/confirm_delete
  def confirm_delete
    authorize @production

    # Only render the modal if Turbo frame request
    if turbo_frame_request?
      render layout: false
    else
      redirect_to productions_path
    end
  end

  def destroy
    authorize @production

    respond_to do |format|
      if @production.destroy
        format.turbo_stream do
          flash.now[:notice] = 'Production record was successfully deleted.'
        end
        format.html { redirect_to productions_path, notice: 'Production record was successfully deleted.' }
      else
        format.turbo_stream do
          flash.now[:alert] = @production.errors.full_messages.join(', ')
          render turbo_stream: [
            turbo_stream.update('flash', partial: 'layouts/flash')
          ]
        end
        format.html { redirect_to productions_path, alert: @production.errors.full_messages.join(', ') }
      end
    end
  end

  private

  def set_production
    @production = Production.find(params[:id])
  end

  def load_form_data
    @blocks = Block.order(:block_number)
    @mills = Mill.active.ordered
  end

  def production_params
    params.require(:production).permit(:date, :block_id, :ticket_estate_no, :ticket_mill_no, :mill_id, :total_bunches, :total_weight_ton)
  end
end
