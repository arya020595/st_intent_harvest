class InventoryOrdersController < ApplicationController
  include RansackMultiSort

  before_action :set_inventory
  before_action :set_inventory_order, only: %i[show edit update destroy confirm_delete]

  # GET /inventories/:inventory_id/inventory_orders
  def index
    authorize InventoryOrder

    # Eager load inventory for display
    base = policy_scope(InventoryOrder).where(inventory_id: @inventory.id).includes(:inventory).order(purchase_date: :desc)
    apply_ransack_search(base)

    @pagy, @inventory_orders = paginate_results(@q.result(distinct: true))
  end

  # GET /inventories/:inventory_id/inventory_orders/new
  def new
    @inventory_order = @inventory.inventory_orders.build
    authorize @inventory_order

    if turbo_frame_request?
      render layout: false
    else
      redirect_to inventory_inventory_orders_path(@inventory)
    end
  end

  # GET /inventories/:inventory_id/inventory_orders/:id
  def show
    authorize @inventory_order

    if turbo_frame_request?
      render layout: false
    else
      redirect_to inventory_inventory_orders_path(@inventory)
    end
  end

  # GET /inventories/:inventory_id/inventory_orders/:id/edit
  def edit
    authorize @inventory_order

    if turbo_frame_request?
      render layout: false
    else
      redirect_to inventory_inventory_orders_path(@inventory)
    end
  end

  # GET /inventories/:inventory_id/inventory_orders/:id/confirm_delete
  def confirm_delete
    authorize @inventory_order

    if turbo_frame_request?
      render layout: false
    else
      redirect_to inventory_inventory_orders_path(@inventory)
    end
  end

  # POST /inventories/:inventory_id/inventory_orders
  def create
    @inventory_order = @inventory.inventory_orders.build(inventory_order_params)
    authorize @inventory_order

    respond_to do |format|
      if @inventory_order.save
        format.turbo_stream do
          flash.now[:notice] = 'Inventory order was successfully created.'
        end
        format.html do
          redirect_to inventory_inventory_orders_path(@inventory), notice: 'Inventory order was successfully created.'
        end
      else
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace('modal', partial: 'inventory_orders/form',
                                                             locals: { inventory: @inventory,
                                                                       inventory_order: @inventory_order }),
                 status: :unprocessable_entity
        end
        format.html { render :new, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /inventories/:inventory_id/inventory_orders/:id
  def update
    authorize @inventory_order

    respond_to do |format|
      if @inventory_order.update(inventory_order_params)
        format.turbo_stream do
          flash.now[:notice] = 'Inventory order was successfully updated.'
        end
        format.html do
          redirect_to inventory_inventory_orders_path(@inventory), notice: 'Inventory order was successfully updated.'
        end
      else
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace('modal', partial: 'inventory_orders/form',
                                                             locals: { inventory: @inventory,
                                                                       inventory_order: @inventory_order }),
                 status: :unprocessable_entity
        end
        format.html { render :edit, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /inventories/:inventory_id/inventory_orders/:id
  def destroy
    authorize @inventory_order

    if @inventory_order.destroy
      respond_to do |format|
        format.turbo_stream do
          flash.now[:notice] = 'Inventory order deleted successfully.'
        end
        format.html do
          redirect_to inventory_inventory_orders_path(@inventory), notice: 'Inventory order deleted successfully.'
        end
      end
    else
      redirect_to inventory_inventory_orders_path(@inventory), alert: 'Failed to delete inventory order.'
    end
  end

  private

  def set_inventory
    @inventory = Inventory.find(params[:inventory_id])
  end

  def set_inventory_order
    @inventory_order = @inventory.inventory_orders.find_by(id: params[:id])
    return if @inventory_order.present?

    render(turbo_stream: turbo_stream.replace('modal', ''), status: :ok) and return if turbo_frame_request?

    redirect_to inventory_inventory_orders_path(@inventory)
  end

  def inventory_order_params
    params.require(:inventory_order).permit(:quantity, :total_price, :supplier, :purchase_date)
  end
end
