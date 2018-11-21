class RestaurantAvailabilitiesController < ApplicationRestaurantsController
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
  end

  def create
    unless params[:starts_at].present? && params[:ends_at].present? && params[:restaurant_id].present?
      raise "Must provide both the start and end time along with the restaurant id to save this availability"
    end
    restaurant_availability = RestaurantAvailability.new(restaurant_id: params[:restaurant_id], starts_at: params[:starts_at], ends_at: params[:ends_at])

    unless restaurant_availability.save
      render :json => {success: false, general_error: "Unable to update this restaurant's availability hours", errors: @restaurant.errors.full_messages}, status: 500
      return
    end

    redirect_to edit_restaurant_preferences_path
  end


end
