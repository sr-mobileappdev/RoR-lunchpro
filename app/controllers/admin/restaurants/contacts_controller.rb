class Admin::Restaurants::ContactsController < AdminController
  before_action :set_parent_record
  before_action :set_record, only: [:show, :edit, :update, :delete]

  def set_parent_record
    @restaurant = Restaurant.find(params[:restaurant_id])
  end

  def set_record
    @record = RestaurantPoc.find(params[:id])
  end

  def show

  end

  def new
    @record = RestaurantPoc.new()
    @record.restaurant = @restaurant
  end

  def create

    form = Forms::AdminRestaurantPoc.new(current_user, allowed_params)
    unless form.valid?
      render :json => {success: false, general_error: "Unable to add contact to restaurant due to the following errors or notices:", errors: form.errors}, status: 500
      return
    end

    # Model validations & save
    unless form.save_and_invite
      render :json => {success: false, general_error: "Unable to add contact to restaurant at this time due to a server error.", errors: []}, status: 500
      return
    end

    flash[:notice] = "New restaurant contact has been assigned to this restaurant."
    render :json => {success: true, redirect: admin_restaurant_path(@restaurant) }
    return

  end

  def update

    form = Forms::AdminRestaurantPoc.new(current_user, allowed_params, @record)
    unless form.valid?
      render :json => {success: false, general_error: "Unable to update contact due to the following errors or notices:", errors: form.errors}, status: 500
      return
    end

    # Model validations & save
    unless form.save
      render :json => {success: false, general_error: "Unable to update contact at this time due to a server error.", errors: []}, status: 500
      return
    end

    flash[:notice] = "Restaurant contact details have been updated."
    render :json => {success: true, redirect: admin_restaurant_path(@restaurant) }
    return

  end
  def delete
    #check if user is trying to delete their only active restaurant POC, and block them if they are
    if @restaurant.restaurant_pocs.where(:status => "active").count == 1
      flash[:alert] = "Unable to delete contact, there must be at least one active Restaurant Contact."
      render :json => {success: true, redirect: admin_restaurant_path(@restaurant) }
      return
    end

    #set poc to deleted
    @record.update_attributes!(status: 'deleted')
    flash[:alert] = "Restaurant Contact has been deleted from the LunchPro system."
    if params[:wizard] && params[:wizard] == 'true'
      render :json => {success: true, reload: true}
      return
    else
      render :json => {success: true, redirect: admin_restaurant_path(@restaurant) }
      return
    end
  end

private

  def allowed_params
    groupings = [:restaurant_poc]

    super(groupings, params)
  end


end
