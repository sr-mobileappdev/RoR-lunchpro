class Api::V1::OrderReviewsController < ApiController

skip_before_action :check_user_space, only: [:index]

  def index
    records = []

    if params[:restaurant_id].present?
    	restaurant = Restaurant.find(params[:restaurant_id])
      	records = restaurant.order_reviews
      	render json: {
      		overall_rating_avg: restaurant.average_rating(:overall),
      		food_quality_rating_avg: restaurant.average_rating(:food_quality),
      		presentation_rating_avg: restaurant.average_rating(:presentation),
      		completeness_rating_avg: restaurant.average_rating(:completion),
      		on_time_percentage: restaurant.average_rating(:on_time),
    		order_reviews: records.as_json(:include => parsed_include_params, :methods => :reviewer_name) 
    	} and return
    else
      records = OrderReview.active
      render json: records.to_json(:include => parsed_include_params)
    end
  end
  
  def create
	review = OrderReview.new(create_params)
	review.assign_attributes(:status => OrderReview.statuses.key(Constants::STATUS_ACTIVE), :reviewer_type => '1')
	if review.save
		render json: { success: true, message: "Successfully created order", order_review: review }, status:200 and return
	end
	render json: { success: false, message: "An error occurred", errors: review.errors }, status:500 and return
  end
  
  private
  def create_params
  	params.permit(:order_id, :title, :food_quality, :presentation, :completion, :on_time, :comment, :reviewer_id)
  end
end