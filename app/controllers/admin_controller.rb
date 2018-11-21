class AdminController < ActionController::Base
  protect_from_forgery with: :exception
  layout "admin"

  skip_before_action :verify_authenticity_token, if: :json_request?

  before_action :authenticate_admin_user!
  before_action :store_location
  around_action :set_time_zone, if: :current_user
  before_action :set_is_xhr

  def authenticate_admin_user!

    authenticate_user!

    if user_signed_in? && current_user.deactivated_at
      sign_out(current_user)
      authenticate_user!
    end

    unless current_user && current_user.space_admin?
      sign_out(current_user)
      redirect_to new_user_session_path, notice: 'You are not signed in as admin. Please sign in to continue.'
    end

  end

  def set_is_xhr
    if request.xhr?
      @xhr = true
    else
      @xhr = false
    end
  end

  def set_time_zone(&block)
    time_zone = current_user.timezone || "Central Time (US & Canada)"
    Time.use_zone(time_zone, &block)
  end

  def store_location
    return unless request.get?
    if (request.path != "/users/sign_in" &&
        request.path != "/users/sign_up" &&
        !request.path.match(%r{/users/auth}) &&
        request.path != "/users/password/new" &&
        request.path != "/users/password/edit" &&
        request.path != "/users/confirmation" &&
        request.path != "/users/sign_out" &&
        request.path != "/auth/welcome" &&
        request.path != "/auth/authorize" &&
        !request.xhr?) # don't store ajax calls
      session[:previous_url] = request.fullpath
    end
  end

  def json_request?
    request.format.json?
  end

  def allowed_params(groupings, params)

    allowed = {}
    groupings.each do |param_group|
      next unless params[param_group]

      if params[param_group].kind_of?(Array)
        allowed[param_group] = params[param_group].map do |p|
          p.permit!
        end
      else
        allowed[param_group] = params.fetch(param_group, {}).permit!
      end

      allowed[param_group].select { |k, v| k.include?("_cents") }.each do |ar_k, val|
        allowed[param_group][ar_k] = (val.to_f * 100).ceil
      end

      allowed[param_group].select { |k, v| k.include?("_percent") }.each do |ar_k, val|
        allowed[param_group][ar_k] = (val.to_f * 100).ceil
      end

      allowed[param_group].select { |k, v| k.include?("_attributes") }.each do |ar_k, val|
        allowed[param_group][ar_k] = transform_attributes(val)
      end

    end
    authed_params = ActionController::Parameters.new(allowed)
    authed_params

  end

  def transform_attributes(attribute_group)
    return attribute_group unless attribute_group && attribute_group.kind_of?(ActionController::Parameters)
    attribute_group_allowed = {}
    attribute_group_allowed = attribute_group


    attribute_group_allowed.each do |key, attrib_value| # key = 0, 1, 2, etc
      attrib_value.select { |k, v| k.include?("_cents") }.each do |ar_k, val|
        attribute_group_allowed[key][ar_k] = (val.to_f * 100).ceil
      end

      attrib_value.select { |k, v| k.include?("_percent") }.each do |ar_k, val|
        attribute_group_allowed[key][ar_k] = (val.to_f * 100).ceil
      end

      attrib_value.select { |k, v| k.include?("_attributes") || k.include?("[]") }.each do |ar_k, val|
        attribute_group_allowed[key][ar_k] = transform_attributes(val)
      end

    end

    return attribute_group_allowed
  end

end
