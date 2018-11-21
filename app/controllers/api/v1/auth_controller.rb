class Api::V1::AuthController < ApiController
  include SwaggerBlocks::Auth
  skip_before_action :authenticate_user, only: [:register, :password]
  skip_before_action :check_user_space, only: [:register]
  def login
    unless params[:email].present? && params[:password].present?
      v1_unaccepted_response("AUTH-001-Missing", "Missing required email and/or password login parameter") and return
    end

    user = User.active.where(email: params[:email]).first
    if user && user.valid_password?(params[:password])
      unless user.sales_rep
        v1_unaccepted_response("AUTH-003-MissingSalesRep", "Attempting to login with a user account that is not a sales rep. Only sales rep accounts can login to the app at this time.") and return
      end

      @record = user
      token = @record.generate_access_token

      # Success Response
      response_summary = {} #response_summary = {count: records.count, total_count: records.total_count, page: @page, total_pages: records.total_pages}
      render json: {meta: response_summary, user_access_token: token, sales_rep: SalesRepsSerializer.new(@record.sales_rep)} and return

    else
      v1_unaccepted_response("AUTH-002-LoginFailure", "Incorrect email address and / or password.") and return
    end
  end

  def register
    unless required_params_are_present?([:email, :password, :first_name, :last_name])
      v1_unaccepted_response("AUTH-001-Missing", "Missing required paramters") and return
    end
    
    existing_sales_rep = nil
    if params[:existing_sales_rep_id].present?
    	existing_sales_rep = SalesRep.find(params[:existing_sales_rep_id])
    else
    	existing_sales_reps = SalesRep.match_email_phone_name(params[:email], params[:primary_phone], params[:first_name], params[:last_name])
    	if existing_sales_reps.any? && existing_sales_reps.first.non_lp
    		existing_sales_rep = existing_sales_reps.first
    	end
    end

    form = Forms::ApiSalesRep.new(permitted_params, @company, existing_sales_rep)

    if form.save
      token = form.user.generate_access_token
	  Managers::NotificationManager.trigger_notifications([209], [form.sales_rep, form.sales_rep.user])
      # Success Response
      response_summary = {} #response_summary = {count: records.count, total_count: records.total_count, page: @page, total_pages: records.total_pages}
      render json: {meta: response_summary, user_access_token: token, sales_rep: SalesRepsSerializer.new(form.sales_rep)} and return

    else
      v1_unaccepted_response("AUTH-004-Failure", "Unable to register account due to the following errors", form.errors) and return
    end
  end

  def status
    user_token = UserAccessToken.where(access_token: params[:user_access_token], status: ['active','inactive']).first
    if user_token
      message = user_token.message
      response = {is_active: (user_token.active?), status_message: message}

      render json: response and return
    else
      v1_unaccepted_response("AUTH-003-NotFound", "User access token was not found or has been deleted. Please login again.") and return
    end
  end

  def profile
    if current_user
      response = {sales_rep: SalesRepsSerializer.new(current_user.sales_rep)}
      render json: response and return
    else
      v1_unaccepted_response("AUTH-003-NotFound", "User access token was not found or has been deleted. Please login again.") and return
    end
  end

  def password
    @email = params[:email]

    user = User.find_match(email: @email).first

    response = {}
    if user
      user.send_reset_password_instructions
      response = {message: 'Password reset email has been sent to the user with this email. Please follow the instructions in that email to reset your password.'}
    else
      response = {message: 'No active user found with this email.'}
    end

    render json: response and return
  end

  def change
    # Only sales reps can update their accounts via API
    if current_user
      unless current_user.sales_rep
        v1_unaccepted_response("AUTH-006-NoSalesRep", "There is no sales rep related to this login. Please contact support.") and return
      end
      # Update the user and the sales rep record

      errors = []
      ActiveRecord::Base.transaction do
        if current_user.update(permitted_params) && current_user.sales_rep.update(permitted_sales_rep_params)
          sales_rep = current_user.sales_rep
          sales_rep.reload
          response = {message: 'Sales rep has been updated.', sales_rep: SalesRepsSerializer.new(sales_rep)}
          render json: response and return
        else
          errors = current_user.errors + current_user.sales_rep.errors
          raise ActiveRecord::Rollback
        end
      end
      v1_unaccepted_response("AUTH-004-Failure", "Unable to update account due to the following errors", errors) and return
    else
      v1_unaccepted_response("AUTH-003-NotFound", "User access token was not found or has been deleted. Please login again.") and return
    end

  end


  def index

  end

  def permitted_params
    params.permit(:first_name, :last_name, :email, :password, :password_confirmation, :company_id, :primary_phone, :company, :sales_rep_phone, :address_line1, :address_line2, :city, :state, :postal_code)
  end

  def permitted_sales_rep_params
    params.permit(:first_name, :last_name, :company_id)
  end

end
