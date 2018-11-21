class Admin::Restaurants::MenusController < AdminController
  before_action :set_parent_record
  before_action :set_record, only: [:show, :edit, :update, :find_items, :add_item, :activate, :deactivate, :delete, :menu_setup, :export]

  def set_parent_record
    @restaurant = Restaurant.find(params[:restaurant_id])
  end

  def set_record
    if params[:id]
      @record = Menu.find(params[:id])
    else
      @record = Menu.new(created_by_user_id: current_user.id, restaurant_id: @restaurant.id)
    end
  end

  def show

  end

  def new
    @record = Menu.new(created_by_user_id: current_user.id, restaurant_id: @restaurant.id)
  end

  def find_items

  end

  def add_item
    @item = MenuItem.find(params[:item_id])
    if @record.new_record?
      @record.save
    end
    @record.add_item(@item)
  end

  def menu_setup


  end

  def create

    form = Forms::AdminMenu.new(current_user, allowed_params)
    unless form.valid?
      render :json => {success: false, general_error: "Unable to create new menu due to the following errors or notices:", errors: form.errors}, status: 500
      return
    end

    # Model validations & save
    unless form.save
      render :json => {success: false, general_error: "Unable to create new menu at this time due to a server error.", errors: []}, status: 500
      return
    end

    flash[:notice] = "Menu has been created."
    if params[:wizard] == 'true'
      render :json => {success: true, reload: true}
      return
    else
      render :json => {success: true, redirect: admin_restaurant_menus_path(@restaurant) }
      return
    end

  end

  def update

    form = Forms::AdminMenu.new(current_user, allowed_params, @record)
    unless form.valid?
      render :json => {success: false, general_error: "Unable to update menu settings due to the following errors or notices:", errors: form.errors}, status: 500
      return
    end

    # Model validations & save
    unless form.save
      render :json => {success: false, general_error: "Unable to update menu settings at this time due to a server error.", errors: []}, status: 500
      return
    end

    flash[:notice] = "Menu has been updated."
    render :json => {success: true, redirect: admin_restaurant_menu_path(@restaurant, form.menu) }
    return

  end

  def delete

    if @restaurant.menus.where(:status => "active").count == 1
      flash[:alert] = "Unable to delete menu, there must be at least one active menu for this restaurant."
      render :json => {success: false, redirect: admin_restaurant_menu_path(@restaurant, @record)}
    else
      @record.update_attributes(status: "deleted")
      flash[:alert] = "Menu has been deleted from the system."
      if params[:wizard] == 'true'
        render :json => {success: true,  reload: true}
        return
      else
        render :json => {success: true, redirect: admin_restaurant_menus_path(@restaurant) }
        return
      end
    end

  end

  def activate

    @record.update_attributes(deactivated_at: nil, status: "active")
    flash[:notice] = "Menu has been activated within the LunchPro system."
    render :json => {success: true, redirect: admin_restaurant_menus_path(@restaurant) }

  end

  def deactivate

    if @restaurant.menus.where(:status => "active").count == 1
      flash[:alert] = "Unable to deactivate menu, there must be at least one active menu for this restaurant."
      render :json => {success: false, redirect: admin_restaurant_menu_path(@restaurant, @record)}
    else
      @record.update_attributes(deactivated_at: Time.now, status: "inactive", deactivated_by_id: current_user.id)
      flash[:alert] = "Menu has been deactivated within the LunchPro system."
      render :json => {success: true, redirect: admin_restaurant_menus_path(@restaurant)}
    end

  end

  def export
    man = Managers::CsvManager.new

    csv_data = man.export_menu_items(current_user, @record.restaurant_id, @record.id)
    filename = "#{@record.restaurant.name}_#{@record.name}".delete(' ')
    
    unless !man.errors.any?
      flash[:alert] = "There was an error processing your request."
      redirect_to request.referrer and return
    end
    send_data csv_data,
      :type => 'text/csv',
      :disposition => "attachment; filename=#{filename}_#{Time.now.to_date}.csv"
  end


private

  def allowed_params
    groupings = [:menu]

    super(groupings, params)
  end

end
