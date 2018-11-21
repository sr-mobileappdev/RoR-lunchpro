class Api::V1::RestaurantsController < ApiController
  include SwaggerBlocks::Restaurants
  
  skip_before_action :check_user_space, only: [:index, :show]
  
  def show
  	@restaurant = Restaurant.find(params[:id])
  	if !@restaurant.present?
  		render json: { success: false }, status: 404 and return
  	end
  	render json: { restaurant: @restaurant.slice(:id, :name) }, status: 200 and return
  end
  
  def index

    @scoped_params = define_scoped_params(params[:include_params])
    
    @sales_rep = nil
    
	filtered_restaurants = []
    records = []

    if params[:appointment_id].present?
    
      appt = Appointment.find(params[:appointment_id])
      
      @sales_rep = appt.sales_rep
      
      filtered_restaurants = appt.office.filtered_available_restaurants(appt,nil)
    else
      filtered_restaurants = Restaurant.active.eager_load(:cuisines, orders: :order_reviews)
    end
    
    if params[:recommended_cuisine_ids].present?
    	recommended_cuisine_ids = params[:recommended_cuisine_ids].split(',').map{ |id| id.to_i }
    	filtered_restaurants = filtered_restaurants.select{ |r|
    		intersection = (r.cuisines.pluck(:id) & recommended_cuisine_ids)
    		intersection.any?
    	}
    end
    
    sort_by_relevance = params[:order_property].present? && @sales_rep.present? && params[:order_property].is_a?(String) && params[:order_property].downcase == 'relevance'
    
    filtered_restaurants.each do |r|
    	record = r.as_json(:methods => [:average_overall_rating, :order_reviews_length, :average_on_time, :average_person_price]).merge({ cuisines: r.cuisines.select{|c|c.status == 'active'} })
    	if sort_by_relevance
    		record = record.merge({ relevance: r.relevance(@sales_rep) })
    	end
    	records << record
    end
    
    if(params[:order_property].present?)
    	if params[:order_descending].present?
    		records = records.sort{ |a,b| b[params[:order_property]] <=> a[params[:order_property]] }
    	else
    		records = records.sort{ |a,b| a[params[:order_property]] <=> b[params[:order_property]] }
    	end
    end    
    
    render json: records and return
  end
  
end
