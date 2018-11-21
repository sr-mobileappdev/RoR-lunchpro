class ApplicationOfficesController < ApplicationController
  before_action :authorize_office_manager
  before_action :set_ui_space

  before_action :set_layout

  def set_layout
    @layout = "office"
  end

  def set_ui_space
    @ui_space = "office"
  end

  def authorize_office_manager

    authenticate_user!
    
    if user_signed_in? && current_user.deactivated_at
      sign_out(current_user)
      authenticate_user!
    end

    unless current_user && current_user.space_office?
      if current_user && current_user.space_admin?
        redirect_to admin_root_path
      elsif current_user && current_user.space_sales_rep?
        redirect_to current_rep_calendars_path
      elsif current_user && current_user.space_restaurant?
        redirect_to admin_root_path
      else
        sign_out(current_user)
        redirect_to new_user_session_path, notice: 'You are not signed in as an office manager. Please sign in to continue.'
      end
    end
  end

  def modal?
    params[:is_modal].present?
  end

  def redirect_to_tab(tab)
    case tab
    when "calendar"
      redirect_to current_office_calendars_path
    when "policies"
      redirect_to policies_office_preferences_path
    when "directory"
      redirect_to directory_office_preferences_path
    end
  end

  private
  def transform_attributes(attribute_group)
    return attribute_group unless attribute_group && attribute_group.kind_of?(ActionController::Parameters)
    attribute_group_allowed = {}
    attribute_group_allowed = attribute_group


    attribute_group_allowed.each do |key, attrib_value| # key = 0, 1, 2, etc
      attrib_value.select { |k, v| k.include?("_cents") }.each do |ar_k, val|
        attribute_group_allowed[key][ar_k] = (val.to_f * 100).ceil if val.present?
      end

      attrib_value.select { |k, v| k.include?("_percent") }.each do |ar_k, val|
        attribute_group_allowed[key][ar_k] = (val.to_f * 100).ceil if val.present?
      end

      attrib_value.select { |k, v| k.include?("_attributes") || k.include?("[]") }.each do |ar_k, val|
        attribute_group_allowed[key][ar_k] = transform_attributes(val)
      end

    end

    return attribute_group_allowed
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

end
