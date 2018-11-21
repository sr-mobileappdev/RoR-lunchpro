class Restaurant::AccountController < ApplicationRestaurantsController

  before_action :set_restaurant_user
  before_action :set_restaurant
  before_action :set_user

  def set_restaurant_user
    @restaurant_user = UserRestaurant.find_by(user_id: current_user.id)
    @consolidated = session[:hq_consolidated_view]
  end

  def set_restaurant
    @restaurant = Restaurant.find((current_restaurant_id || @restaurant_user.restaurant_id))
  end

  def set_user
    @user = current_user
  end

  def index
    @show_tab = params[:tab] || "summary"
  end

  def update_password
    form = Forms::User.new(@restaurant_user.user, user_params, current_user)

    if form.change_password?
      bypass_sign_in(@restaurant_user.user)
      redirect_to restaurant_account_index_path
    else
      render :json => { success: false, general_error: "Unable to update the password due to the following errors or notices:", errors: form.errors}, status: 500
      return
    end

  end

  def end_impersonation
    impersonator = User.where(:id => session[:impersonator_id]).first
    return_url = session[:impersonator_return_url]
    signed_out = (Devise.sign_out_all_scopes ? sign_out : sign_out(:user))
    return if !impersonator
    sign_in(:user, impersonator)
    redirect_to return_url
  end


  def delete_account
    form = Forms::User.new(current_user, current_user)
    unless form.delete_account
      flash[:warning] = "There was an error processing your request. Please contact customer support for assistance."
    end
    flash[:success] = "Account was successfully deleted!"
    sign_out current_user
    redirect_to new_session_path('user')
  end


  def set_current_restaurant
    restaurant_id = params[:user_restaurant][:current_restaurant_id]
    if restaurant_id.present?
      if restaurant_id == 'consolidated'
        set_current_restaurant_id(@restaurant_user.restaurant_id, true)
        flash[:success] = "Restaurant has been set"
        return redirect_to restaurant_orders_path
      else
        if set_current_restaurant_id(restaurant_id, false)
          flash[:success] = "Restaurant has been set"
          return redirect_to restaurant_orders_path
        else
          render :json => {success: false, general_error: "Unable to set current restaurant at this time due to a server error."}, status: 500
          return
        end
      end
    else
      render :json => {success: false, general_error: "Unable to set current restaurant due to the following errors or notices:",
        errors: ["You must select a restaurant."]}, status: 500
      return
    end

  end

  def update
    tab = params[:for]
    form = Forms::FrontendRestaurant.new(@restaurant, allowed_params, params[:for])
    if tab == "summary"
      unless form.valid?
        render :json => {success: false, general_error: "Unable to update restaurant due to the following errors or notices:", errors: form.errors}, status: 500
        return
      end
    end
    # Model validations & save
    if form.save
      render json: { success: true }
      return
    else
      render :json => { success: false, general_error: "Unable to update restaurant at this time due to a server error.", errors: [] }, status: 500
      return
    end

  end

  def update_pocs

  form = Forms::RestaurantManagers::RestaurantContact.new(@restaurant, contact_params)

    if form.valid? && form.save
      flash[:success] = "Point of contacts have been updated!"
      redirect_to restaurant_account_index_path(tab: 'contact_information')
      return
    else
      render json: { success: false, general_error: "Unable to update restaurant due to the following errors or notices:", errors: form.errors}, status: 500
      return
    end



  end

  def update_notification_prefs
    user_notification_prefs = current_user.user_notification_prefs.active.first
    if !user_notification_prefs.present?
      user_notification_prefs = UserNotificationPref.new(allowed_notification_prefs_params)
    else
      user_notification_prefs.assign_attributes(allowed_notification_prefs_params)
    end
    user_notification_prefs.save!


    flash[:success] = "Notification Preferences have been updated!"
    redirect_to restaurant_account_index_path(tab: "notifications")
  end

  #used for restaurant_managers to select which restaurant they'd like to manipulate
  def select_restaurant
    if current_user.restaurant_manager?
      unless @restaurant.restaurants.count != 0 || @restaurant.headquarters
        redirect_to restaurant_orders_path
        return
      end
    else
      redirect_to restaurant_orders_path
      return
    end
  end

  def summary
    @name = @restaurant.name.to_json
    @address = @restaurant.address_line1.to_json
    # Need phone number for restaurant. Need to look at how the sales rep phone number is handled
    render json: {
      templates: {
        targ__restaurant_account: (render_to_string :partial => 'restaurant/account/components/account__detail_summary', :layout => false, :formats => [:html])
      }
    }
  end

  def change_password

    render json: {
      templates: {
        targ__restaurant_account: (render_to_string :partial => 'restaurant/account/components/account__detail_change_password', :layout => false, :formats => [:html])
      }
    }

  end

  def show

  end

  def contact_information
    render json: {
      templates: {
        targ__restaurant_account: (render_to_string :partial => 'restaurant/account/components/account__detail_contact_information', :layout => false, :formats => [:html])
      }
    }
  end

  def payment_information
    if @restaurant.bank_accounts.any?
      render json: {
        templates: {
          targ__restaurant_account: (render_to_string :partial => 'restaurant/account/components/account__detail_payment_information', :layout => false, :formats => [:html])
        }
      }
      return
    else
      redirect_to new_restaurant_account_bank_account_path
    end
  end

  def payments
    render json: {
      templates: {
        targ__restaurant_account: (render_to_string partial: 'restaurant/account/components/account__detail_payments', layout: false, formats: [:html])
      }
    }

  end

  def reviews
    @order_review_count = @restaurant.order_reviews.count
    @order_reviews_with_comments = @restaurant.order_reviews.select{|review| review.comment.present?}.sort_by{|rev| rev.overall}
    render json: {
      templates: {
        targ__restaurant_account: (render_to_string :partial => 'restaurant/account/components/account__detail_reviews', layout: false, formats: [:html])
      }
    }
  end

  def notifications
    @user_notification_prefs = current_user.user_notification_prefs.active.first
    if !@user_notification_prefs
      @user_notification_prefs = UserNotificationPref.new(:user_id => current_user.id, :status => 'active',
        :last_updated_by_id => current_user.id, :via_email => {}, :via_sms => {})
    end
    render json: {
      templates: {
        targ__restaurant_account: (render_to_string :partial => 'restaurant/account/components/account__detail_notifications', :layout => false, :formats => [:html])
      }
    }
  end

  def faq
    render json: {
      templates: {
        targ__restaurant_account: (render_to_string :partial => 'restaurant/account/components/account__detail_faq', :layout => false, :formats => [:html])
      }
    }
  end

  def terms
    render json: {
      templates: {
        targ__restaurant_account: (render_to_string :partial => 'restaurant/account/components/account__detail_terms', :layout => false, :formats => [:html])
      }
    }
  end

  private

    def allowed_params
      groupings = [:restaurant]
      super(groupings, params)
    end

    def test_params
      #params.require(:restaurant).permit!
      test = params[:restaurant][:user]
      groupings = [test]
      super(groupings, params)
    end

    def user_params
      params.require(:user).permit(:current_password, :password, :password_confirmation)
    end

    def restaurant_params
      params.require(:restaurant).permit(:id, :name, :phone, :address_line1, :address_line2, :timezone, :city, :state, :postal_code, :country, :description, :brand_image,
        restaurant_pocs_attributes: [:id, :restaurant_id, :first_name, :last_name, :title, :phone, :email, :status, :created_by_id, :primary])
    end

    def contact_params
      params.require(:restaurant).permit(:id, restaurant_pocs_attributes: [:id, :restaurant_id, :first_name, :last_name, :title, :phone, :email, :status, :created_by_id, :primary])
    end

    def allowed_notification_prefs_params
      params.require(:user_notification_pref).permit(:user_id, :status, :last_updated_by_id, via_email: {}, via_sms: {})
    end
end
