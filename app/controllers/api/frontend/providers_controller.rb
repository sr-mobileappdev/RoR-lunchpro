class Api::Frontend::ProvidersController < ApplicationController

  before_action :authenticate_user!

  def specialties
    render json: {
      specialties: Provider.specialties
    }
  end

  def titles
    render json: {
      titles: Provider.titles
    }
  end

end