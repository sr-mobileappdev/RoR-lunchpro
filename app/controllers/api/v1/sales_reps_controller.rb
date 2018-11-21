class Api::V1::SalesRepsController < ApiController
  include SwaggerBlocks::SalesReps

  before_action :set_record, only: [:update, :show, :destroy, :upload_image, :update_rewards_email]
  skip_before_action :check_user_space, only: [:create, :index]

  def set_record
    @rep = SalesRep.active.find(params[:id])
  end
  
  def show
  	drug_sales_reps = []
  	@rep.drugs_sales_reps.active.each do |d|
  		drug_sales_reps << d.as_json(:include => "drug")
  	end
  	json = @rep.as_json().merge({ sales_rep_phones: @rep.sales_rep_phones.active, sales_rep_emails: @rep.sales_rep_emails.active, company: @rep.company, drugs_sales_reps: drug_sales_reps })
  	if params[:include].present? && params[:include].include?("payment_methods")
  		payment_methods = []
  		if @rep.user.present?
  			payment_methods = @rep.user.payment_methods.active
  		end
  		json = json.merge({payment_methods: payment_methods})
  	end
  	render json: json and return
  end

  def index
	records = []
	
	if(params[:partner_request_sales_rep_id].present?)
		records = SalesRep.find(params[:partner_request_sales_rep_id]).eligible_partners
	elsif params[:email_address].present? && params[:first_name].present? && params[:phone].present? && params[:last_name].present?		
		records += SalesRep.match_email_phone_name(params[:email_address], params[:phone], params[:first_name], params[:last_name])
	else
		records = SalesRep.active.eager_load(:sales_rep_phones, :sales_rep_emails, :user)
	end
		
    render json: records.to_json(:include => parsed_include_params) and return
  end
  
  def update
  	@rep.assign_attributes(update_params)
  	phones = []
  	emails = []
  	drugs = []
  	if params[:sales_rep_phone].present? 
  		phones << SalesRepPhone.new(:sales_rep_id => @rep.id, :phone_number => params[:sales_rep_phone], :phone_type => SalesRepPhone.phone_types[:business], :status => 1)
  	end
  	if params[:sales_rep_email].present?
  		emails << SalesRepEmail.new(:sales_rep_id => @rep.id, :email_address => params[:sales_rep_email], :email_type => SalesRepEmail.email_types[:business], :status => 1)
  	end
  	if params[:drugs_sales_reps].present? && params[:drugs_sales_reps].kind_of?(Array)
  		params[:drugs_sales_reps].each do |drug|
  			drugs << DrugsSalesRep.new(:sales_rep_id => @rep.id, :drug_id => drug[:drug_id], :status => 1)
  		end
  	end
  	form = Forms::Api::FormSalesRep.new(@rep, emails, phones, drugs, params[:user_primary_phone])
  	
  #validate records
  	unless form.valid?
  		render :json => {success: false, message: "Unable to update the sales rep due to the following errors or notices:", errors: form.errors}, status: 400
      	return
  	end
  	
  #save records
  	unless form.save?
      render :json => {success: false, message: "Unable to update the sales rep at this time due to a server error.", errors: form.errors}, status: 500
      return
    end
    
    #return updated record
	render json: { success: true, message: "Successfully updated the sales rep.", sales_rep: @rep } and return
  end
  
  def update_rewards_email
  	if params[:rewards_email].present?
  		existing_email = @rep.sales_rep_emails.where(:email_type => 'personal', :status => 'active').first
  		if existing_email.present?
  			existing_email.assign_attributes(:email_address => params[:rewards_email])
  			if !existing_email.save
  				render json: { success: false, message: "Unable to update the rewards email due to the following errors:", errors: existing_email.errors.full_messages }, status: 500
  				return
  			else
  				render json: { success: true }, status: 200
  				return
  			end
  		else
	  		new_email = SalesRepEmail.new(:sales_rep_id => @rep.id, :email_address => params[:rewards_email], :email_type => SalesRepEmail.email_types[:personal], :status => 1)
	  		if !new_email.save
  				render json: { success: false, message: "Unable to update the rewards email due to the following errors:", errors: new_email.errors.full_messages }, status: 500
  				return
  			else
  				render json: { success: true }, status: 200
  				return
  			end
  		end
  	else
  		render json: { success: false, message: "The rewards_email parameter is required" }, status: 400
  		return
  	end
  end
  
  def create
  	errors = []
  	if params[:email_address].present? && params[:first_name].present? && params[:last_name].present? && params[:phone_number].present?
  		sales_rep = nil
  		sales_rep_email = nil
  		sales_rep_phone = nil
  		success = false
  		ActiveRecord::Base.transaction do  			
  			 	sales_rep = SalesRep.new(:first_name => params[:first_name], :last_name => params[:last_name], :company_id => params[:company_id], :status => SalesRep.statuses.key(Constants::STATUS_ACTIVE))
  			 	
  			 	sales_rep_email = SalesRepEmail.new(:sales_rep => sales_rep, :email_address => params[:email_address], :status => SalesRepEmail.statuses.key(Constants::STATUS_ACTIVE))
  			 	sales_rep_phone = SalesRepPhone.new(:sales_rep => sales_rep, :phone_number => params[:phone_number], :phone_type => 2, :status => SalesRepPhone.statuses.key(Constants::STATUS_ACTIVE))
  		 		user = User.new(:space => 2, :first_name => params[:first_name], :last_name => params[:last_name], :status => User.statuses.key(Constants::STATUS_ACTIVE), :primary_phone => params[:phone_number], :email => params[:email_address])
  		 		# set password
  		 		generated_password = Devise.friendly_token.first(8)
  		 		user.assign_attributes(:password => generated_password)
		    	user.skip_invitation
      			user.skip_confirmation_notification!
  		 		sales_rep.user = user
  		 		if sales_rep.save && sales_rep_email.save && sales_rep_phone.save && user.save
      				user_prefs = UserNotificationPref.new(:status => 'active', :user_id => user.id, :last_updated_by_id => user.id,	:via_email => User.default_rep_notifications(true), :via_sms => User.default_rep_notifications(false))
    				if user_prefs.save
  		 				success = true  
  		 			else
  		 				raise ActiveRecord::Rollback
  		 			end
  		 		else
  		 			errors += user.errors.full_messages
  		 			errors += sales_rep.errors.full_messages
  		 			errors += sales_rep_email.errors.full_messages
  		 			errors += sales_rep_phone.errors.full_messages
                   raise ActiveRecord::Rollback		 		
  		 		end  		 	
  		end
  		
  		if success
  			render :json => {success: success, sales_rep: sales_rep, sales_rep_email: sales_rep_email, sales_rep_phone: sales_rep_phone}, status: 200
      		return
      	end
  	end
  	errors << "Email, first and last name, and phone number are required"
  	render :json => {success: false, message: errors[0], errors: errors}, status: 400
    return
  end
  
  def appointment_date_range
  	if params[:sales_rep_id].present?
  		@rep = SalesRep.find(params[:sales_rep_id])
  		appointments = @rep.appointments.where.not(status: ['inactive', 'deleted']).where.not("appointment_on < ? AND (rep_confirmed_at IS NULL OR NOT (food_ordered OR will_supply_food))", Time.now.utc.to_date).order(:appointment_on)
  		first_appt = appointments.first
  		last_appt = appointments.last
  		first_date = nil
  		last_date = nil
  		if first_appt.present?
  			first_date = first_appt.appointment_on
  		end
  		if last_appt.present?
  			last_date = last_appt.appointment_on
  		elsif first_appt.present?
  			last_date = first_appt.appointment_on
  		end
  		to_return = { "earliest_date" => first_date, "latest_date" => last_date }
  		render json: to_return and return 
  	else
  		render :json => {success: false, message: "A Sales Rep's id is required"}, status: 400
    	return
  	end
  end
  
  def update_params
  	params.require(:sales_rep).permit(:default_tip_percent, :max_tip_amount_cents, :per_person_budget_cents, :company_id, :first_name, :last_name, :address_line1, :address_line2, :city, :state, :postal_code)
  end
  
  def destroy
  	if !@rep.user.present?
  		render json: { success: false, message: "An error occurred while deactivating the sales rep." }, status: 400 and return
  	end
  	
	form = Forms::User.new(@rep.user, @rep.user)
  	unless form.delete_account
		render :json => { success: false, message: "An error occurred while deactivating the sales rep." }, status: 500 and return
	end
	render json: { success: true, message: "Successfully deactivated the sales rep." } and return
  end
  
  def upload_image
  	image_from_client = parse_image_data(params[:profile_image], params[:upload_content_type])
  	if @rep.update(:profile_image => image_from_client)
  		clean_tempfile
  		render :json => {success: true }, status: 200
    	return
  	else
  		clean_tempfile
  		render :json => {success: false }, status: 500
    	return
  	end
  end

  def parse_image_data(base64_image, content_type)
    filename = "profile-image"
    in_content_type, encoding, string = base64_image.split(/[:;,]/)[1..3]

    @tempfile = Tempfile.new(filename)
    temp_file_path = @tempfile.path
    @tempfile.binmode
    @tempfile.write Base64.decode64(string)
    @tempfile.rewind
    
    # we will also add the extension ourselves based on the above
    # if it's not gif/jpeg/png, it will fail the validation in the upload model
    extension = content_type.match(/gif|jpeg|png/).to_s
    filename += ".#{extension}" if extension
    ActionDispatch::Http::UploadedFile.new({
      tempfile: @tempfile,
      content_type: content_type,
      filename: filename
    })    
  end
  
  def clean_tempfile
    if @tempfile
      @tempfile.close
      @tempfile.unlink
    end
  end
end
