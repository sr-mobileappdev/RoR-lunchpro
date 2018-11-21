class Admin::Restaurants::UsersController < AdminController
  before_action :set_parent_record
  before_action :set_record, only: [:show, :edit, :update]

  def set_parent_record
    @restaurant = Restaurant.find(params[:restaurant_id])
  end

  def set_record
    @restaurant_user = User.find(params[:id])
  end

  def show

  end

  def new
    @restaurant_user = UserRestaurant.new()
    @restaurant_user.restaurant = @restaurant
    @restaurant_user.user = User.new()
  end

  def create

    if params[:poc] == '1'
      params[:restaurant_poc] = {first_name: params[:user][:first_name], last_name: params[:user][:last_name], title: params[:user][:job_title], email: params[:user][:email], phone: params[:user][:primary_phone], restaurant_id: @restaurant.id}
      form = Forms::AdminRestaurantPoc.new(current_user, allowed_params)
    else
      form = Forms::AdminUserRestaurant.new(current_user, allowed_params)
    end

    unless form.valid?
      render :json => {success: false, general_error: "Unable to add restaurant point of contact due to the following errors or notices:", errors: form.errors}, status: 500
      return
    end

    # Model validations & save
    unless form.save_and_invite
      render :json => {success: false, general_error: "Unable to add restaurant point of contact at this time due to a server error.", errors: []}, status: 500
      return
    end

    if params[:poc] == "1"
      flash[:notice] = "New restaurant point of contact has been assigned to this restaurant"
    else
      flash[:notice] = "New restaurant user has been assigned to this restaurant, and invited to LunchPro."
    end

    if params[:wizard] == 'true'
      render :json => {success: true, reload: true}
      return
    else
      render :json => {success: true, redirect: admin_restaurant_path(@restaurant) }
      return
    end

  end

  def update

    form = Forms::AdminUserRestaurant.new(current_user, allowed_params, @record, @record.user)
    unless form.valid?
      render :json => {success: false, general_error: "Unable to update restaurant point of contact due to the following errors or notices:", errors: form.errors}, status: 500
      return
    end

    # Model validations & save
    unless form.save
      render :json => {success: false, general_error: "Unable to update restaurant point of contact at this time due to a server error.", errors: []}, status: 500
      return
    end

    flash[:notice] = "User details have been updated."
    render :json => {success: true, redirect: admin_restaurant_path(@restaurant) }
    return

  end

private

  def allowed_params
    groupings = [:user_restaurant, :user, :restaurant_poc]

    super(groupings, params)
  end


end
