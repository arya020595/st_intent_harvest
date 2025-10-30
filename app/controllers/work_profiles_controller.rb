# frozen_string_literal: true

class WorkProfilesController < ApplicationController
  before_action :set_work_profile, only: %i[show edit update destroy]

  def index
    @work_profiles = policy_scope(WorkProfile)
    authorize WorkProfile
  end

  def show
    authorize @work_profile
  end

  def new
    @work_profile = WorkProfile.new
    authorize @work_profile
  end

  def create
    @work_profile = WorkProfile.new(work_profile_params)
    authorize @work_profile

    # Logic to be implemented later
  end

  def edit
    authorize @work_profile
  end

  def update
    authorize @work_profile

    # Logic to be implemented later
  end

  def destroy
    authorize @work_profile

    # Logic to be implemented later
  end

  private

  def set_work_profile
    @work_profile = WorkProfile.find(params[:id])
  end

  def work_profile_params
    params.require(:work_profile).permit(
      :name,
      :description
    )
  end
end
