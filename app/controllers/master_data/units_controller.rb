# frozen_string_literal: true

module MasterData
  class UnitsController < ApplicationController
    include RansackMultiSort

    before_action :set_unit, only: %i[show edit update destroy]

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
    end

    def create
      @unit = Unit.new(unit_params)
      authorize @unit, policy_class: MasterData::UnitPolicy

      if @unit.save
        redirect_to master_data_unit_path(@unit), notice: 'Unit was successfully created.'
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
      authorize @unit, policy_class: MasterData::UnitPolicy
    end

    def update
      authorize @unit, policy_class: MasterData::UnitPolicy

      if @unit.update(unit_params)
        redirect_to master_data_unit_path(@unit), notice: 'Unit was successfully updated.'
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      authorize @unit, policy_class: MasterData::UnitPolicy

      @unit.destroy!
      redirect_to master_data_units_url, notice: 'Unit was successfully deleted.'
    end

    private

    def set_unit
      @unit = Unit.find(params[:id])
    end

    def unit_params
      params.require(:unit).permit(
        :name,
        :unit_type
      )
    end
  end
end
