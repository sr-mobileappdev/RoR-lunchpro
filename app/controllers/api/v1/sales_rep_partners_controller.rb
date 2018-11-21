class Api::V1::SalesRepPartnersController < ApiController

  before_action :set_record, only: [:update, :destroy, :show]
  
  def set_record
  	@partner = SalesRepPartner.find(params[:id])
  end
  
  def show
  	render json: @partner.as_json(:include => ["sales_rep","partner"])
  end
  
  def index
  	records = []
  	filtered_partners = []
  	
  	if params[:sales_rep_id].present?
  		if params[:partner_id].present?
  			filtered_partners = SalesRepPartner.where(:sales_rep_id => params[:sales_rep_id], :status => [Constants::STATUS_PENDING], :partner_id => params[:partner_id])
  		else
  			filtered_partners = SalesRepPartner.where(:sales_rep_id => params[:sales_rep_id], :status => [Constants::STATUS_COMPLETED]).or(SalesRepPartner.where(:partner_id => params[:sales_rep_id], :status => [Constants::STATUS_PENDING]))
  		end
  	elsif(params[:partner_request_sales_rep_id].present?)
  		records = SalesRep.find(params[:partner_request_sales_rep_id]).eligible_partners
  	else
  		filtered_partners = SalesRepPartner.where.not(:status => Constants::STATUS_DELETED)
  	end
  	
  	filtered_partners.each do |p|
  		records << p.as_json(:except => ["partner","sales_rep"]).merge({ 
  			partner: p.partner.as_json().merge({ company: p.partner.company, sales_rep_phones: p.partner.sales_rep_phones.active, sales_rep_emails: p.partner.sales_rep_emails.active }), 
  			sales_rep: p.sales_rep.as_json().merge({ company: p.sales_rep.company, sales_rep_phones: p.sales_rep.sales_rep_phones.active, sales_rep_emails: p.sales_rep.sales_rep_emails.active })
  		})
  	end
  	
  	render json: records and return
  end

  def create
  	unless params[:partner_email].present?
  		render json: { success: false, message: "Partner email was not received by server", errors:["Partner email was not received by server"]}, status: 400 and return
  	end
  	
  	sales_rep_users = User.joins(sales_rep: :sales_rep_emails).where(:status => Constants::STATUS_ACTIVE, :space => 2)
  	partner_user = nil
  	sales_rep_users.each do |sru|
  		if (sru.email.present? && sru.email.downcase == params[:partner_email].downcase) ||
  			(sru.sales_rep.present? && sru.sales_rep.sales_rep_emails.present? && sru.sales_rep.sales_rep_emails.any? { |sr_email| sr_email.email_address.present? && sr_email.email_address.downcase == params[:partner_email].downcase })
  			partner_user = sru
  		end
  	end
  	
  	if !partner_user.present?
  		render json: { success: false }, status: 200 and return
  	end
  	
	partner_to_create = SalesRepPartner.new(:status => Constants::STATUS_PENDING, :sales_rep_id => params[:sales_rep_id], :partner_id => partner_user.sales_rep.id)
	
	form = Forms::Api::FormSalesRepPartner.new(partner_to_create)
  #validate records  	
  	unless form.valid?
  		render :json => {success: false, message: "Unable to create the association between the two sales reps due to the following errors or notices:", errors: form.errors}, status: 400
      	return
  	end
  #save records
  	unless form.save?
      render :json => {success: false, message: "Unable to create the association between the two sales reps at this time due to a server error.", errors: form.errors}, status: 500
      return
    end
    
    #return updated record
	render json: { success: true, message: "Successfully create the association between the two sales reps.", sales_rep_partner: partner_to_create } and return	
  end
  
  def create_params
  	params.require(:sales_rep_partner).permit(:sales_rep_id, :partner_id)
  end
  
  def update
  	if(update_params[:status] == Constants::STATUS_DELETED)
  		render :json => {success: false, message: "Please, use DELETE /sales_rep_partners for deletion", errors: form.errors}, status: 400 and return
  	end
  	
  	@partner.assign_attributes(update_params)
  	
  	form = Forms::Api::FormSalesRepPartner.new(@partner)
  #validate records  	
  	unless form.valid?
  		render :json => {success: false, message: "Unable to update the association between the two sales reps due to the following errors or notices:", errors: form.errors}, status: 400
      	return
  	end
  #save records
  	unless form.save?
      render :json => {success: false, message: "Unable to update the association between the two sales reps at this time due to a server error.", errors: form.errors}, status: 500
      return
    end
    
    if update_params[:status] == Constants::STATUS_COMPLETED
    	Managers::NotificationManager.trigger_notifications([214], [@partner.sales_rep, @partner])
    end
    
    #return updated record
	render json: { success: true, message: "Successfully updated the association between the two sales reps.", sales_rep_partner: @partner } and return
  end
  
  def update_params
    params.require(:sales_rep_partner).permit(:status)
  end
  
  def destroy
  	@partner.assign_attributes(:status => Constants::STATUS_DELETED)
  	form = Forms::Api::FormSalesRepPartner.new(@partner)
  	unless form.soft_delete?
		render :json => { success: false, message: "An error occurred while trying to remove the association between the 2 sales reps." }, status: 400
	end
		
	render json: { success: true, message: "Successfully removed association between the 2 sales reps." } and return
  end
end