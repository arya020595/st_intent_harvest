# frozen_string_literal: true

class ProductionsController < ApplicationController
  include RansackMultiSort
  include ExportHandling

  before_action :set_production, only: %i[show edit update destroy confirm_delete]
  before_action :load_form_data, only: %i[new create edit update]

  def index
    authorize Production

    apply_ransack_search(policy_scope(Production).kept.includes(:block, :mill).ordered)
    @pagy, @productions = paginate_results(@q.result)

    respond_to do |format|
      format.html
      format.csv { export_csv }
      format.pdf { export_pdf }
    end
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
      if @production.discard
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
    @production = Production.with_discarded.find(params[:id])
  end

  def load_form_data
    @blocks = Block.kept.order(:block_number)
    @mills = Mill.kept.ordered
  end

  def production_params
    params.require(:production).permit(:date, :block_id, :ticket_estate_no, :ticket_mill_no, :mill_id, :total_bunches,
                                       :total_weight_ton)
  end

  # Export methods - delegate to SOLID services with dry-monads
  #
  # NOTE: extra_locals is ONLY used by PDF exports, NOT CSV exports
  # CSV exports ignore extra_locals because they generate plain text without templates
  # PDF exports use extra_locals to pass variables to the HTML template
  #
  # See ExportHandling concern documentation for parameter differences
  def export_csv
    records = @q.result.includes(:block, :mill).ordered

    # NOTE: extra_locals parameter is NOT used by CsvExporter
    # Include it here for consistency, but it will be silently ignored
    # For CSV configuration, subclass must implement #headers and #row_data methods
    handle_csv_export(
      ProductionServices::ExportCsvService,
      records,
      error_path: productions_path
    )
  end

  def export_pdf
    records = @q.result.includes(:block, :mill).ordered
    # Pre-calculate totals to avoid N+1 queries in the view
    totals = {
      total_bunches: records.sum(:total_bunches),
      total_weight_ton: records.sum(:total_weight_ton)
    }

    # Pre-fetch filter data to avoid database queries in the view
    filter_data = {
      mill: params.dig(:q, :mill_id_eq).present? ? Mill.find_by(id: params.dig(:q, :mill_id_eq)) : nil,
      block: params.dig(:q, :block_id_eq).present? ? Block.find_by(id: params.dig(:q, :block_id_eq)) : nil
    }

    # extra_locals are PASSED to PDF template for rendering
    # These variables are available in app/views/productions/index.pdf.erb
    handle_pdf_export(
      ProductionServices::ExportPdfService,
      records,
      error_path: productions_path,
      extra_locals: { totals: totals, filter_data: filter_data }
    )
  end
end
