class Admin::Restaurants::LunchPacksController < AdminController
  before_action :set_parent_record
  before_action :set_record, only: [:show, :edit, :update, :activate, :deactivate, :delete]

  def set_parent_record
    @restaurant = Restaurant.find(params[:restaurant_id])
    if params[:menu_id]
      @menu = Menu.find(params[:menu_id])
    else
      @menu = nil
    end
  end

  def set_record
    @record = MenuItem.find(params[:id])
  end

  def show

  end

  def new
    @record = MenuItem.new(modified_by_user_id: current_user.id, restaurant_id: @restaurant.id, people_served: 1, :lunchpack => true)
    @record.menu_sub_items << MenuSubItem.new(name: '', qty_allowed: nil, status: 'active', menu_sub_item_options: [MenuSubItemOption.new(option_name: '', price_cents: 0)])

  end

  def create

    form = Forms::AdminMenuItem.new(current_user, @menu, allowed_params)
    unless form.save
      render :json => {success: false, general_error: "Unable to create new menu item to the following errors or notices:", errors: form.errors}, status: 500
      return
    end

    form.menu_item.activate!

    return_path = (@menu) ? admin_restaurant_menu_path(@restaurant, @menu) : admin_restaurant_menu_item_path(@restaurant, form.menu_item)

    flash[:notice] = "'#{form.menu_item.name}' has been activated and is now available for immediate ordering."
    render :json => {success: true, redirect: return_path }
    return

  end

  def update

    form = Forms::AdminMenuItem.new(current_user, @menu, allowed_params, @record)
    unless form.save
      render :json => {success: false, general_error: "Unable to update menu item due to the following errors or notices:", errors: form.errors}, status: 500
      return
    end

    return_path = (@menu) ? admin_restaurant_menu_path(@restaurant, @menu) : admin_restaurant_menu_item_path(@restaurant, form.menu_item)

    flash[:notice] = "Menu item has been updated."
    render :json => {success: true, redirect: return_path }
    return

  end

  def activate

    @record.activate!

    flash[:notice] = "'#{@record.name}' has been activated and is now available for immediate ordering."

    return_path = (@menu) ? admin_restaurant_menu_path(@restaurant, @menu) : admin_restaurant_menu_item_path(@restaurant, @record)
    redirect_to return_path

  end

  def deactivate

    if @restaurant.menu_items.where(:status => "active").count == 1 && @record.status == 'active'
      flash[:alert] = "Unable to deactivate menu item, there must be at least one active menu item for this restaurant."
    else
      @record.deactivate!
      flash[:alert] = "'#{@record.name}' has been deactivated and is no longer available for ordering. Existing orders may contain this menu item."
    end

    return_path = (@menu) ? admin_restaurant_menu_path(@restaurant, @menu) : admin_restaurant_menu_item_path(@restaurant, @record)
    redirect_to return_path

  end

  #used to remove a menu item from a menu, only removes association, doesnt delete menu item
  def remove
    item = @record.dup
    @menu.menu_items.delete(@record)
    flash[:alert] = "Menu item '#{item.name}' has been removed from the menu '#{@menu.name}'."
    return_path = admin_restaurant_menu_path(@restaurant, @menu)
    redirect_to return_path
  end


  def delete
    return_path = (@menu) ? admin_restaurant_menu_path(@restaurant, @menu) : admin_restaurant_menus_path(@restaurant)

    if @restaurant.menu_items.where(:status => "active").count == 1 && @record.status == 'active'
      flash[:alert] = "Unable to delete menu item, there must be at least one active menu item for this restaurant."
      render :json => {success: false, redirect: admin_restaurant_menu_item_path(@restaurant, @record) }
    else
      prior_status = @record.status
      @record.deleted!
      flash[:alert] = "Menu item has been removed from the system. It will now only appear in historical reports, where applicable."
      render :json => {success: true, redirect: return_path }
    end
  end

  def upload_asset
    if @xhr
      render json: { html: (render_to_string :partial => 'admin/shared/components/uploader_popup', locals: {upload_path: complete_upload_asset_admin_restaurant_menu_item_path(@record), upload_param: :image}, :layout => false, :formats => [:html]) }
      return
    else
      head :ok
    end
  end

  def complete_upload_asset
    menu_item_image = MenuItemImage.new(status: 'active', menu_item: @record, position: 1)
    menu_item_image.save

    menu_item_image.update(allowed_upload_params)
    # @record.update(allowed_upload_params)

    redirect_to admin_restaurant_menu_item_path(@record.restaurant, @record), notice: 'Image has been uploaded'
  end

private

  def allowed_upload_params
    params.require(:menu_item).permit(:image)
  end

  def allowed_params
    groupings = [:menu_item, :diet_restrictions, :menu_sub_items, :menus]

    super(groupings, params)
  end

end
