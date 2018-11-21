class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception

  skip_before_action :verify_authenticity_token, if: :json_request?

  before_action :store_location
  around_action :set_time_zone, if: :current_user
  before_action :set_is_xhr

  before_action :set_impersonator

  before_action :set_layout

  after_action :touch_user

  layout "application"


  def set_impersonator
    if session[:impersonator_id]
      @impersonator = User.where(:id => session[:impersonator_id]).first
    end
  end

  def touch_user
    if current_user
      if current_user.space_sales_rep? && current_user.sales_rep
        current_user.sales_rep.touch(:updated_at)
      else
        current_user.touch(:updated_at)
      end
    end
  end

  def set_layout
    @layout = "application"
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
        request.path != "/users/invitation" &&
        request.path != "/users/invitation/accept" &&
        !request.xhr?) # don't store ajax calls
      session[:previous_url] = request.fullpath
    end
  end

  def after_sign_in_path_for(resource)
    if session[:previous_url] && session[:previous_url] != "/"
      session[:previous_url]
    else
      if resource.space_admin?
        admin_users_path
      elsif resource.space_office?
        current_office_calendars_path
      elsif resource.space_sales_rep?
        current_rep_calendars_path
      elsif resource.space_restaurant?
        if resource.restaurant_manager?
          select_restaurant_restaurant_account_index_path
        else
          restaurant_orders_path # NEED TO CHANGE
        end
      else
        admin_root_path # NEED TO CHANGE
      end
    end
  end

  def after_sign_out_path_for(resource)
    session[:logged_in_as] = nil
    root_path
  end

  def json_request?
    request.format.json?
  end

end
