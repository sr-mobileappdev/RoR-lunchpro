class Api::V1::DrugsController < ApiController

	def index
		records = []
	
		records = Drug.active
		
    	render json: records.to_json(:include => parsed_include_params) and return
	end
	
	def create
		new_drug = Drug.new(:brand => params[:brand])
		if !new_drug.save
			render json: {success: false, message: "An error occurred while trying to create the drug", errors: new_drug.errors.full_messages}, status: 500
			return
		else
			render json: {success: true, drug: new_drug}, status: 200
			return
		end
	end
end