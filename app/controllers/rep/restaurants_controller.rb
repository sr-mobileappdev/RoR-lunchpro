class Rep::RestaurantsController < ApplicationRepsController

  before_action :set_restaurant

  def set_restaurant
    @restaurant = Restaurant.find(params[:id])
  end

  def index
    redirect_to current_rep_calendars_path
  end

  # The current overall calendar for a single rep, across all offices
  def current
    @redirect_to = 'calendar'
  end

  # individual calendar for a specific office
  def show
    redirect_to current_rep_calendars_path
  end
  
  def reviews
    @order_review_count = @restaurant.order_reviews.count
    redirect_to current_rep_calendars_path if @order_review_count == 0
    @order_reviews_with_comments = @restaurant.order_reviews.select{|review| review.comment.present?}.sort_by{|rev| rev.overall}
  end
end
