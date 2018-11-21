class Restaurant::RestaurantExcludeDatesController < ApplicationRestaurantsController
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
    if @xhr
      if modal?
        render :json => { html: (render_to_string partial: 'shared/modals/restaurants/exclude_date', layout: false, formats: [:html]) }
        return
      else
        raise "Opening modal view without passing is_modal=true"
      end
    end
  end

end
