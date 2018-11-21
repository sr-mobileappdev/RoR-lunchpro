class Restaurant::Account::BankAccountsController < ApplicationRestaurantsController
  before_action :set_restaurant, only: [:show, :edit, :update, :delete, :create, :new]
  before_action :set_record, only: [:show, :edit, :update, :delete, :new]
  before_action :set_user_restaurant
  before_action :set_bank_account_manager

  def set_record
    if params[:id]
      @record = BankAccount.find(params[:id])
    else
      @record = BankAccount.new(restaurant_id: @restaurant.id)
    end
  end

  def set_restaurant
    @restaurant = Restaurant.find((current_restaurant_id || @restaurant_user.restaurant_id))
  end

  def set_user_restaurant
    @user_restaurant = current_user.user_restaurant
    @consolidated = session[:hq_consolidated_view]
  end

  def set_bank_account_manager
    @bank_account_manager = Managers::BankAccountManager.new(@user_restaurant.restaurant, nil, current_user)
  end

  def index
    @main_bank_account = @restaurant.bank_accounts.first
    render json: {
      templates: {
        targ__restaurant_account: (render_to_string :partial => 'restaurant/account/components/account__detail_payment_information', :layout => false, :formats => [:html])
      }
    }
  end

  def new
    @record = BankAccount.new(:restaurant_id => @restaurant.id)
    render json: {
      templates: {
        targ__restaurant_account: (render_to_string :partial => 'restaurant/account/components/account__detail_new_bank_account', :layout => false, :formats => [:html])
      }
    }
    return
  end

  def edit
    render json: {
      templates: {
        targ__restaurant_account: (render_to_string :partial => 'restaurant/account/components/account__detail_edit_bank_account', :layout => false, :formats => [:html])
      }
    }
  end

  def create

    @record = BankAccount.new(bank_params)
    if @restaurant.bank_accounts.active.any?
      @old_record = @restaurant.bank_accounts.active.first
    end

    unless @record.valid? && @record.save
      render :json => { success: false, general_error: "This bank account could not be saved due to the following issue(s):", errors: @record.errors.full_messages}, status: 500
      return
    end

    # delete original bank account once new one has successfully saved
    @old_record.update_attributes(status: 'deleted') if @old_record

    Managers::NotificationManager.trigger_notifications([302], [@restaurant], {poc: current_user.poc_info})

    flash[:success] = "ACH Details have been updated!"
    redirect_to restaurant_account_index_path(tab: "payment_information")
  end

  def delete
    @record.update_attributes(:status => 'deleted')

    flash[:alert] = "Payment method has been deleted."
    unless @record.deleted?
      render :json => { success: false, general_error: "This bank account could not be deleted for the following reason(s):", errors: @record.errors.full_messages}, status: 500
      return
    end

    Managers::NotificationManager.trigger_notifications([302], [@restaurant], {poc: current_user.poc_info})

    redirect_to restaurant_account_index_path(tab: "payment_information")
  end

private

  def bank_params
    params.require(:bank_account).permit(:restaurant_id, :bank_name, :account_number, :routing_number,
      :account_type, :address_line1, :address_line2, :city, :state, :postal, :stripe_identifier)
  end

end
