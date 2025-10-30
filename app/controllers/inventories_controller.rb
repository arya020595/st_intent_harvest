# frozen_string_literal: true

class InventoriesController < ApplicationController
  before_action :set_inventory, only: %i[show edit update destroy]

  def index
    @inventories = policy_scope(Inventory)
    authorize Inventory
  end

  def show
    authorize @inventory
  end

  def new
    @inventory = Inventory.new
    @blocks = Block.all
    authorize @inventory
  end

  def create
    @inventory = Inventory.new(inventory_params)
    authorize @inventory

    if @inventory.save
      redirect_to @inventory, notice: 'Inventory item was successfully created.'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    authorize @inventory
  end

  def update
    authorize @inventory

    if @inventory.update(inventory_params)
      redirect_to @inventory, notice: 'Inventory item was successfully updated.'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @inventory

    @inventory.destroy!
    redirect_to inventories_url, notice: 'Inventory item was successfully deleted.'
  end

  private

  def set_inventory
    @inventory = Inventory.find(params[:id])
  end

  def inventory_params
    params.require(:inventory).permit(
      :name,
      :stock_quantity,
      :price,
      :currency,
      :supplier,
      :input_date,
      :unit_id,
      :category_id
    )
  end
end
