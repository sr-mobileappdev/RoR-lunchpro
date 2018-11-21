class Api::V1::OfficeReferralsController < ApiController

  
  def create
  	sales_rep = SalesRep.find(params[:sales_rep_id])
	new_referral = OfficeReferral.new(:created_by_id => sales_rep.user_id)
	if new_referral.update(create_params)
		render json: { success: true, message: "Successfully referred the office.", office_referral: new_referral }, status: 200 and return	
	else
		render json: { success: false, message: "An error occurred referring the office", errors: new_referral.errors.full_messages }, status: 401 and return
	end
  end
  
  def create_params
  	params.require(:office_referral).permit(:name, :phone, :email)
  end
end