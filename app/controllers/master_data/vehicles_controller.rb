# frozen_string_literal: true

module MasterData
  class VehiclesController < ApplicationController
    include RansackMultiSort

    before_action :set_vehicle, only: %i[show edit update destroy]

    def index
      authorize Vehicle, policy_class: MasterData::VehiclePolicy

      apply_ransack_search(policy_scope(Vehicle, policy_scope_class: MasterData::VehiclePolicy::Scope).order(id: :desc))
      @pagy, @vehicles = paginate_results(@q.result)
    end

    def show
      authorize @vehicle, policy_class: MasterData::VehiclePolicy
    end

    def new
      @vehicle = Vehicle.new
      authorize @vehicle, policy_class: MasterData::VehiclePolicy
    end

    def create
      @vehicle = Vehicle.new(vehicle_params)
      authorize @vehicle, policy_class: MasterData::VehiclePolicy

      # Logic to be implemented later
    end

    def edit
      authorize @vehicle, policy_class: MasterData::VehiclePolicy
    end

    def update
      authorize @vehicle, policy_class: MasterData::VehiclePolicy

      # Logic to be implemented later
    end

    def destroy
      authorize @vehicle, policy_class: MasterData::VehiclePolicy

      # Logic to be implemented later
    end

    private

    def set_vehicle
      @vehicle = Vehicle.find(params[:id])
    end

    def vehicle_params
      params.require(:vehicle).permit(
        :vehicle_number,
        :vehicle_model,
        :status
      )
    end
  end
end
