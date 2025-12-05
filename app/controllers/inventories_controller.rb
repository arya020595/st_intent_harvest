class InventoriesController < ApplicationController
  include RansackMultiSort

  before_action :set_inventory, only: %i[show edit update destroy confirm_delete]
  before_action :load_collections, only: %i[new edit]

  def index
    authorize Inventory

    # Eager load associations used in the view to avoid N+1
    base = policy_scope(Inventory).includes(:unit, :category).order(created_at: :desc)
    apply_ransack_search(base)

    @pagy, @inventories = paginate_results(@q.result(distinct: true))

    @categories = Category.all
    @units = Unit.all
  end

  # GET /inventories/new
  def new
    @inventory = Inventory.new
    @inventory.inventory_orders.build # Initialize with one empty order row
    authorize @inventory

    if turbo_frame_request?
      render layout: false
    else
      redirect_to inventories_path
    end
  end

  # GET /inventories/:id
  def show
    authorize @inventory
    @recent_orders = @inventory.inventory_orders.order(purchase_date: :desc).limit(5)

    if turbo_frame_request?
      render layout: false
    else
      redirect_to inventories_path
    end
  end

  # GET /inventories/:id/edit
  def edit
    authorize @inventory
    @recent_orders = @inventory.inventory_orders.order(id: :desc).limit(5)

    if turbo_frame_request?
      render layout: false
    else
      redirect_to inventories_path
    end
  end

  # GET /inventories/:id/confirm_delete
  def confirm_delete
    authorize @inventory

    # Only render the modal if Turbo frame request
    if turbo_frame_request?
      render layout: false
    else
      redirect_to inventories_path
    end
  end

  def create
    @inventory = Inventory.new(inventory_params)
    authorize @inventory

    respond_to do |format|
      if @inventory.save
        format.turbo_stream do
          flash.now[:notice] = 'Inventory was successfully created.'
        end
        format.html { redirect_to inventories_path, notice: 'Inventory was successfully created.' }
      else
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace('modal', partial: 'inventories/form', locals: { inventory: @inventory }),
                 status: :unprocessable_entity
        end
        format.html { render :new, status: :unprocessable_entity }
      end
    end
  end

  def update
    authorize @inventory

    respond_to do |format|
      if @inventory.update(inventory_params)
        format.turbo_stream do
          flash.now[:notice] = 'Inventory was successfully updated.'
        end
        format.html { redirect_to inventories_path, notice: 'Inventory was successfully updated.' }
      else
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace('modal', partial: 'inventories/form', locals: { inventory: @inventory }),
                 status: :unprocessable_entity
        end
        format.html { render :edit, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    authorize @inventory

    if @inventory.destroy
      respond_to do |format|
        format.turbo_stream do
          flash.now[:notice] = 'Inventory deleted successfully.'
        end
        format.html { redirect_to inventories_path, notice: 'Inventory deleted successfully.' }
      end
    else
      redirect_to inventories_path, alert: 'Failed to delete inventory.'
    end
  end

  private

  # Loads the inventory item using the ID in the URL
  def set_inventory
    @inventory = Inventory.find_by(id: params[:id])
    return if @inventory.present?

    if turbo_frame_request?
      render turbo_stream: turbo_stream.replace('modal', ''), status: :ok and return
    else
      redirect_to inventories_path and return
    end
  end

  # Provide categories and units for the form partial
  def load_collections
    @categories = Category.all
    @units = Unit.order(:name)
  end

  # Only allow a list of trusted parameters through
  def inventory_params
    params.require(:inventory).permit(
      :name,
      :unit_id,
      :category_id,
      inventory_orders_attributes: %i[id quantity total_price supplier purchase_date _destroy]
    )
  end
end
