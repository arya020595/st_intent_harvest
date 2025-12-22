# frozen_string_literal: true

module MasterData
  class UnitsController < ApplicationController
    include RansackMultiSort
    include SoftDeletableController

    before_action :set_unit, only: %i[show edit update destroy confirm_delete]

    def index
      authorize Unit, policy_class: MasterData::UnitPolicy

      apply_ransack_search(policy_scope(Unit, policy_scope_class: MasterData::UnitPolicy::Scope).order(id: :desc))
      @pagy, @units = paginate_results(@q.result)
    end

    def show
      authorize @unit, policy_class: MasterData::UnitPolicy
    end

    def new
      @unit = Unit.new
      authorize @unit, policy_class: MasterData::UnitPolicy

      if turbo_frame_request?
        render layout: false
      else
        redirect_to master_data_units_path
      end
    end

    def create
      @unit = Unit.new(unit_params)
      authorize @unit, policy_class: MasterData::UnitPolicy

      respond_to do |format|
        if @unit.save
          format.turbo_stream do
            flash.now[:notice] = 'Unit was successfully created.'
          end
          format.html { redirect_to master_data_units_path, notice: 'Unit was successfully created.' }
        else
          format.turbo_stream do
            render turbo_stream: turbo_stream.replace('modal', partial: 'master_data/units/form', locals: { unit: @unit }),
                   status: :unprocessable_entity
          end
          format.html { render :new, status: :unprocessable_entity }
        end
      end
    end

    def edit
      authorize @unit, policy_class: MasterData::UnitPolicy

      if turbo_frame_request?
        render layout: false
      else
        redirect_to master_data_units_path
      end
    end

    def update
      authorize @unit, policy_class: MasterData::UnitPolicy

      respond_to do |format|
        if @unit.update(unit_params)
          format.turbo_stream do
            flash.now[:notice] = 'Unit was successfully updated.'
          end
          format.html { redirect_to master_data_units_path, notice: 'Unit was successfully updated.' }
        else
          format.turbo_stream do
            render turbo_stream: turbo_stream.replace('modal', partial: 'master_data/units/form', locals: { unit: @unit }),
                   status: :unprocessable_entity
          end
          format.html { render :edit, status: :unprocessable_entity }
        end
      end
    end


   def confirm_delete
      authorize @unit, policy_class: MasterData::UnitPolicy

      # Only show the modal
      if turbo_frame_request?
        render layout: false
      else
        redirect_to master_data_unit_path
      end
    end


    def destroy
      authorize @unit, policy_class: MasterData::UnitPolicy
      super
    end

    def restore
      @unit = Unit.with_discarded.find(params[:id])
      authorize @unit, policy_class: MasterData::UnitPolicy
      super
    end

    private

    def set_unit
      @unit = Unit.find_by(id: params[:id])
      return if @unit.present?

      if turbo_frame_request?
        render turbo_stream: turbo_stream.replace("modal", ""), status: :ok
      else
        redirect_to master_data_units_path
      end
    end


    def unit_params
      params.require(:unit).permit(
        :name,
        :unit_type
      )
    end
  end
end
