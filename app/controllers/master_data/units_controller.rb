# frozen_string_literal: true

module MasterData
  class UnitsController < ApplicationController
    before_action :set_unit, only: %i[show edit update destroy]

    def index
      @units = policy_scope(Unit, policy_scope_class: MasterData::UnitPolicy::Scope)
      authorize Unit, policy_class: MasterData::UnitPolicy
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

      # Logic to be implemented later
    end

    def edit
      authorize @unit, policy_class: MasterData::UnitPolicy
    end

    def update
      authorize @unit, policy_class: MasterData::UnitPolicy

      # Logic to be implemented later
    end

    def destroy
      authorize @unit, policy_class: MasterData::UnitPolicy

      # Logic to be implemented later
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
