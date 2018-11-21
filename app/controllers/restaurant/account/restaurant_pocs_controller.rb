class Restaurant::Account::RestaurantPocsController < ApplicationRestaurantsController
  before_action :set_restaurant_user
  before_action :set_restaurant

  def set_restaurant_user
    @restaurant_user = current_user.user_restaurant
    @consolidated = session[:hq_consolidated_view]
  end

  def set_restaurant
    @restaurant = Restaurant.find((current_restaurant_id || @restaurant_user.restaurant_id))

  end


  def index
    @show_tab = params[:tab] || "contact_information"
  end

  def new
    @poc = RestaurantPoc.new
    render json: {
      templates: {
        targ__restaurant_account: (render_to_string :partial => 'restaurant/account/components/account__detail_new_restaurant_poc', :layout => false, :formats => [:html])
      }
    }
  end

  def create
    restaurant_id = @restaurant.id
    @poc = RestaurantPoc.new(poc_params)
    @poc.restaurant = @restaurant
    if @poc.save
      flash[:notice] = "New point of contact has been added"
      render :json => {success: true, redirect: '/restaurant/account?tab=contact_information'}
    else
      flash[:alert] = "Point of contact could not be added at this time."
      render :json => {success: false, general_error: "Invalid information for point of contact", errors: @poc.errors[:base]}
    end
  end


  def update
    tab = params[:for]
    poc = RestaurantPoc.find(params[:id])
    upt_poc = params[:restaurant_poc]
    new_name = upt_poc[:display_name]
    if new_name != poc.display_name
      @first_name = new_name.split(" ").first()
      @last_name = new_name.split(" ").last()
      poc.assign_attributes(first_name: @first_name, last_name: @last_name, email: upt_poc[:email], phone: upt_poc[:phone])
    else
      poc.assign_attributes(email: upt_poc[:email], phone: upt_poc[:phone])
    end

    unless poc.save
      render :json => {success: false, general_error: "Unable to update this contact's information", errors: poc.errors}, status: 500
      return
    end

    if tab.present?
      redirect_to restaurant_account_index_path(tab: tab)
    else
      redirect_to restaurant_account_index_path(tab: "contact information")
    end
  end

  def delete
    @record = RestaurantPoc.find(params[:id])
    @record.update_attributes(:status => 'deleted')

    flash[:alert] = "Contact has been deleted."
    render :json => {success: true, redirect: '/restaurant/account?tab=contact_information'}
  end

private
  def poc_params
    params.require(:restaurant_poc).permit(:first_name, :last_name, :email, :phone, :restaurant, :primary, :restaurant_id)
  end

end
