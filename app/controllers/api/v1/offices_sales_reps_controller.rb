class Api::V1::OfficesSalesRepsController < ApiController

  	before_action :set_record, only: [:update, :destroy]

  	def set_record
    	@rep = OfficesSalesRep.active.find(params[:id])
  	end
	
	def create
	
		offices_sales_rep_to_create = OfficesSalesRep.new(:sales_rep_id => params[:sales_rep_id], :status => 1, :office_id => params[:office_id])
		
	#validate records
		form = Forms::Api::FormOfficesSalesRep.new(offices_sales_rep_to_create)
		
		unless form.valid?
  			render :json => {success: false, message: "Unable to associate sales rep with office due to the following errors or notices:", errors: form.errors}, status: 400
      		return
  		end
  	#save records
  		unless form.save?
      		render :json => {success: false, message: "Unable to associate sales rep with office at this time due to a server error.", errors: form.errors}, status: 500
      		return
    	end		
		
	#return new records
		render :json => { success: true, message: "Successfully associated the sales rep and office", offices_sales_rep: offices_sales_rep_to_create }
	end
	
	def destroy
		form = Forms::Api::FormOfficesSalesRep.new(@rep)
		
		unless form.soft_delete?
			render :json => { success: false, message: "An error occurred while trying to remove the association between sales rep and office." }, status: 400
		end
		
		render json: { success: true, message: "Successfully removed association between sales rep and office" } and return
	end
	
	def update
		@rep.assign_attributes(update_params)
	#validate records
		form = Forms::Api::FormOfficesSalesRep.new(@rep)
		
		unless form.valid?
  			render :json => {success: false, message: "Unable to update sales rep's office's information due to the following errors or notices:", errors: form.errors}, status: 400
      		return
  		end
  	#save records
  		unless form.save?
      		render :json => {success: false, message: "Unable to update sales rep's office's information at this time due to a server error.", errors: form.errors}, status: 500
      		return
    	end		
		
	#return updated records
		render :json => { success: true, message: "Successfully updated sales rep's office's information", offices_sales_rep: @rep }
	end
	
	private
	def update_params
		params.require(:offices_sales_rep).permit(:notes, :per_person_budget_cents)
	end
end