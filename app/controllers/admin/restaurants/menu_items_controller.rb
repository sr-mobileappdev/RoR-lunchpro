class Admin::Restaurants::MenuItemsController < AdminController
  before_action :set_parent_record, except: [:complete_upload_asset]
  before_action :set_record, only: [:show, :edit, :update, :activate, :deactivate, :delete, :remove, :upload_asset, :complete_upload_asset, :menu_items_setup]

  def set_parent_record
    @restaurant = Restaurant.find(params[:restaurant_id])
    if params[:menu_id].present?
      @menu = Menu.find(params[:menu_id])
    else
      @menu = nil
    end
  end

  def set_record
    if params[:id]
      @record = MenuItem.find(params[:id])
    else
      @record = MenuItem.new(modified_by_user_id: current_user.id, restaurant_id: @restaurant.id, people_served: 1)
      @record.menu_sub_items << MenuSubItem.new(name: '', qty_allowed: nil, status: 'active', menu_sub_item_options: [MenuSubItemOption.new(option_name: '', price_cents: 0)])
    end
  end

  def show

  end

  def new
    @record = MenuItem.new(modified_by_user_id: current_user.id, restaurant_id: @restaurant.id, people_served: 1)

  end

  def menu_items_setup

  end

  def create

    form = Forms::AdminMenuItem.new(current_user, @menu, allowed_params)
    unless form.save && form.menu_item.activate!
      render :json => {success: false, general_error: "Unable to create new menu item to the following errors or notices:", errors: form.errors}, status: 500
      return
    end

    if params[:wizard] == 'true'
      flash[:notice] = "'#{form.menu_item.name}' has been added to this restaurant's active menu items."
      render json: { success: true, reload: true }
      return
    else

      flash[:notice] = "'#{form.menu_item.name}' has been added to this restaurant's active menu items."
      render :json => {success: true, redirect: admin_restaurant_menus_path(@restaurant) }
      return
    end

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

    if params[:wizard] == 'true'
      flash[:notice] = "'#{@record.name}' has been activated and is now available for immediate ordering."
      render json: { success: true , redirect: "/admin/restaurants/#{@restaurant.id}/registration#step-3"}
      return
    else
      flash[:notice] = "'#{@record.name}' has been activated and is now available for immediate ordering."
      return_path = (@menu) ? admin_restaurant_menu_path(@restaurant, @menu) : admin_restaurant_menu_item_path(@restaurant, @record)
      redirect_to return_path
      return
    end

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
      if params[:wizard] == 'true'

        render :json => {success: true, reload: true}
        return
      else
        render :json => {success: true, redirect: return_path }
        return
      end
    end
  end

  def upload_asset
    if @xhr
      render json: { html: (render_to_string :partial => 'admin/shared/components/uploader_popup', locals: {upload_path: complete_upload_asset_admin_restaurant_menu_item_path(@record, image_id: params[:image_id]), upload_param: :image}, :layout => false, :formats => [:html]) }
      return
    else
      head :ok
    end
  end

  def complete_upload_asset
    if params[:menu_item].present?
    
      if params[:image_id].present? && @record.menu_item_images.pluck(:id).include?(params[:image_id].to_i)
        @menu_item_image = MenuItemImage.find(params[:image_id])
      else
        @menu_item_image = MenuItemImage.create(status: 'active', menu_item: @record, position: 1)
      end


      image_from_client = parse_image_data(params[:image_data])
      @menu_item_image.update(image: image_from_client)

      clean_tempfile
      
      redirect_to admin_restaurant_menu_item_path(@record.restaurant, @record), notice: 'Image has been uploaded'
    end
  end


  private

  def parse_image_data(base64_image)
    filename = "menu-item-image-#{@menu_item_image.id}"
    in_content_type, encoding, string = base64_image.split(/[:;,]/)[1..3]

    @tempfile = Tempfile.new(filename)
    temp_file_path = @tempfile.path
    @tempfile.binmode
    @tempfile.write Base64.decode64(string)
    @tempfile.rewind
    
    content_type = params[:image_file_type]
    # we will also add the extension ourselves based on the above
    # if it's not gif/jpeg/png, it will fail the validation in the upload model
    extension = content_type.match(/gif|jpeg|png/).to_s
    filename += ".#{extension}" if extension
    ActionDispatch::Http::UploadedFile.new({
      tempfile: @tempfile,
      content_type: content_type,
      filename: filename
    })    
  end
  
  def clean_tempfile
    if @tempfile
      @tempfile.close
      @tempfile.unlink
    end
  end


  def allowed_upload_params
    params.require(:menu_item).permit(:image)
  end

  def allowed_params
    groupings = [:menu_item, :diet_restriction, :diet_restrictions, :menu_sub_items, :menus]

    super(groupings, params)
  end

end
