class Api::V1::PaymentMethodsController < ApiController

	before_action :set_record, only: [:destroy, :update, :set_default, :show]

	def set_record
    	@payment_method = PaymentMethod.active.find(params[:id])
  	end
  
	def create
		custom_create_params = Hash.new
  		custom_create_params[:address_line1] = params[:address_line1]
  		custom_create_params[:address_line2] = params[:address_line2]
  		custom_create_params[:address_city] = params[:city]
  		custom_create_params[:address_state] = params[:state]
  		custom_create_params[:address_zip] = params[:postal_code]
  		custom_create_params[:name] = params[:cardholder_name]
  		custom_create_params[:default] = params[:default]
  		custom_create_params[:nickname] = params[:nickname]
		sales_rep = SalesRep.find(params[:sales_rep_id])
		record = PaymentMethod.new
    	payment_manager = Managers::PaymentManager.new(sales_rep.user, nil, record)
    	result = payment_manager.create_stripe_card(params[:card_token], false, custom_create_params, false, nil)
    	if result
    		render json: { success: true, message: "Successfully created the payment method" }, status: 200 and return
    	else
    		render json: { success: false, errors: payment_manager.errors }, status: 500 and return
    	end
	end
	
	def show
		render json: @payment_method and return
	end
	
	def index
    	records = []
		if params[:sales_rep_id].present?
			sales_rep = SalesRep.find(params[:sales_rep_id])
			records = sales_rep.user.payment_methods.active		
		end
    	render json: records and return
  	end
  	
  	def destroy
	  	new_default = nil
    	if @payment_method.default && @payment_method.user.payment_methods.active.count > 1     
      		new_default = @payment_method.user.non_default_payment_methods.first
    	end
    	payment_manager = Managers::PaymentManager.new(@payment_method.user, nil, @payment_method)
  		success = false
	  	ActiveRecord::Base.transaction do  	    
	    	@payment_method.assign_attributes(:status => 'inactive')
	    	unless @payment_method.save
	      		message = @payment_method.errors.full_messages.first
	      		render :json => {success: false, message: message, errors: @payment_method.errors.full_messages}, status: 500
	      		return
 		   	end
 		   	result = payment_manager.delete_stripe_card(new_default)
  		  	if result
  		  		success = true
  		  	else
  		  		raise ActiveRecord::Rollback
    		end
    	end
    	if success
    		render :json => {success: true }, status: 200 
    		return
 	   	else
  	 		render :json => {success: false, errors: payment_manager.errors }, status: 500 
    		return
    	end
  	end
  	
  	def update
  		payment_manager = Managers::PaymentManager.new(@payment_method.user, nil, @payment_method)
  		custom_update_params = Hash.new
  		custom_update_params[:address_line1] = params[:address_line1]
  		custom_update_params[:address_line2] = params[:address_line2]
  		custom_update_params[:address_city] = params[:city]
  		custom_update_params[:address_state] = params[:state]
  		custom_update_params[:address_zip] = params[:postal_code]
  		custom_update_params[:name] = params[:cardholder_name]
  		custom_update_params[:exp_month] = params[:expire_month]
  		custom_update_params[:exp_year] = params[:expire_year]
  		custom_update_params[:default] = params[:default]
  		custom_update_params[:nickname] = params[:nickname]
    	unless payment_manager.update_stripe_card(custom_update_params) # params is payment_params plus default
      		render :json => {success: false, message: "Unable to update payment method due to the following errors or notices:", errors: payment_manager.errors}, status: 500
      		return
    	end

    	unless @payment_method.update_attributes!(update_params)
      		render :json => {success: false, message: "Unable to update payment method due to the following errors or notices:", errors: @payment_method.errors.full_messages}, status: 500
      		return
    	end
    	render :json => {success: true }, status: 200 and return
  	end
  	
  	def set_default
  		payment_manager = Managers::PaymentManager.new(@payment_method.user, nil, @payment_method)
  		unless payment_manager.set_default_payment_method
      		render :json => {success: false, message: "Unable to delete payment method to sales rep due to the following errors or notices:", errors: payment_manager.errors}, status: 500
      		return
    	end
    	
    	render :json => {success: true }, status: 200
      	return	
  	end
	
private

  	def update_params
    	params.permit(:cardholder_name, :expire_month, :expire_year, :address_line1, :address_line2, :city, :state, :postal_code)
  	end
end