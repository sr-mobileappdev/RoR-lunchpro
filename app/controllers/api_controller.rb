class ApiController < ActionController::Base
  include Swagger::Blocks
  include Knock::Authenticable
  before_action :authenticate_user
  before_action :check_user_space
  undef_method :current_user
  rescue_from ActiveRecord::RecordNotFound, :with => :record_not_found
  
  def check_user_space
  		if current_user.present? && current_user.space_onboarding?
  			render json: { success: false, message: "Onboarding users are not permitted to use this endpoint" }, status: 401 and return
  		end
  end

  def authenticate_api_user
    v1_authenticate(params[:api_key])
  end

  def set_current_user
    @user_access_token = nil
    access_token = (params[:user_access_token].present?) ? params[:user_access_token] : request.headers['X-User-Access-Token']
    if access_token
      @user_access_token = access_token
    end

    @user_access_token
  end

  def verify_current_user
    @user_access_token = nil
    access_token = (params[:user_access_token].present?) ? params[:user_access_token] : request.headers['X-User-Access-Token']
    if access_token
      @user_access_token = access_token
    end

    user_token = UserAccessToken.where(access_token: @user_access_token, status: ['active']).first
    if user_token
      @current_user = user_token.user
    else
      @current_user = nil
    end

    @current_user
  end

  def authenticate_current_user
    unless @user_access_token.present?
      v1_invalid_current_user_response and return
    end

    user_token = UserAccessToken.where(access_token: @user_access_token, status: ['active','inactive']).first
    if user_token
      if user_token.active?
        return true
      else
        v1_invalid_current_user_response("You have been logged out. Please login again to continue.") and return
      end
    else
      v1_invalid_current_user_response and return
    end

    true
  end

  def required_params_are_present?(params_keys)
    params_keys.each do |k|
      return false unless params[k].present?
    end

    return true
  end


  def v1_authenticate(api_key = nil)
    is_authorized = false

    unless api_key
      api_key = (params[:api_key].present?) ? params[:api_key] : request.headers['X-Api-Key']
    end

    if api_key == nil
      v1_missing_auth_response and return
    end

    api_user = ApiUser.where(api_key: api_key).first
    if api_user
      api_user.touch!
      @api_user = api_user
      if api_user.is_enabled
        is_authorized = true
      else
        # Disabled API user
        v1_disabled_auth_response and return
      end
    else
      v1_unauthorized_response and return
    end

    is_authorized
  end


  # Default Responses for failure conditions

  def v1_unauthorized_response
    render :json => {message: 'Not Authorized, please check your api key'}, status: 401
  end

  def v1_disabled_auth_response
    render :json => {message: 'Your API key has been disabled. Please contact support for further details.'}, status: 401
  end

  def v1_unaccepted_response(error_code, message, errors = nil)
    resp = {error_code: error_code, message: message}
    resp[:errors] = errors if errors && errors.kind_of?(Array)

    render :json => resp, status: 406 # Not Acceptable
  end

  def v1_missing_auth_response
    render :json => {message: 'Not Authorized, missing api key as a parameter or header value'}, status: 401
  end

  def v1_invalid_current_user_response(message = nil)
    message ||= 'Not Authorized, a user access token is required for this call'
    render :json => {message: message}, status: 401
  end


  # API Response Scopes

  def define_scoped_params(include_params)
    scoped_params = nil
    if include_params.present?
      begin
        scoped_params = JSON.parse(params[:include_params])
      rescue Exception => ex
        scoped_params = nil
      end
    end

    scoped_params
  end
  
  def parsed_include_params #todo: when we have the time, let's make this recursive to go beyond child and grand child properties
  	to_return = {}
	if(params[:include].present? && params[:include].kind_of?(String))
		str_arr = params[:include].split(",")
		str_arr.each do |attr_name| 
			if attr_name.include?(".")
				attr_name_split = attr_name.split(".")
				if(attr_name_split.length == 2)
					parent_name = attr_name_split[0]
					child_name = attr_name_split[1]
					if !to_return[parent_name].present?
						to_return[parent_name] = { include: [child_name] }
					else
						to_return[parent_name][:include].push(child_name)
					end					
				end
			else
				if !to_return[attr_name].present?
					to_return[attr_name] = {}		
				end	
			end
		end
	end
	return to_return
  end

private

  def record_not_found(error)
    render :json => {:error => error.message}, :status => :not_found
  end

end
