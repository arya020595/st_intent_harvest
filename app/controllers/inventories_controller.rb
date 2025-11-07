class InventoriesController < ApplicationController
  before_action :set_inventory, only: %i[edit update destroy]

  def index
    @inventories = Inventory.order(created_at: :desc)
    @inventory = Inventory.new
    @categories = Category.all
    @units = Unit.all
  end

  def create
    @inventory = Inventory.new(inventory_params)

    if @inventory.save
      redirect_to inventories_path, notice: 'Inventory added successfully!'
    else
      @inventories = Inventory.order(created_at: :desc)
      render :index
    end
  end

  def update
    if @inventory.update(inventory_params)
      redirect_to inventories_path, notice: 'Inventory updated successfully!'
    else
      redirect_to inventories_path, alert: 'Failed to update inventory.'
    end
  end

  def destroy
    if @inventory.destroy
      redirect_to inventories_path, notice: 'Inventory deleted successfully!'
    else
      redirect_to inventories_path, alert: 'Failed to delete inventory.'
    end
  end

  private

  def set_inventory
    @inventory = Inventory.find(params[:id])
  end

  def inventory_params
    params.require(:inventory).permit(
      :name,
      :category_id,
      :price,
      :currency,
      :stock_quantity,
      :supplier,
      :unit_id,
      :input_date
    )
  end
end
