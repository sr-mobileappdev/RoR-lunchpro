class Restaurant::MenusController < ApplicationRestaurantsController
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
    @show_tab = params[:tab] || "all"
    @menus = @restaurant.active_menus

  end

  def show
    if @xhr
      #nil menu == full menu
      menu = nil
      if params[:id].present? && params[:id] != "0"
        menu = Menu.find(params[:id])
      end
      render json: {templates: {
          targ__menu_detail: (render_to_string :partial => 'restaurant/menus/components/menu_detail', locals:{restaurant: @restaurant, menu: menu}, :layout => false, :formats => [:html])
        }
      }
    else
    end
  end


end
