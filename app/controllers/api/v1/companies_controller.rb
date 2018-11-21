class Api::V1::CompaniesController < ApiController

skip_before_action :check_user_space, only: [:index]

	def index
		records = []
	
		records = Company.active
		
    	render json: records.to_json(:include => parsed_include_params) and return
	end

end