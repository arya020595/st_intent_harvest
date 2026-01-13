# frozen_string_literal: true

class InventoryOrdersController < ApplicationController
  include RansackMultiSort
  include SoftDeletableController

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
        # Turbo Stream flash message
        flash.now[:notice] = 'Inventory order was successfully created.'

        format.turbo_stream # renders create.turbo_stream.erb
        format.html do
          redirect_to inventory_inventory_orders_path(@inventory), notice: 'Inventory order was successfully created.'
        end
      else
        format.turbo_stream { render :new, status: :unprocessable_entity }
        format.html { render :new, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /inventories/:inventory_id/inventory_orders/:id
  def update
    authorize @inventory_order

    respond_to do |format|
      if @inventory_order.update(inventory_order_params)
        # Set Turbo Stream flash
        flash.now[:notice] = 'Inventory order was successfully updated.'

        format.turbo_stream # renders update.turbo_stream.erb
        format.html do
          redirect_to inventory_inventory_orders_path(@inventory), notice: 'Inventory order was successfully updated.'
        end
      else
        format.turbo_stream { render :edit, status: :unprocessable_entity }
        format.html { render :edit, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /inventories/:inventory_id/inventory_orders/:id
  def destroy
    authorize @inventory_order
    super
  end

  def restore
    @inventory_order = InventoryOrder.with_discarded.find(params[:id])
    authorize @inventory_order
    super
  end

  private

  def set_inventory
    @inventory = Inventory.find(params[:inventory_id])
    authorize @inventory
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
