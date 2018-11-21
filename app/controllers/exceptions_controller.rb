class ExceptionsController < ApplicationController
  layout "exceptions"

  def not_found
    @ui_space = 'nil'
    if current_user
      case current_user.space
      when 'space_sales_rep'
        @ui_space = 'sales_rep'
      when 'space_office'
        @ui_space = 'office'
      when 'space_restaurant'
        @restaurant = Restaurant.find((session[:current_restaurant_id] || current_user.restaurant.restaurant_id))
        @ui_space = 'restaurant'
      end
    end
    if json_request?
      render :json => {message: 'Page or resource not found at this address'}, status: 404
      return
    end

    render template: "exceptions/not_found.html.erb", :status => 404, :layout => false
  end

  def internal_server_error
    if json_request?
      render :json => {message: 'System has encountered a 500 error. We have been notified. If this error persists or is urgent please contact support.'}, status: 500
      return
    end
    render :file => "#{Rails.root}/public/500.html", :status => 500, :layout => false
  end

end
