# frozen_string_literal: true

module MasterData
  class VehiclesController < ApplicationController
    include RansackMultiSort
    include SoftDeletableController

    before_action :set_vehicle, only: %i[show edit update destroy confirm_delete]

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

      if turbo_frame_request?
        render layout: false
      else
        redirect_to master_data_vehicles_path
      end
    end

    def create
      @vehicle = Vehicle.new(vehicle_params)
      authorize @vehicle, policy_class: MasterData::VehiclePolicy

      respond_to do |format|
        if @vehicle.save
          format.turbo_stream do
            flash.now[:notice] = 'Vehicle was successfully created.'
          end
          format.html { redirect_to master_data_vehicles_path, notice: 'Vehicle was successfully created.' }
        else
          format.turbo_stream do
            render turbo_stream: turbo_stream.replace('modal', partial: 'master_data/vehicles/form', locals: { vehicle: @vehicle }),
                   status: :unprocessable_entity
          end
          format.html { render :new, status: :unprocessable_entity }
        end
      end
    end

    def edit
      authorize @vehicle, policy_class: MasterData::VehiclePolicy

      if turbo_frame_request?
        render layout: false
      else
        redirect_to master_data_vehicles_path
      end
    end

    def update
      authorize @vehicle, policy_class: MasterData::VehiclePolicy

      respond_to do |format|
        if @vehicle.update(vehicle_params)
          format.turbo_stream do
            flash.now[:notice] = 'Vehicle was successfully updated.'
          end
          format.html { redirect_to master_data_vehicles_path, notice: 'Vehicle was successfully updated.' }
        else
          format.turbo_stream do
            render turbo_stream: turbo_stream.replace('modal', partial: 'master_data/vehicles/form', locals: { vehicle: @vehicle }),
                   status: :unprocessable_entity
          end
          format.html { render :edit, status: :unprocessable_entity }
        end
      end
    end

    def confirm_delete
      authorize @vehicle, policy_class: MasterData::VehiclePolicy
      # Only show the modal
      if turbo_frame_request?
        render layout: false
      else
        redirect_to master_data_vehicles_path
      end
    end

    def destroy
      authorize @vehicle, policy_class: MasterData::VehiclePolicy
      super
    end

    def restore
      @vehicle = Vehicle.with_discarded.find(params[:id])
      authorize @vehicle, policy_class: MasterData::VehiclePolicy
      super
    end

    private

    def set_vehicle
      @vehicle = Vehicle.find_by(id: params[:id])
      return if @vehicle.present?

      if turbo_frame_request?
        render turbo_stream: turbo_stream.replace('modal', ''), status: :ok
      else
        redirect_to master_data_vehicles_path
      end
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
