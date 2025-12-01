class InventoriesController < ApplicationController
  before_action :set_inventory, only: %i[show edit update destroy confirm_delete]

  def index
    authorize Inventory

    @q = policy_scope(Inventory).ransack(params[:q])
    @q.sorts = 'input_date desc' if @q.sorts.empty?

    @pagy, @inventories = pagy(@q.result(distinct: true).order(created_at: :desc))

    @categories = Category.all
    @units = Unit.all
  end

  # GET /inventories/new
  def new
    @inventory = Inventory.new
    authorize @inventory
  end

  # GET /inventories/:id
  def show
    authorize @inventory
  end

  # GET /inventories/:id/edit
  def edit
    authorize @inventory
  end

  # GET /inventories/:id/confirm_delete
  def confirm_delete
    authorize @inventory
  end

  def create
    @inventory = Inventory.new(inventory_params)
    authorize @inventory

    if @inventory.save
      flash[:notice] = 'Inventory added successfully!'
    else
      flash[:alert] = 'Failed to add inventory.'
    end
  end

  def update
    authorize @inventory

    if @inventory.update(inventory_params)
      flash[:notice] = 'Inventory updated successfully!'
    else
      flash[:alert] = 'Failed to update inventory.'
    end
  end

  def destroy
    authorize @inventory

    if @inventory.destroy
      flash[:notice] = 'Inventory deleted successfully!'
    else
      flash[:alert] = 'Failed to delete inventory.'
    end
  end

  private

  # Loads the inventory item using the ID in the URL
  def set_inventory
    @inventory = Inventory.find(params[:id])
  end

  # Only allow a list of trusted parameters through
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
