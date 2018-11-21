class Api::Frontend::SlotsController < ApplicationController

  before_action :authenticate_user!

  def index
  
  end

  def day_of_weeks
    render json: {
      day_of_weeks: AppointmentSlot.formatted_day_of_weeks
    }
  end

end
