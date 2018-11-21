class Api::Frontend::RestaurantsController < ApplicationController

  before_action :authenticate_user!

  def cuisines
    render json: {
      cuisines: Restaurant.cuisines
    }
  end

end
