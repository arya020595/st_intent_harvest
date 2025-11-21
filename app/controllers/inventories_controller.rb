#This defines a controller which inheritates (OOP allows class(subclass) to reuse in a hiearchical structure) 
#from the base controller from the app.

#before running CRUD, rails will execute the set_inventory method to load the correct record from the database
class InventoriesController < ApplicationController
  before_action :set_inventory, only: %i[edit update destroy]

#'authorize/pundit is used to check if the user is allowed to view inventory items'
def index
  authorize Inventory

  @q = policy_scope(Inventory).ransack(params[:q]) #this sets up the serach/filter functionality from Ransack
  @q.sorts = 'input_date desc' if @q.sorts.empty? #if the user did'nt choose a sort order, default to ordering by input_date descending.

  @pagy, @inventories = pagy(@q.result(distinct: true).order(created_at: :desc)) #it runs the search query first, it uses Pagy for pagination and @inventories is the pagination list of inventories

  @categories = Category.all #this loads all cateories for dropdown filter
  @units = Unit.all #this loads all units for dropdown filter

end

  #this section builds new inventory items using strong params, then it checks if the user is allowed to create it.
  def create
    @inventory = Inventory.new(inventory_params)
    authorize @inventory

    #Condition where if add a new inventory item it will return a success message bubble.
    if @inventory.save
      redirect_to inventories_path, notice: 'Inventory added successfully!'
    #Otherwise, if failed it rebuilds all required instance variables needed by the index page.
    else
      # Rebuild data for re-render
      @q = policy_scope(Inventory).ransack(params[:q])
      @pagy, @inventories = pagy(@q.result.order(created_at: :desc))
      @categories = Category.all
      @units = Unit.all
      render :index, status: :unprocessable_entity #this renders the index view again (not redirect) return http 422
    end
  end

  #this section updates the existed inventory item and firstly it checks permission for updating the item.
  def update
    authorize @inventory

    #Condition where if updating an existing inventory item it will return a success message bubble.
    if @inventory.update(inventory_params)
      redirect_to inventories_path, notice: 'Inventory updated successfully!'

    #Otherwise, if failed it will return an error message.
    else
      redirect_to inventories_path, alert: 'Failed to update inventory.'
    end
  end


  #this section deletes existing inventory items, it checks permissions if the user is allowed to delete it.
  def destroy
    authorize @inventory

    #deletes the item if possible and redirects with appropriate message. 
    if @inventory.destroy
      redirect_to inventories_path, notice: 'Inventory deleted successfully!'
    else
      redirect_to inventories_path, alert: 'Failed to delete inventory.'
    end
  end

  private


    #Loads the inventory item using the ID in the URL. Used edit/update/destroy
  def set_inventory
    @inventory = Inventory.find(params[:id])
  end


  #Ensures only allowed fields can be submitted from forms.
  #Protect against mass-assignment vulnerabilities.
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
