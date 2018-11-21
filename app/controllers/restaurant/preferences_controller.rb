class Restaurant::PreferencesController < ApplicationRestaurantsController
  before_action :set_restaurant_user
  before_action :set_restaurant

  def set_restaurant_user
    @restaurant_user = UserRestaurant.find_by(user_id: current_user.id)
    @consolidated = session[:hq_consolidated_view]
  end

  def set_restaurant
    @restaurant = Restaurant.find((current_restaurant_id || @restaurant_user.restaurant_id))
  end

  def index
    RestaurantAvailability.dows.each do |day, number|
      avail = @restaurant.restaurant_availabilities.where(:status => 'active', :day_of_week => number)
      if avail.present?
        #if one already exists for this weekday, skip
      else
        # else create a new one
         @restaurant.restaurant_availabilities.build(day_of_week: number, status: 'inactive')
      end
    end
  end

  def update_preferences
    form = Forms::RestaurantManagers::RestaurantAvailability.new(@restaurant, restaurant_availabilities_params)
      # have to be converted to cents, since sent to params as dollar amounts
    params[:restaurant][:min_order_amount_cents] = @restaurant.convert_to_cents(params[:restaurant][:min_order_amount_cents])
    params[:restaurant][:default_delivery_fee_cents] = @restaurant.convert_to_cents(params[:restaurant][:default_delivery_fee_cents])

    if form.valid? && form.save && @restaurant.update_attributes(preferences_params)
      render :json => { success: true }
      return
    else
      render :json => { success: false, general_error: "Your restaurant's catering preferences could not be updated at this time", errors: @restaurant.errors.full_messages }, status: 500
      return
    end

  end

  def update_exclusions
    if @restaurant.update_attributes(exclude_dates_params)
      render :json => { success: true }
      return
    else
      render :json => { success: false, general_error: "Unable to update your restaurant's exclusion date due to the following errors or notices:", errors: @restaurant.errors.full_messages}, status: 500
      return
    end

  end

  def update_delivery_distance

    if @restaurant.update_attributes(delivery_distance_params)
      render :json => { success: true }
      return
    else
      render :json => { success: false, general_error: "Unable to update your restaurant's delivery distance settings due to the following errors or notices:", errors: @restaurant.errors.full_messages}, status: 500
      return
    end

  end

  def update

  end

  def delete
  end

private

  def restaurant_params
    params.require(:restaurant).permit(:id, :min_order_amount_cents, :default_delivery_fee_cents, :max_order_people, :orders_until, :orders_until_hour, :delivery_radius,
      restaurant_availabilities_attributes: [:id, :day_of_week, :starts_at, :ends_at, :status],
      restaurant_exclude_dates_attributes: [:id, :starts_at, :ends_at, :restaurant_id, :_destroy],
      delivery_distance_attributes: [:id, :radius, :use_complex, :north, :north_east, :east, :south_east, :south, :south_west, :west, :north_west, :restaurant_id])
  end

  def preferences_params
    params.require(:restaurant).permit(:id, :min_order_amount_cents, :default_delivery_fee_cents, :max_order_people, :orders_until, :orders_until_hour, :delivery_radius,
      delivery_distance_attributes: [:id, :radius, :restaurant_id])
  end

  def delivery_distance_params
    params.require(:restaurant).permit(:id, delivery_distance_attributes: [:id, :radius, :use_complex, :north, :north_east, :east, :south_east, :south, :south_west, :west, :north_west, :restaurant_id])
  end

  def restaurant_availabilities_params
    params.require(:restaurant).permit(:id, restaurant_availabilities_attributes: [:id, :day_of_week, :starts_at, :ends_at, :status])
  end

  def exclude_dates_params
    params.require(:restaurant).permit(:id,
      restaurant_exclude_dates_attributes: [:id, :starts_at, :ends_at, :restaurant_id, :_destroy])
  end
end
